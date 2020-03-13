component = require "component"
r = component.robot
s = component.geolyzer
invent = component.inventory_controller
v = require "vars"
comp = require "computer"
farm = require "farmutils"
nav = require "navigation"
stats = require "stats"
spread = require "spread"
fill = require "fill"
misc = require "misc"
inv = require "inventory"


local function Main()
  misc.Initialize()
  -- maxStage = misc.GetMaxStage()
  stats.Start()
  spread.Start()
  fill.Start()
  print("Field completed")
end
Main()