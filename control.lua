-- Copyright 2020 Sil3ntStorm https://github.com/Sil3ntStorm
--
-- Licensed under MS-RL, see https://opensource.org/licenses/MS-RL

if not global.logistic_signals then
    global.logistic_signals = {};
end

local function onEntityCreated(event)
    if (event.created_entity.valid and (event.created_entity.name == "sil-unfulfilled-requests-combinator" or event.created_entity.name == "sil-player-requests-combinator")) then
        event.created_entity.operable = false;
        table.insert(global.logistic_signals, event.created_entity);
    end
end

local function onEntityDeleted(event)
    if (not (event.entity and event.entity.valid)) then
        log('onEntityDeleted called with an invalid entity');
        return
    end
    -- grab the values and store them for the loop, as the game might remove the entity while the loop is still running
    local destroyed_unit_number = event.entity.unit_number;
    local destroyed_unit_name = event.entity.name;
    if (destroyed_unit_name == "sil-unfulfilled-requests-combinator" or destroyed_unit_name == "sil-player-requests-combinator") then
        local removed_from_tracking = false;
        for i = #global.logistic_signals, 1, -1 do
            if (not global.logistic_signals[i].valid or global.logistic_signals[i].unit_number == destroyed_unit_number) then
                table.remove(global.logistic_signals, i);
                removed_from_tracking = true;
            end
        end
        if (not removed_from_tracking) then
            log('onEntityDeleted called with an entity that was not tracked');
        end
    end
end

local function processRequests(req, requests)
    local log_point = req.get_logistic_point(defines.logistic_member_index.logistic_container);
    if (not (log_point and log_point.valid)) then
        return
    end
    local buffer_chests_enabled = settings.global["sil-enable-buffer-chests"].value
    if (not ((log_point.mode == defines.logistic_mode.buffer and buffer_chests_enabled) or log_point.mode == defines.logistic_mode.requester)) then
        return
    end
    for i = 1, req.request_slot_count do
        local stack = req.get_request_slot(i);
        if (stack ~= nil) then
            local invIndex = defines.inventory.chest;
            if (req.type == 'spider-vehicle') then
                invIndex = defines.inventory.spider_ammo;
            end
            local inv = req.get_inventory(invIndex);
            local curCount = 0;
            if (inv == nil) then
                log("Failed to get inventory of " .. req.name .. " a " .. req.type);
            else
                curCount = inv.get_item_count(stack.name);
            end
            if (req.type == 'spider-vehicle') then
                inv = req.get_inventory(defines.inventory.spider_trunk);
                if (inv ~= nil) then
                    curCount = curCount + inv.get_item_count(stack.name);
                end -- has Spider Trunk
            end -- is SpiderTron
            local needed = stack.count - curCount;
            if (needed > 0) then
                if (requests[stack.name]) then
                    requests[stack.name] = requests[stack.name] + needed;
                else
                    requests[stack.name] = needed;
                end
            end -- only if items are missing, not deducting over-delivery by bots!
        end -- is request slot used
    end -- request slot count looping chest requests
    for item, count in pairs(log_point.targeted_items_pickup) do
        -- Add stuff that is about to be gone to the requested list
        if (requests[item]) then
            requests[item] = requests[item] + count;
        else
            requests[item] = count;
        end
    end
    for item, count in pairs(log_point.targeted_items_deliver) do
        -- Remove stuff that is being delivered from the requested list
        if (requests[item]) then
            requests[item] = requests[item] - count;
        else
            -- Delivery without the item being requested?!?
            requests[item] = 0 - count;
        end
    end
end

local function processCombinator(obj)
    if (not (obj and obj.valid)) then
        return;
    end
    local network = obj.force.find_logistic_network_by_position(obj.position, obj.surface);
    local player_outside_network = settings.global['sil-player-request-map-wide'].value
    if (not (network or player_outside_network)) then
        if obj.name == "sil-player-requests-combinator" and not player_outside_network then
            obj.get_or_create_control_behavior().parameters = {}
        end
        return;
    end
    local requests = {};
    local params = {};
    if not network then
        -- Only grab the players globally
        local signalIndex = 1
        for _, plr in pairs(game.players) do
            if (obj.name == "sil-player-requests-combinator" and plr and plr.valid and plr.connected and plr.character and plr.character.valid and plr.character_personal_logistic_requests_enabled and plr.surface.index == obj.surface.index) then
                local main_inv = plr.character.get_inventory(defines.inventory.character_main)
                local trash_inv = plr.character.get_inventory(defines.inventory.character_trash)
                for _, log in pairs(plr.character.get_logistic_point()) do
                    if (log.mode == defines.logistic_mode.active_provider and trash_inv) then
                        for name, cnt in pairs(trash_inv.get_contents()) do
                            local slot = { signal = { type = "item", name = name}, count = 0 - cnt, index = signalIndex};
                            table.insert(params, slot);
                            signalIndex = signalIndex + 1;
                        end
                    elseif (log.mode == defines.logistic_mode.requester and main_inv and log.filters) then
                        for _, req in pairs(log.filters) do
                            local want = req.count
                            local have = main_inv.get_item_count(req.name)
                            if (want > have) then
                                local slot = { signal = { type = "item", name = req.name}, count = want - have, index = signalIndex};
                                table.insert(params, slot);
                                signalIndex = signalIndex + 1;
                            end
                        end
                    end
                end
            end
        end
        obj.get_or_create_control_behavior().parameters = params
        return
    end
    for _, req in pairs(network.requesters) do
        if ((req.type ~= "character" and obj.name == "sil-unfulfilled-requests-combinator") or (req.type == "character" and obj.name == "sil-player-requests-combinator")) then
            processRequests(req, requests);
        end
    end -- requesters
    local maxSignalCount = obj.get_control_behavior().signals_count;
    local ignored = 0;
    local signalIndex = 1;
    local MAX_VALUE = 2147483647; -- ((2 ^ 32 - 1) << 1) >> 1;
    for k,v in pairs(requests) do
        if (v > 0) then
            if (v > MAX_VALUE) then
                log('Value for ' .. k .. ' (' .. v .. ') exceeds 32 bit limit, clamping');
                v = MAX_VALUE;
            end
            local slot = { signal = { type = "item", name = k}, count = v, index = signalIndex};
            if (signalIndex <= maxSignalCount) then
                signalIndex = signalIndex + 1;
                table.insert(params, slot);
            else
                ignored = ignored + 1;
            end
        end
    end
    if (ignored > 0) then
        log('Ignored ' .. ignored .. ' requests, which exceed maximum number of requests');
    end
    obj.get_or_create_control_behavior().parameters = params;
end

script.on_event({defines.events.on_pre_player_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died}, onEntityDeleted);
script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, onEntityCreated);

script.on_nth_tick(30, function(event)
    for _, obj in pairs(global.logistic_signals) do
        processCombinator(obj);
    end
end);
