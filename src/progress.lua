local Draw = require "primitive"
local Utils = require "utils"

Draw.Wave = require "wave"

local Progress = {
    settings = {
        scrubber_margin    = nil,
        scrubber_thickness = nil,
        scrubber_size      = nil,
        scrubber_color     = nil,
        unfilled_color     = nil,
    }
}

function Progress.horizontal(ass, layout, percent, mix, phase, color)
    if layout.w == 0 then return end

    local filled_length = percent * layout.w / 100
    local unfilled_length = layout.w - filled_length
    -- TODO: Shrink scrubber thickness on drag
    local scrubber_effective_thickness = Progress.settings.scrubber_thickness + (2 * Progress.settings.scrubber_margin)
    -- TODO: Simplify layout logic here
    -- TODO: Use fill for played and unplayed layouts instead
    local filled_layout, scrubber_layout, unfilled_layout = layout:split({
        direction = "x",
        sizes = {
            Utils.clamp(filled_length - (scrubber_effective_thickness / 2), 0, layout.w),
            Utils.clamp(Progress.settings.scrubber_thickness, 0, layout.h),
            Utils.clamp(unfilled_length - (scrubber_effective_thickness / 2), 0, layout.w),
        }
    })

    -- TODO: Use Layout:centeredAt instead
    Draw.Wave.horizontal(
        ass,
        filled_layout:pad({
            direction = "y",
            padding   = (layout.h - (2 * Draw.Wave.settings.amplitude) / 2),
        }),
        mix,
        phase,
        color
    )
    Draw.cylinder(ass, scrubber_layout:pad({
        direction = "y",
        padding   = (layout.h - Progress.settings.scrubber_size) / 2,
    }), Progress.settings.scrubber_color)
    Draw.cylinder(ass, unfilled_layout:pad({
        direction = "y",
        padding   = (layout.h - Draw.Wave.settings.thickness) / 2,
    }), Progress.settings.unfilled_color)
end

function Progress.vertical(ass, layout, percent, mix, phase, color)
    if layout.h == 0 then return end

    local filled_length = percent * layout.h / 100
    local unfilled_length = layout.h - filled_length
    -- TODO: Shrink scrubber thickness on drag
    local scrubber_effective_thickness = Progress.settings.scrubber_thickness + (2 * Progress.settings.scrubber_margin)
    -- TODO: Simplify layout logic here
    -- TODO: Use fill for played and unplayed layouts instead
    local unfilled_layout, scrubber_layout, filled_layout = layout:split({
        direction = "y",
        sizes = {
            Utils.clamp(unfilled_length - (scrubber_effective_thickness / 2), 0, layout.h),
            Utils.clamp(Progress.settings.scrubber_thickness, 0, layout.h),
            Utils.clamp(filled_length - (scrubber_effective_thickness / 2), 0, layout.h),
        }
    })

    -- TODO: Use Layout:centeredAt instead
    Draw.cylinder(ass, unfilled_layout:pad({
        direction = "x",
        padding   = (layout.w - Draw.Wave.settings.thickness) / 2,
    }), Progress.settings.unfilled_color)
    Draw.cylinder(ass, scrubber_layout:pad({
        direction = "x",
        padding   = (layout.w - Progress.settings.scrubber_size) / 2,
    }), Progress.settings.scrubber_color)
    Draw.Wave.vertical(
        ass,
        filled_layout:pad({
            direction = "x",
            padding   = (layout.w - (2 * Draw.Wave.settings.amplitude) / 2),
        }),
        mix,
        phase,
        color
    )
end

return Progress
