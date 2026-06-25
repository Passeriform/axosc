local mp = require "mp"
local assdraw = require "mp.assdraw"

local Ass = require "ass"
local Layout = require "layout"
local Utils = require "utils"

local Draw = require "primitive"
Draw.Progress = require "progress"

--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------
local Config = {
    debug = false,

    frame_rate      = 0.016,
    animation_speed = 12,
    hide_timeout    = 3.5,

    icon_font       = "Phosphor",
    icon_font_size  = 24,
    icons = {
        play       = "\xEE\x8F\x90",
        pause      = "\xEE\x8E\x9E",
        next       = "\xEE\x96\xA6",
        volume     = "\xEE\x91\x8A",
        mute       = "\xEE\x91\x9B",
        subtitles  = "\xEE\x86\xA8",
        play_speed = "\xEE\x92\x92",
    },

    colors = {
        background = 0x000000,
        icon       = 0xFFFFFF,

        progress = {
            scrubber = 0xFFFFFF,
            filled   = 0xC1C3ED,
            unfilled = 0x312C2D,
            disabled = 0x2F2325,
        },
    },

    progress = {
        animate_idle = true,

        wave = {
            speed     = 0.045,
            amplitude = 4.5,
            frequency = 0.15,
            thickness = 5,
        },

        scrubber = {
            margin    = 8,
            size      = 20,
            thickness = 5,
        },
    },
    
    notch = {
        width  = 600,
        height = 64,
        radius = 30,
    },

    control_panel = {
        offset = 80,
        width  = 168,
        height = 56,
        radius = 12,
    },

    volume_panel = {
        offset  = 10,
        height  = 160,
        padding = 20,
        radius  = 12,
    },

    taste = {
        animate_collapsed_wave = true,
        preserve_wave_on_seek  = true,
        zero_progress_hinting  = true,
    },
}

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------
local State = {
    show_osc          = true,
    show_volume_panel = false,

    paused            = false,
    muted             = false,
    volume            = 100.0,
    seek              = 0.0,
}

--------------------------------------------------------------------------------
-- Interpolation
--------------------------------------------------------------------------------
local Interpolations = {
    notch_offset        = 0.0,
    volume_panel_height = 0.0,

    seekbar_wave = {
        mix   = 1.0,
        phase = 0.0,
    },

    volume_wave = {
        mix   = 1.0,
        phase = 0.0,
    },
}

function Interpolations.update()
    Interpolations.notch_offset = Utils.lerp(
        Interpolations.notch_offset,
        State.show_osc and -Config.notch.height or 0,
        Config.animation_speed * Config.frame_rate
    )

    Interpolations.volume_panel_height = Utils.lerp(
        Interpolations.volume_panel_height,
        State.show_osc and State.show_volume_panel and Config.volume_panel.height or 0,
        Config.animation_speed * Config.frame_rate
    )

    Interpolations.seekbar_wave.phase = Interpolations.seekbar_wave.phase + Config.progress.wave.speed
    Interpolations.seekbar_wave.mix = Utils.lerp(
        Interpolations.seekbar_wave.mix,
        ((not State.paused) or (State.paused and Config.taste.preserve_wave_on_seek and Input.active_drag == "seekbar" and Input.was_playing)) and 1.0 or (Config.taste.animate_collapsed_wave and 0.1 or 0.0)
        Config.animation_speed * Config.frame_rate
    )

    Interpolations.volume_wave.phase = Interpolations.volume_wave.phase + Config.progress.wave.speed
    Interpolations.volume_wave.mix = Utils.lerp(
        Interpolations.volume_wave.mix,
        State.muted and (Config.taste.animate_collapsed_wave and 0.1 or 0.0) or 1.0,
        Config.animation_speed * Config.frame_rate
    )
end

--------------------------------------------------------------------------------
-- Layout
--------------------------------------------------------------------------------
local Layouts = {}

function Layouts.update(window_width, window_height)
    -- TODO: Use Layout:anchor("center", { x, y }) instead of moving.
    Layouts.notch = Layout.new(
        window_width / 2,
        window_height,
        Config.notch.width,
        Config.notch.height
    ):moveBy(
        -Config.notch.width / 2,
        Interpolations.notch_offset
    )

    -- TODO: Use fill type split instead of manual seekbar size calculation.
    Layouts.play, Layouts.seekbar, Layouts.next = Layouts.notch:split({
        direction = "x",
        sizes = { Layouts.notch.h, Layouts.notch.w - (2 * Layouts.notch.h), Layouts.notch.h }
    })

    local notch_inline_end, notch_block_start = Layouts.notch:corner("tr")

    Layouts.control_panel = Layout.new(
        notch_inline_end,
        notch_block_start,
        Config.control_panel.width,
        Config.control_panel.height
    ):moveBy(Config.control_panel.offset, 0)

    -- TODO: Simplify consumption on repeat lengths
    Layouts.volume, Layouts.subtitles, Layouts.play_speed = Layouts.control_panel:split({
        direction = "x",
        sizes = { Layouts.control_panel.h, Layouts.control_panel.h, Layouts.control_panel.h }
    })

    Layouts.volume_panel = Layout.new(
        Layouts.volume.x,
        Layouts.volume.y - Config.volume_panel.offset,
        Layouts.volume.w,
        Interpolations.volume_panel_height
    -- FIXME: Sizing is getting too small after some idle time
    ):moveBy(0, -Interpolations.volume_panel_height)

    Layouts.volume_slider = Layouts.volume_panel:pad({
        direction = "y",
        padding   = Config.volume_panel.padding,
    })
end

--------------------------------------------------------------------------------
-- Input
--------------------------------------------------------------------------------
local Input = {
    idle_tracker = 0,
    active_drag  = nil,
    was_playing  = false,
}

function Input.wake()
    Input.idle_tracker = 0
    State.show_osc = true
    mp.set_property("cursor-autohide", "no")
end

function Input.seekTo(position)
    -- TODO: Add throttling window with both edges, add configuration option for seek throttle
    local requested = (position - Layouts.seekbar.x) * 100 / Layouts.seekbar.w
    mp.commandv("seek", Utils.clamp(requested, 0, 100), "absolute-percent", "exact")
end

function Input.setVolume(position)
    local _, volume_slider_block_end = Layouts.volume_slider:corner("bl")
    local requested = (volume_slider_block_end - position) * 100 / Layouts.volume_slider.h
    mp.commandv("set", "volume", Utils.clamp(requested, 0, 100))
end

function Input.update()
    if Input.active_drag ~= nil then return end

    Input.idle_tracker = Input.idle_tracker + Config.frame_rate

    if Input.idle_tracker >= Config.hide_timeout then
        State.show_osc = false
        mp.set_property("cursor-autohide", "always")
    end
end

--------------------------------------------------------------------------------
-- Render
--------------------------------------------------------------------------------
local overlay = mp.create_osd_overlay("ass-events")

Draw.settings = {
    font      = Config.icon_font,
    font_size = Config.icon_font_size,
}

Draw.Wave.settings = {
    thickness             = Config.progress.wave.thickness,
    amplitude             = Config.progress.wave.amplitude,
    frequency             = Config.progress.wave.frequency,
    zero_progress_hinting = Config.taste.zero_progress_hinting
}

Draw.Progress.settings = {
    scrubber_margin    = Config.progress.scrubber.margin,
    scrubber_size      = Config.progress.scrubber.size,
    scrubber_thickness = Config.progress.scrubber.thickness,
    scrubber_color     = Config.colors.progress.scrubber,
    unfilled_color     = Config.colors.progress.unfilled,
}

function render()
    local window_width, window_height = mp.get_osd_size()

    if window_width == 0 or window_height == 0 then return end

    Input.update()
    Interpolations.update()
    Layouts.update(window_width, window_height)

    local ass = assdraw.ass_new()

    Draw.notch(ass, Layouts.notch, Config.notch.radius, Config.colors.background)
    Draw.icon(ass, Layouts.play, State.paused and Config.icons.play or Config.icons.pause, Config.colors.icon)
    Draw.Progress.horizontal(ass, Layouts.seekbar, State.seek, Interpolations.seekbar_wave.mix, Interpolations.seekbar_wave.phase, Config.colors.progress.filled)
    Draw.icon(ass, Layouts.next, Config.icons.next, Config.colors.icon)
    Draw.panel(ass, Layouts.control_panel, Config.control_panel.radius, Config.colors.background)
    Draw.icon(ass, Layouts.volume, State.muted and Config.icons.mute or Config.icons.volume, Config.colors.icon)
    Draw.panel(ass, Layouts.volume_panel, Config.volume_panel.radius, Config.colors.background)
    Draw.Progress.vertical(ass, Layouts.volume_slider, State.volume, Interpolations.volume_wave.mix, Interpolations.volume_wave.phase, State.muted and Config.colors.progress.disabled or Config.colors.progress.filled)
    Draw.icon(ass, Layouts.subtitles, Config.icons.subtitles, Config.colors.icon)
    Draw.icon(ass, Layouts.play_speed, Config.icons.play_speed, Config.colors.icon)

    if Config.debug then
        Draw.debug(ass, {
            Layouts.notch,
            Layouts.play,
            Layouts.seekbar,
            Layouts.next,
            Layouts.control_panel,
            Layouts.volume,
            Layouts.volume_panel,
            Layouts.volume_slider,
            Layouts.subtitles,
            Layouts.play_speed,
        })
    end

    overlay.res_x, overlay.res_y = window_width, window_height
    overlay.data = ass.text
    overlay:update()
end

--------------------------------------------------------------------------------
-- MPV Binding
--------------------------------------------------------------------------------
mp.add_forced_key_binding("MBTN_LEFT", "mouse_button", function(table)
    Input.wake()

    local x, y = mp.get_mouse_pos()

    if table.event == "down" then
        if Layouts.play:contains(x, y) then
            mp.commandv("cycle", "pause")
        elseif Layouts.next:contains(x, y) then
            mp.commandv("playlist-next")
        elseif Layouts.volume:contains(x, y) then
            mp.commandv("cycle", "mute")
        elseif Layouts.subtitles:contains(x, y) then
            mp.commandv("cycle", "sub")
        elseif Layouts.play_speed:contains(x, y) then
            local current_speed = mp.get_property_number("speed", 1.0)
            local next_speed = current_speed + 0.25
            if next_speed > 2.0 then next_speed = 1.0 end
            mp.commandv("set", "speed", next_speed)
        elseif Layouts.seekbar:contains(x, y) then
            Input.active_drag = "seekbar"
            Input.was_playing = not mp.get_property_bool("pause")
            mp.set_property_bool("pause", true)
            Input.seekTo(x)
        elseif State.show_osc and State.show_volume_panel and Layouts.volume_slider:contains(x, y) then
            Input.active_drag = "volume_slider"
            Input.setVolume(y)
        end
    elseif table.event == "up" then
        if Input.active_drag == "seekbar" and Input.was_playing then
            mp.set_property_bool("pause", false)
        end
        Input.active_drag = nil
    end
end, { complex = true, repeatable = false })

mp.observe_property("mouse-pos", "native", function(_, position)
    Input.wake()

    if Layouts.volume and Layouts.volume_panel then
        State.show_volume_panel = State.show_osc and (
            Input.active_drag == "volume_slider" or Layouts.volume:contains(position.x, position.y) or (
                State.show_volume_panel and (Layouts.volume + Layouts.volume_panel):contains(position.x, position.y)
            )
        )
    end

    if Input.active_drag == "seekbar" then
        Input.seekTo(position.x)
    elseif Input.active_drag == "volume_slider" then
        Input.setVolume(position.y)
    end
end)

mp.observe_property("pause", "bool", function(_, paused)
    Input.wake()
    State.paused = paused or false
end)

mp.observe_property("mute", "bool", function(_, muted)
    Input.wake()
    State.muted = muted or false
end)

mp.observe_property("volume", "number", function(_, volume)
    Input.wake()
    State.volume = volume or 0
end)

mp.observe_property("percent-pos", "number", function(_, seek)
    State.seek = seek or 0
end)

mp.register_event("seek", Input.wake)

mp.add_periodic_timer(Config.frame_rate, render)
