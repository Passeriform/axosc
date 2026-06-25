local Ass = {}

function Ass.__createRasterize(ass)
    return function(val)
        return math.floor(val * (2 ^ (ass.scale - 1)) + 0.5)
    end
end

function Ass.__unicode(codepoint)
    if codepoint < 0x80 then
        return string.char(codepoint)
    elseif codepoint < 0x800 then
        return string.char(
            0xC0 + math.floor(codepoint / 0x40),
            0x80 + (codepoint % 0x40)
        )
    elseif codepoint < 0x10000 then
        return string.char(
            0xE0 + math.floor(codepoint / 0x1000),
            0x80 + math.floor((codepoint / 0x40) % 0x40),
            0x80 + (codepoint % 0x40)
        )
    else
        return string.char(
            0xF0 + math.floor(codepoint / 0x40000),
            0x80 + math.floor((codepoint / 0x1000) % 0x40),
            0x80 + math.floor((codepoint / 0x40) % 0x40),
            0x80 + (codepoint % 0x40)
        )
    end
end

function Ass.scale(scale)
    return string.format("{\\p%s}", scale or 0)
end

function Ass.color(color, alpha)
    return string.format("{\\1c&H%06X&}{\\1a&H%02X&}", color, alpha or 0)
end

function Ass.border(size, color, alpha)
    return string.format("{\\bord%d}{\\3c&H%06X&}{\\3a&H%02X&}", size or 0, color or 0xFFFFFF, alpha or 0)
end

function Ass.text(text, font, size, color)
    return string.format("{\\c&H%06X&}{\\fs%d}{\\fn%s}%s{\\fn}", color or 0xFFFFFF, size, font, text)
end

function Ass.moveTo(x, y)
    return string.format("m %d %d ", x, y)
end

function Ass.lineTo(x, y)
    return string.format("l %d %d ", x, y)
end

function Ass.bezier(x1, y1, x2, y2, x3, y3)
    return string.format("b %d %d %d %d %d %d ", x1, y1, x2, y2, x3, y3)
end

return Ass