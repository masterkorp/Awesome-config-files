local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")

local __volume = {}

local function getvolume()
   return string.match(awful.util.pread("amixer -c0 get \"Master\""), "(%d+)%%")
end
    )
local function new(args)
  return __volume = {}
end

return setmetatable(__bat, { __call = function(_, ...) return new(...) end })
