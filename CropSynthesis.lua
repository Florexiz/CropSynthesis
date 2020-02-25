sd = require("sides")
sc = component.geolyzer
rb = component.robot
function Dance()
  rb.turn(true)
  rb.turn(true)
  rb.move(sd.front)
  rb.move(sd.front)
  rb.move(sd.top)
  rb.move(sd.bottom)
  rb.move(sd.bottom)
  rb.move(sd.top)
  rb.move(sd.back)
  rb.move(sd.back)
  rb.turn(true)
  rb.turn(true)
end
Dance()
