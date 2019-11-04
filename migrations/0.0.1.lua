for _, force in pairs(game.forces) do
    force.recipes["sil-unfulfilled-requests-combinator"].enabled = force.technologies["circuit-network"].researched;
end
