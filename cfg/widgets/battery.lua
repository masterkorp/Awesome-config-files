local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local surface = require("gears.surface")
local beautiful = require("beautiful")
local color = require("gears.color")
local pl = require("pl.import_into")()

local __bat = {}
local base_string = "/sys/class/power_supply/BAT0"
local batticon = {
  width = 10,
  height = 14,
  icon = surface(awful.util.getdir("config") .. "/icons/batticon.png"),
  charging = surface(awful.util.getdir("config") .. "/icons/charging.png"),
  status = "",
  danger = 0.35,
  dying = 0.10
}
-- The battery charge
local total = .5


--- check_status
-- Checks the batterry status and its charge
-- @return A table with the charge and the status
local function check_status()
  local status = pl.file.read(base_string .. "/status")

  if status then
    local charge = pl.file.read(base_string .. "/energy_now")
    local capacity = pl.file.read(base_string .. "/energy_full")

    -- Calculate charge
    total = math.floor((charge / capacity) * 100)
  else
    status = "Not connected"
    total = 0
  end

  return { ["charge"] = total, ["status"] = status }
end

local function update(textbox)

  local status = check_status()

  -- Notifcation of events.
  if status["status"] ~= batticon["status"] then
    naughty.notify({text = status, title = "Battery"})
  end
  batticon["status"] = status["status"]
end

local function new(args)
  local args = args or {}
  local status = check_status()

  -- A layout widget that contains the 3 widgets for the diferent
  __bat.widget = wibox.layout.fixed.horizontal()
  local textbox = wibox.widget.textbox()
  __bat.widget:add(textbox)

  -- The icon
  -- http://awesome.naquadah.org/wiki/Writing_own_widgets
  local icon = wibox.widget.base.make_widget()
  icon.fit = function(icon, width, height)
     return batticon["width"], batticon["height"]
  end
  icon.draw = function(_, wibox, cr, width, height)
    -- This not really documented use the cairo to get bearings in.
    -- http://cairographics.org/manual/cairo-cairo-t.html
    -- Another example is:
    -- https://github.com/Elv13/awesome-configs/blob/master/widgets/battery.lua
    cr:set_source_surface(batticon.icon, 0, 0)
    cr:paint()
    -- It must not overlap, and since y is the counting from the top, you need to translate the rectangle to the bottom of the icon
    cr:translate(.5, (2 + batticon["height"] * (1 - total)))
    cr:rectangle(1, 1, batticon["width"] - 3, batticon["height"] * total)
    if status["charge"] > batticon["danger"] then
      cr:set_source_rgb(color.parse_color(beautiful.batt_ok))
    elseif status["charge"] > batticon["dying"] and total <= batticon["danger"] then
      cr:set_source_rgb(color.parse_color(beautiful.batt_danger))
    elseif status["charge"] <= batticon["danger"] then
      cr:set_source_rgb(color.parse_color(beautiful.batt_dying))
    end
    cr:fill()

    if batticon["status"] == "Charging" then
      cr:set_source_surface(batticon["charging"], -1, -4)
      cr:paint()
    end

  end
  __bat.widget:add(icon)



  local battery_timer = timer ({timeout = 10})
  battery_timer:connect_signal("timeout", function() update(textbox) end)
  battery_timer:start()

  return __bat.widget
end

return setmetatable(__bat, { __call = function(_, ...) return new(...) end })
