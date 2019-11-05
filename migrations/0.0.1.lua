-- Copyright 2019 Sil3ntStorm https://github.com/Sil3ntStorm
--
-- Licensed under MS-RL, see https://opensource.org/licenses/MS-RL

for _, force in pairs(game.forces) do
    force.recipes["sil-unfulfilled-requests-combinator"].enabled = force.technologies["circuit-network"].researched;
end
