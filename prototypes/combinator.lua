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

table.insert(data.raw["technology"]["circuit-network"].effects, { type = "unlock-recipe", recipe = recipe.name});
