component = require("component")
comp = require("computer")
sides = require("sides")
inv = component.inventory_controller
g = component.geolyzer
r = component.robot

currentPos = {}
bannedSlots = {}
cropName = "?"
fieldLength = 11
fieldCenter = (fieldLength + 1) / 2
s = {up = 0, right = 1, down = 2, left = 3}
currentDir = s.up
timeSleep = 5
timeCharge = 20
itemInHand = ""
field = {}
sampleStats = {20, 31, 0}

function ColorChange(event)
  if event == "error" then r.setLightColor(0xFF0000)
  elseif event == "scan" then r.setLightColor(0x0000FF)
  elseif event == "care" then r.setLightColor(0x00FF00)
  elseif event == "idle" then r.setLightColor(0xFFFFFF) end
end

function IsDelta(i, j)
  return tonumber(field[i][j]) and true or false
end

function IsValidPlace(i, j)
  count = 0
  if i > 1 and IsDelta(i - 1 , j) then count = count + 1 end
  if i < fieldLength and IsDelta(i + 1, j) then count = count + 1 end
  if j > 1 and IsDelta(i , j - 1) then count = count + 1 end
  if j < fieldLength and IsDelta(i, j + 1) then count = count + 1 end
  return count >= 2 and true or false
end

function TryMove(side)
  for i = 1, 10 do
    if r.move(side) then
      if side == sides.top or side == sides.bottom then
      elseif currentDir == s.up then currentPos.y = currentPos.y - 1
      elseif currentDir == s.down then currentPos.y = currentPos.y + 1
      elseif currentDir == s.left then currentPos.x = currentPos.x - 1
      else currentPos.x = currentPos.x + 1 end
      return
    end
  end
  print("Stuck!")
  ColorChange("error")
  os.exit()
end

function Rotate(side)
  while side ~= currentDir do
    r.turn(true)
    currentDir = currentDir + 1
    if currentDir == 4 then currentDir = 0 end
  end
end

function MoveTo(x, y)
  dx = x - currentPos.x
  dy = y - currentPos.y
  if dy ~= 0 then
    if dy < 0 then Rotate(s.up) else Rotate(s.down) end
  end
  for i = 1, math.abs(dy) do TryMove(sides.forward) end
  if dx ~= 0 then
    if dx < 0 then Rotate(s.left) else Rotate(s.right) end
  end
  for i = 1, math.abs(dx) do TryMove(sides.forward) end
end

function Panic()
  os.exit()
end 

function EquipItem(item)
  if item == itemInHand then return end
  for i = 1, r.inventorySize() do
    itemName = inv.getStackInInternalSlot(i)
    if itemName ~= nil then
      itemName = itemName.name
      if item == "trowel" and itemName == "IC2:itemWeedingTrowel" then
        r.select(i) inv.equip() itemInHand = item return end
      if item == "sticks" and itemName == "IC2:blockCrop" then
        r.select(i) inv.equip() itemInHand = item return end
      if item == "spade" and itemName == "berriespp:itemSpade" then
        r.select(i) inv.equip() itemInHand = item return end
    end
  end
  print("Missing in inventory: " .. item)
  ColorChange("error")
  Panic()
  os.exit()
end
function PlaceNewCrop(delta)
  for j = 1, fieldLength do
    for i = j % 2 == 0 and 2 or 1, fieldLength, 2 do
      if field[i][j] == "empty" then
        MoveTo(i, j)
        EquipItem("sticks")
        r.use(sides.bottom)
        EquipItem("seed")
        r.use(sides.bottom)
        field[i][j] = delta
      end
    end
  end
end

function PlaceNewSticks()
  for j = 1, fieldLength do
    for i = 1, fieldLength do
      if IsValidPlace(i, j) then
        MoveTo(i, j)
        EquipItem("sticks")
        if r.use(sides.bottom) then r.use(sides.bottom) field[i][j] = "sticks" end
      end
    end
  end
end

function PlaceUnbanned(delta)
  for i = , do
    PlaceNewCrop(delta)
  end
end

function ProcessWeed()
  EquipItem("trowel")
  r.use(sides.bottom)
  EquipItem("sticks")
  r.use(sides.bottom)
  return "sticks"
end

function ProcessSeedbag(delta)
  EquipItem("spade")
  r.use(sides.bottom)
  EquipItem("sticks")
  r.use(sides.bottom)
  PlaceUnbanned(delta)
end

function ProcessAnotherSeedbag()
  return "seedbag"
end

function CalculateDelta(scan)
  delta = scan["crop:growth"] - sampleStats[1] + 
          scan["crop:gain"] - sampleStats[2] + 
          scan["crop:resistance"] - sampleStats[3]
  return math.abs(delta)
end

function ProcessBlock()
  scan = g.analyze(sides.down)
  if scan == nil then return "sticks" end
  if scan.name == "minecraft:air" then return "empty" end
  if scan.name == "IC2:blockCrop"then
    if scan["crop:name"] == "weed" then return ProcessWeed() end
    if cropName == "?" then cropName = scan["crop:name"] end
    if scan["crop:name"] ~= cropName then return ProcessAnotherSeedbag() end
    return CalculateDelta(scan)
  end
  return "unknown"
end

function ScanField()
  ColorChange("scan")
  for j = 1, fieldLength/3 do
    for i = (j % 2 == 0 and fieldLength or 1),
            (j % 2 == 0 and 1 or fieldLength),
            (j % 2 == 0 and -1 or 1) do
      MoveTo(i, j)
      if i >= fieldCenter - 1 and i <= fieldCenter + 1 and
         j >= fieldCenter - 1 and j <= fieldCenter + 1 then
        field[i][j] = "center"
      else field[i][j] = ProcessBlock() end
      print(field[i][j])
    end
  end
  PlaceNewSticks()
end

function Initialize()
  for i = 1, fieldLength do field[i] = {} end
  currentPos.y = fieldCenter
  currentPos.x = fieldCenter
end

function Charge()
  if comp.energy() / comp.maxEnergy() < 0.2 then
    MoveTo(fieldCenter, fieldCenter)
    TryMove(sides.bottom)
    TryMove(sides.bottom)
    os.sleep(timeCharge)
    TryMove(sides.up)
    TryMove(sides.up)
    if comp.energy() / comp.maxEnergy() < 0.9 then
      print("Cant charge!")
      ColorChange("error")
      Panic()
    end
  end
end

function CheckCrops()
ColorChange("care")
  for j = 1, fieldLength do
    for i = (j % 2 == 0 and fieldLength or 1),
            (j % 2 == 0 and 1 or fieldLength),
            (j % 2 == 0 and -1 or 1) do
      if field[i][j] == "sticks" then
        MoveTo(i, j)
        newBlock = tonumber(ProcessBlock())
        if newBlock then ProcessSeedbag(newBlock) end
      end
    end
  end
end

function Main()
  Initialize()
  ScanField()
  while true do
    CheckCrops()
    ColorChange("idle")
    Charge()
    os.sleep(timeSleep)
  end
end
Main()
