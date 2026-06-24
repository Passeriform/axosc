local Utils = require "utils"

local Layout = {}

Layout.__index = Layout

Layout.__add = function (a, b) return Layout.fromCoords(
    math.min(a.x, b.x),
    math.min(a.y, b.y),
    math.max(a.x + a.w, b.x + b.w),
    math.max(a.y + a.h, b.y + b.h)
) end

function Layout:__tostring()
    return string.format("Layout (%.2f, %.2f) => [%.2f, %.2f]", self.x, self.y, self.w, self.h)
end

function Layout:__checkValid()
    assert(
        self.w >= 0 and self.h >= 0,
        "Sizing can't be non-positive float: [" .. self.w .. ", " .. self.h .. "]."
    )
end

-- TODO: Add anchor as persistent key
function Layout.new(x, y, w, h)
    local instance = setmetatable({ x = x, y = y, w = w, h = h }, Layout)
    instance:__checkValid()
    return instance
end

function Layout.fromCoords(x1, y1, x2, y2) return Layout.new(
    math.min(x1, x2),
    math.min(y1, y2),
    math.abs(x1 - x2),
    math.abs(y1 - y2)
) end

function Layout:center()
    return self.x + (self.w / 2), self.y + (self.h / 2)
end

-- TODO: Replace usage with Layout:bb() if possible
function Layout:corner(cornerType)
    if cornerType == "tl" then
        return self.x, self.y
    elseif cornerType == "tr" then
        return self.x + self.w, self.y
    elseif cornerType == "bl" then
        return self.x, self.y + self.h
    elseif cornerType == "br" then
        return self.x + self.w, self.y + self.h
    else
        error("Invalid corner type provided. Valid values are 'tl', 'tr', 'bl', 'br'.")
    end
end

function Layout:pad(padder)
    assert(
        padder.direction == "x" or padder.direction == "y" or padder.direction == "*",
        "Invalid direction string. Direction can be either 'x', 'y' or '*'."
    )

    assert(
        padder.padding >= 0,
        "Invalid padding size provided. Padding sizes must be non-negative."
    )

    if padder.direction == "x" then
        padding = Utils.clamp(padder.padding, 0, self.w / 2)
        return Layout.new(self.x + padding, self.y, self.w - (2 * padding), self.h)
    elseif padder.direction == "y" then
        padding = Utils.clamp(padder.padding, 0, self.h / 2)
        return Layout.new(self.x, self.y + padding, self.w, self.h - (2 * padding))
    else
        padding = Utils.clamp(padder.padding, 0, math.min(self.w, self.h) / 2)
        return Layout.new(self.x + padding, self.y + padding, self.w - (2 * padding), self.h - (2 * padding))
    end
end

function Layout:moveBy(dx, dy)
    return Layout.new(
        self.x + dx,
        self.y + dy,
        self.w,
        self.h
    )
end

function Layout:split(splitter)
    assert(
        splitter.direction == "x" or splitter.direction == "y",
        "Invalid direction string. Direction can be either 'x' or 'y'."
    )

    assert(#splitter.sizes > 1, "At least 2 or more split sizes are required to split the layout.")

    local max_length = splitter.direction == "x" and self.w or self.h

    local desired_sum = 0
    for _, value in ipairs(splitter.sizes) do
        desired_sum = desired_sum + value
    end

    assert(desired_sum <= max_length, "Desired lengths exceed the bounds of layout.")

    -- NOTE: Gap reduction creep on zero-length splits is "stylistically" intentional. Makes it a little cozier :).
    local gap = (max_length - desired_sum) / (#splitter.sizes - 1)

    local split_layouts = {}
    if (splitter.direction == "x") then
        local current_position = self.x
        for _, length in ipairs(splitter.sizes) do
            table.insert(split_layouts, Layout.new(
                current_position,
                self.y,
                length,
                self.h
            ))
            current_position = current_position + length + gap
        end
    else
        local current_position = self.y
        for _, length in ipairs(splitter.sizes) do
            table.insert(split_layouts, Layout.new(
                self.x,
                current_position,
                self.w,
                length
            ))
            current_position = current_position + length + gap
        end
    end

    return table.unpack(split_layouts)
end

function Layout:contains(mx, my)
    return self.x <= mx and self.x + self.w >= mx and self.y <= my and self.y + self.h >= my
end

return Layout
