component = require("component")
sd = require("sides")
cp = require("computer")
rb = component.robot
sc = component.geolyzer
chargeTime = 30
scanInterval = 10
fieldLength = 11
cropsticksSlots = 8
currentDir = 0
cropName = "?"
sampleStats = {20, 31, 0}
fieldStats = {}

function SearchSticksInInventory()
  iSize = rb.inventorySize()
  for i = iSize-cropsticksSlots+1, iSize do
    if rb.count(i) > 0 then return i end
  end
  return nil
end

function Emergency()
  print("Emergency!")
end
    
function ProcessWeed()
  rb.use(sd.bottom)
  sticksSlot = SearchSticksInInventory()
  if sticksSlot == nil then Emergency()
  else
    rb.select(sticksSlot) 
    rb.place(sd.bottom)
  end
end

function ProcessAnotherSeed()
  
end

function CheckBlock()
  scan = sc.analyze(sd.bottom)
  if scan == nil then return "sticks" end
  if scan.color == 0 then return "empty" end
  if scan["crop:name"] == "weed" then ProcessWeed() return "sticks" end
  if cropName == "?" then
    cropName = scan["crop:name"]
  else if cropName ~= scan["crop:name"] then ProcessAnotherSeed() return "sticks" end end
  sum = sampleStats[1] + sampleStats[2] + sampleStats[3]
  sum = sum - math.abs(scan["crop:growth"] - sampleStats[1])
            - math.abs(scan["crop:gain"] - sampleStats[2])
            - math.abs(scan["crop:resistance"] - sampleStats[3])
  return sum
end
function MoveTo(x, y)
  
end
function ReadWorkingArea()
  rb.setLightColor(0x0000FF)
  for i = 1, (fieldLength-1)/2 do rb.move(sd.forward) end
  rb.turn(false)
  for i = 1, (fieldLength-1)/2 do rb.move(sd.forward) end
  rb.turn(true)
  rb.turn(true)
  for i = 1, fieldLength do
    for j = 1, fieldLength-1 do
      if fieldStats[i][j] ~= "center" then fieldStats[i][j] = CheckBlock() end
      print(fieldStats[i][j])
      rb.move(sd.forward)
    end
    if i ~= fieldLength then
      rb.turn(i % 2 == 1)
      rb.move(sd.forward)
      rb.turn(i % 2 == 1)
    end
  end
  rb.turn(true)
  rb.turn(true)
  for i = 1, (fieldLength-1)/2 do rb.move(sd.forward) end
  rb.turn(true)
  for i = 1, (fieldLength-1)/2 do rb.move(sd.forward) end
end

function Main()
  
  ReadWorkingArea()
  
end

function Start()
  for i = 1, fieldLength do fieldStats[i] = {} end
  for i = 1, fieldLength do
    for j = 1, fieldLength do
      if i >= (fieldLength-1)/2 and i <= (fieldLength-1)/2+2 and
         j >= (fieldLength-1)/2 and j <= (fieldLength-1)/2+2 then
        fieldStats[i][j] = "center"
      else
        fieldStats[i][j] = "empty"
      end
    end
  end
  Main()
end
Start()
