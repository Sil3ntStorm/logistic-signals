-- Copyright 2021 Sil3ntStorm https://github.com/Sil3ntStorm
--
-- Licensed under MS-RL, see https://opensource.org/licenses/MS-RL

maxCount = data.raw["constant-combinator"]["sil-unfulfilled-requests-combinator"].item_slot_count;
-- Initialize to 20 for some safety margin for badly written mods adding items when they should not!
-- All prototypes should already exist when the first data-updates runs!
count = 20;
-- count all existing items, now that every mod should be done adding theirs
for _, info in pairs(data.raw) do
    for _, item in pairs(info) do
        if (item.stack_size) then
            count = count + 1
        end
    end
end

if (count > maxCount) then
    data.raw["constant-combinator"]["sil-unfulfilled-requests-combinator"].item_slot_count = count;
    data.raw["constant-combinator"]["sil-player-requests-combinator"].item_slot_count = count;
    log('Updated combinators to ' .. count .. ' slots');
end
