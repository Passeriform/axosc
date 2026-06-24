local Ass = require "ass"
local Draw = require "primitive"

-- TODO: Add checks for zero-length
-- TODO: Infer amplitude from layout size
local Wave = {
    settings = {
        thickness             = nil,
        amplitude             = nil,
        frequency             = nil,
        zero_progress_hinting = nil,
    },
}

function Wave.horizontal(ass, layout, mix, phase, color)
    local rasterize = Draw.__createRasterize(ass)
    local radius = Wave.settings.thickness / 2
    local control_distance = radius * Draw.KAPPA
    local amplitude = Wave.settings.amplitude * mix
    local frequency = Wave.settings.frequency * mix

    if (not Wave.settings.zero_progress_hinting and layout.w <= 0) then return end

    -- 1. Define points over wave
    -- TODO: Simplify normal calculation logic
    -- TODO: Add logic for vertical wave
    local points = {}
    for idx = 0, layout.w, 1 do
        local theta = (idx * frequency) + phase
        local slope = amplitude * frequency * math.cos(theta)
        local normal_length = math.sqrt(1 + slope * slope)
        local x = layout.x + idx
        local y = layout.y + (math.sin(theta) * amplitude)
        table.insert(points, {
            x = x,
            y = y,
            normal_x = -slope * radius / normal_length,
            normal_y = radius / normal_length
        })
    end

    -- 2. Prepare path for wave
    local path = Ass.moveTo(
        rasterize(points[1].x + points[1].normal_x),
        rasterize(points[1].y + points[1].normal_y)
    )
    for i = 2, #points do
        path = path .. Ass.lineTo(
            rasterize(points[i].x + points[i].normal_x),
            rasterize(points[i].y + points[i].normal_y)
        )
    end
    for i = #points, 1, -1 do
        path = path .. Ass.lineTo(
            rasterize(points[i].x - points[i].normal_x),
            rasterize(points[i].y - points[i].normal_y)
        )
    end

    ass:new_event()
    ass:pos(0, 0)
    ass:an(7)
    ass:append(Ass.scale(ass.scale))
    ass:append(Ass.color(color))
    ass:append(Ass.border())
    ass:draw_start()
    ass:append(path)
    ass:append(Ass.scale())
    ass:draw_stop()

    -- 3. Add line-end caps
    Draw.circle(ass, points[1], radius, color)
    Draw.circle(ass, points[#points], radius, color)
end

function Wave.vertical(ass, layout, mix, phase, color)
    local rasterize = Draw.__createRasterize(ass)    
    local radius = Wave.settings.thickness / 2
    local control_distance = radius * Draw.KAPPA
    local amplitude = Wave.settings.amplitude * mix
    local frequency = Wave.settings.frequency * mix
    
    if (not Wave.settings.zero_progress_hinting and layout.h <= 0) then return end

    -- 1. Define points over wave
    -- TODO: Simplify normal calculation logic
    -- TODO: Add logic for vertical wave
    local points = {}
    for idx = 0, layout.h, 1 do
        local theta = (idx * frequency) + phase
        local slope = amplitude * frequency * math.cos(theta)
        local normal_length = math.sqrt(1 + slope * slope)
        local _, layout_block_end = layout:corner("br")
        local x = layout.x + (math.sin(theta) * amplitude)
        local y = layout_block_end - idx
        table.insert(points, {
            x = x,
            y = y,
            normal_x = radius / normal_length,
            normal_y = slope * radius / normal_length
        })
    end

    -- 2. Prepare path for wave
    local path = Ass.moveTo(
        rasterize(points[1].x + points[1].normal_x),
        rasterize(points[1].y + points[1].normal_y)
    )
    for i = 2, #points do
        path = path .. Ass.lineTo(
            rasterize(points[i].x + points[i].normal_x),
            rasterize(points[i].y + points[i].normal_y)
        )
    end
    for i = #points, 1, -1 do
        path = path .. Ass.lineTo(
            rasterize(points[i].x - points[i].normal_x),
            rasterize(points[i].y - points[i].normal_y)
        )
    end

    ass:new_event()
    ass:pos(0, 0)
    ass:an(7)
    ass:append(Ass.scale(ass.scale))
    ass:append(Ass.color(color))
    ass:append(Ass.border())
    ass:draw_start()
    ass:append(path)
    ass:append(Ass.scale())
    ass:draw_stop()

    -- 3. Add line-end caps
    Draw.circle(ass, points[1], radius, color)
    Draw.circle(ass, points[#points], radius, color)
end

return Wave
