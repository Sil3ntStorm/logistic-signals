-- Copyright 2019 Sil3ntStorm https://github.com/Sil3ntStorm
--
-- Licensed under MS-RL, see https://opensource.org/licenses/MS-RL

local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"]);
entity.name = "sil-unfulfilled-requests-combinator";
entity.icons = {{
    icon = data.raw["constant-combinator"]["constant-combinator"].icon,
    tint = {r = 0.227, g = 0.447, b = 0.592, a = 0.8}
}}
entity.minable.result = entity.name;
entity.item_slot_count = 200;
entity.operable = false;

local item = table.deepcopy(data.raw.item["constant-combinator"]);
item.name = entity.name;
item.icons = entity.icons;
item.place_result = entity.name;

local recipe = table.deepcopy(data.raw.recipe["constant-combinator"]);
recipe.name = entity.name;
recipe.result = entity.name;

data:extend{entity, item, recipe};

table.insert(data.raw["technology"]["circuit-network"].effects, { type = "unlock-recipe", recipe = recipe.name });

local playerComb = table.deepcopy(data.raw["constant-combinator"]["sil-unfulfilled-requests-combinator"]);
playerComb.name = "sil-player-requests-combinator";
playerComb.icons = {{
    icon = data.raw["constant-combinator"]["constant-combinator"].icon,
    tint = {r = 0.113, g = 0.888, b = 0.106, a = 0.85}
}}
playerComb.minable.result = playerComb.name;
playerComb.operable = false;

local pcItem = table.deepcopy(data.raw.item["sil-unfulfilled-requests-combinator"]);
pcItem.name = playerComb.name;
pcItem.icons = playerComb.icons;
pcItem.place_result = playerComb.name;

local pcRepice = table.deepcopy(data.raw.recipe["sil-unfulfilled-requests-combinator"]);
pcRepice.name = playerComb.name;
pcRepice.result = playerComb.name;

data:extend{playerComb, pcItem, pcRepice};

table.insert(data.raw["technology"]["circuit-network"].effects, { type = "unlock-recipe", recipe = pcRepice.name });
