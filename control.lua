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
    if (event.entity.valid and (event.entity.name == "sil-unfulfilled-requests-combinator" or event.entity.name == "sil-player-requests-combinator")) then
        for i = #global.logistic_signals, 1, -1 do
            if (global.logistic_signals[i].unit_number == event.entity.unit_number) then
                table.remove(global.logistic_signals, i);
            end
        end
    end
end

local function processRequests(req, requests)
    local log_point = req.get_logistic_point(defines.logistic_member_index.logistic_container);
    if (not (log_point and log_point.valid)) then
        return
    end
    if (not (log_point.mode == defines.logistic_mode.buffer or log_point.mode == defines.logistic_mode.requester)) then
        return
    end
    for i = 1, req.request_slot_count do
        local stack = req.get_request_slot(i);
        if (stack ~= nil) then
            local inv = req.get_inventory(defines.inventory.chest);
            local curCount = 0;
            if (inv == nil) then
                log("Failed to get inventory of " .. req.name .. " a " .. req.type);
            else
                curCount = inv.get_item_count(stack.name);
            end
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
            requests[item] = 0 - count;
            log("This shouldn't happen!");
        end
    end
end

local function processCombinator(obj)
    if (not (obj and obj.valid)) then
        return;
    end
    local network = obj.force.find_logistic_network_by_position(obj.position, obj.surface);
    if (not (network)) then
        return;
    end
    local requests = {};
    local params = {};
    for _, req in pairs(network.requesters) do
        if ((req.type ~= "character" and obj.name == "sil-unfulfilled-requests-combinator") or (req.type == "character" and obj.name == "sil-player-requests-combinator")) then
            processRequests(req, requests);
        end
    end -- requesters
    local signalIndex = 1;
    local MAX_VALUE = 2147483647; -- ((2 ^ 32 - 1) << 1) >> 1;
    for k,v in pairs(requests) do
        if (v > 0) then
            if (v > MAX_VALUE) then
                log('Value for ' .. k .. ' (' .. v .. ') exceeds 32 bit limit, clamping');
                v = MAX_VALUE;
            end
            local slot = { signal = { type = "item", name = k}, count = v, index = signalIndex};
            signalIndex = signalIndex + 1;
            table.insert(params, slot);
        end
    end
    obj.get_or_create_control_behavior().parameters = params;
end

script.on_event({defines.events.on_pre_player_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died}, onEntityDeleted);
script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, onEntityCreated);

script.on_event(defines.events.on_tick, function(event)
    if (event.tick % 30 > 0) then
        return;
    end

    for _, obj in pairs(global.logistic_signals) do
        processCombinator(obj);
    end
end
);
