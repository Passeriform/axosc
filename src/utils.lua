local Utils = {}

function Utils.lerp(current, target, time)
    local EPSILON = 0.05

    local next_value = current + (target - current) * time

    if math.abs(target - next_value) < EPSILON then
        return target
    end

    return next_value
end

function Utils.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

return Utils
