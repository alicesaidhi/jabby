
local function conditional<T>(fn: () -> unknown, a: T, b: T): () -> T
    return function()
        return if fn() then a else b
    end
end

return conditional