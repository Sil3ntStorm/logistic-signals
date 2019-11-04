function printTable(level, key, value)
    if (type(value) == "table") then
        for k, v in pairs(value) do
            printTable(level .. "[" .. key .. "]", k, v)
        end
    elseif (type(value) ~= "string" and type(value) ~= "number") then
        log(level .. "[" .. key .. "] = " .. tostring(value))
    else
        log(level .. "[" .. key .. "] = " .. value)
    end
end
