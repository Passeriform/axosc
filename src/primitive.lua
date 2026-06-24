local Ass = require "ass"

local Draw = {
    KAPPA        = 0.5522847,
    debug_colors = {},

    settings     = {
        font      = nil,
        font_size = nil,
    }
}

function Draw.__createRasterize(ass)
    return function(val)
        return math.floor(val * (2 ^ (ass.scale - 1)) + 0.5)
    end
end

function Draw.notch(ass, layout, radius, color)
    local rasterize = Draw.__createRasterize(ass)
    local control_distance = radius * Draw.KAPPA
    local _, layout_block_end = layout:corner("br")

    ass:new_event()
    ass:pos(0, 0)
    ass:an(7) 
    ass:append(Ass.color(color))
    ass:append(Ass.border())
    ass:draw_start()

    ass:append(Ass.moveTo(rasterize(layout.x - radius), rasterize(layout_block_end)))
    ass:append(Ass.bezier(
        rasterize(layout.x - radius + control_distance),
        rasterize(layout_block_end),
        rasterize(layout.x),
        rasterize(layout_block_end - radius + control_distance),
        rasterize(layout.x),
        rasterize(layout_block_end - radius)
    ))
    ass:append(Ass.lineTo(rasterize(layout.x), rasterize(layout.y + radius)))
    ass:append(Ass.bezier(
        rasterize(layout.x),
        rasterize(layout.y + radius - control_distance),
        rasterize(layout.x + radius - control_distance),
        rasterize(layout.y),
        rasterize(layout.x + radius),
        rasterize(layout.y)
    ))
    ass:append(Ass.lineTo(rasterize(layout.x + layout.w - radius), rasterize(layout.y)))
    ass:append(Ass.bezier(
        rasterize(layout.x + layout.w - radius + control_distance),
        rasterize(layout.y),
        rasterize(layout.x + layout.w),
        rasterize(layout.y + radius - control_distance),
        rasterize(layout.x + layout.w),
        rasterize(layout.y + radius)
    ))
    ass:append(Ass.lineTo(rasterize(layout.x + layout.w), rasterize(layout_block_end - radius)))
    ass:append(Ass.bezier(
        rasterize(layout.x + layout.w),
        rasterize(layout_block_end - radius + control_distance),
        rasterize(layout.x + layout.w + radius - control_distance),
        rasterize(layout_block_end),
        rasterize(layout.x + layout.w + radius),
        rasterize(layout_block_end)
    ))

    ass:draw_stop()
end

function Draw.panel(ass, layout, radius, color)
    local panel_inline_end, panel_block_end = layout:corner("br")
    local saturating_radius = math.min(radius, layout.w / 2, layout.h / 2)

    ass:new_event()
    ass:pos(0, 0)
    ass:an(7) 
    ass:append(Ass.color(color))
    ass:append(Ass.border())
    ass:draw_start()
    ass:round_rect_cw(layout.x, layout.y, panel_inline_end, panel_block_end, saturating_radius)
    ass:draw_stop()
end

-- TODO: Add checks for zero-radius
-- TODO: Convert to use layout bounds as diameter
function Draw.circle(ass, position, radius, color)
    local rasterize = Draw.__createRasterize(ass)
    local control_distance = radius * Draw.KAPPA

    ass:new_event()
    ass:pos(0, 0)
    ass:an(7)
    ass:append(Ass.scale(ass.scale))
    ass:append(Ass.color(color))
    ass:append(Ass.border())
    ass:draw_start()
    ass:append(Ass.moveTo(rasterize(position.x), rasterize(position.y - radius)))
    ass:append(Ass.bezier(
        rasterize(position.x + control_distance),
        rasterize(position.y - radius),
        rasterize(position.x + radius),
        rasterize(position.y - control_distance),
        rasterize(position.x + radius),
        rasterize(position.y)
    ))
    ass:append(Ass.bezier(
        rasterize(position.x + radius),
        rasterize(position.y + control_distance),
        rasterize(position.x + control_distance),
        rasterize(position.y + radius),
        rasterize(position.x),
        rasterize(position.y + radius)
    ))
    ass:append(Ass.bezier(
        rasterize(position.x - control_distance),
        rasterize(position.y + radius),
        rasterize(position.x - radius),
        rasterize(position.y + control_distance),
        rasterize(position.x - radius),
        rasterize(position.y)
    ))
    ass:append(Ass.bezier(
        rasterize(position.x - radius),
        rasterize(position.y - control_distance),
        rasterize(position.x - control_distance),
        rasterize(position.y - radius),
        rasterize(position.x),
        rasterize(position.y - radius)
    ))
    ass:append(Ass.scale())
    ass:draw_stop()
end

function Draw.cylinder(ass, layout, color)
    local cylinder_inline_end, cylinder_block_end = layout:corner("br")
    local radius = math.min(layout.w, layout.h) / 2

    ass:new_event()
    ass:pos(0, 0)
    ass:an(7) 
    ass:append(Ass.color(color))
    ass:append(Ass.border())
    ass:draw_start()
    ass:round_rect_cw(layout.x, layout.y, cylinder_inline_end, cylinder_block_end, radius)
    ass:draw_stop()
end

function Draw.icon(ass, layout, text, color)
    ass:new_event()
    ass:pos(layout:center())
    ass:an(5)
    ass:append(Ass.text(text, Draw.settings.font, Draw.settings.font_size, color))
end

function Draw.debug(ass, layouts)
    if #Draw.debug_colors < #layouts then
        for idx, _ in ipairs(layouts) do
            -- NOTE: This color is BGR for compatibility with ASS
            Draw.debug_colors[idx] = math.random(0x000000, 0xFFFFFF)
        end
    end

    for idx, layout in ipairs(layouts) do
        local layout_inline_end, layout_block_end = layout:corner("br")

        ass:new_event()
        ass:pos(0, 0)
        ass:an(7)
        ass:append(Ass.color(Draw.debug_colors[idx], 127))
        ass:append(Ass.border(1, 0xFFFFFF, 22))
        ass:draw_start()
        ass:rect_cw(layout.x, layout.y, layout_inline_end, layout_block_end)
        ass:draw_stop()
    end
end

return Draw
