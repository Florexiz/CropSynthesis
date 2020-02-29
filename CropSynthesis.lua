component = require("component")
comp = require("computer")
sides = require("sides")
inv = component.inventory_controller
g = component.geolyzer
r = component.robot

currentPos = {}
cropName = "?"
fieldLength = 11
fieldCenter = (fieldLength + 1) / 2
s = {up = 0, right = 1, down = 2, left = 3}
currentDir = s.up
checksForScanLeft = 20
plantCount = 0
mode = "stats"
avgDelta = 1000
timeSleep = 5
timeCharge = 20
itemInHand = ""
itemCount = 0
field = {}
seedToPlant = {}
seedToPlantSize = 0
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
  if field[i][j] ~= "empty" then return false end
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
  print("Removing empty sticks")
  for j = 1, fieldLength do
    for i = 1, fieldLength do
      if field[i][j] == "sticks" then
        MoveTo(i, j)
        r.swing(sides.bottom)
      end
    end
  end
  os.exit()
end 

function EquipItem(item)
  if itemInHand == item or (item == "sticks" and itemCount > 1) then return end
  for i = 1, r.inventorySize() do
    itemName = inv.getStackInInternalSlot(i)
    if itemName ~= nil then
      itemName = itemName.name
      if item == "sticks" and itemName == "IC2:blockCrop" then
        r.select(i)
        itemCount = r.count()
        inv.equip()
        itemInHand = item
        return
      end
      if item == "spade" and itemName == "berriespp:itemSpade" then
        r.select(i) itemCount = -1 inv.equip() itemInHand = item return end
    end
  end
  print("Missing in inventory: " .. item)
  ColorChange("error")
  Panic()
  os.exit()
end

function PlaceSticksDown()
  if itemCount <= 1 then EquipItem("sticks") end
  r.use(sides.bottom)
  itemCount = itemCount - 1
end

function CalculateAvgDelta()
  sum = 0
  for j = 1, fieldLength do
    for i = 1, fieldLength do
      if IsDelta(i, j) then sum = sum + field[i][j] end
    end
  end
  avgDelta = sum / plantCount
  print("New average delta: ".. avgDelta)
end

function IncreaseStats(delta, s)
  maxDelta = {x = 0, y = 0, delta = 0}
  for j = 1, fieldLength do
    for i = 1, fieldLength do
      if IsDelta(i, j) and field[i][j] > maxDelta.delta then
        maxDelta.delta = field[i][j]
        maxDelta.x = i
        maxDelta.y = j
      end
    end
  end
  if delta < maxDelta.delta then
    for i = 1, r.inventorySize() do
      itemName = inv.getStackInInternalSlot(i)
      if itemName ~= nil then
        itemName = itemName.name
        if itemName == "IC2:itemCropSeed" then
          seedToPlant[seedToPlantSize + 1] = i
          seedToPlantSize = seedToPlantSize + 1
        end
      end
    end
    MoveTo(maxDelta.x, maxDelta.y)
    r.swing(sides.bottom)
    PlaceSticksDown()
    for i = 1, r.inventorySize() do
      itemName = inv.getStackInInternalSlot(i)
      if itemName ~= nil then
        itemName = itemName.name
        if itemName == "IC2:itemCropSeed" then
          isWrong = true
          for j = 1, seedToPlantSize do
            if seedToPlant[j] == i then isWrong = false end
          end
          if isWrong then r.select(i) r.drop(sides.bottom) end
        end
      end
    end
    r.select(s)
    r.place(sides.bottom)
    field[maxDelta.x][maxDelta.y] = delta
    CalculateAvgDelta()
    if avgDelta < 2 then mode = "spread" end
  else
    r.select(s)
    r.drop(sides.bottom)
  end
end

function PlaceNewCrop(delta, slot)
  for j = 1, mode == "stats" and 3 or fieldLength do
    for i = j % 2 == 1 and 2 or 1, mode == "stats" and 3 or fieldLength, 2 do
      if field[i][j] == "empty" then
        MoveTo(i, j)
        PlaceSticksDown()
        r.select(slot)
        r.place(sides.bottom)
        field[i][j] = delta
        plantCount = plantCount + 1
        CalculateAvgDelta()
        return
      end
    end
  end
  if mode == "spread" then mode = "fill" end
  if mode == "stats" or mode == "fill" then IncreaseStats(delta, slot) end
end

function PlaceNewSticks()
  for j = 1, fieldLength do
    for i = 1, fieldLength do
      if IsValidPlace(i, j) then
        MoveTo(i, j)
        PlaceSticksDown()
        field[i][j] = "sticks"
        PlaceSticksDown()
      end
    end
  end
end

function ProcessWeed()
  EquipItem("spade")
  r.use(sides.bottom)
  PlaceSticksDown()
  return "sticks"
end

function ProcessSeedbag(delta, place)
  if mode == "fill" and delta < 2 then  
    return delta
  end
  EquipItem("spade")
  r.use(sides.bottom)
  if place then PlaceSticksDown() end
  for i = 1, r.inventorySize() do
    itemName = inv.getStackInInternalSlot(i)
    if itemName ~= nil then
      itemName = itemName.name
      if itemName == "IC2:itemCropSeed" then
        PlaceNewCrop(delta, i)
      end
    end
  end
  if place then PlaceNewSticks() end
  return "sticks"
end

function DropToChest()
  for i = 1, r.inventorySize() do
    itemName = inv.getStackInInternalSlot(i)
    if itemName ~= nil then
      itemName = itemName.name
      if itemName ~= "berriespp:itemSpade" and
         itemName ~= "IC2:blockCrop" then
        MoveTo(fieldCenter, fieldCenter)
        r.select(i)
        for j = 1, inv.getInventorySize(sides.up) do
          if inv.dropIntoSlot(sides.up, j) then break end
          if j == inv.getInventorySize(sides.up) then
            print("No free space in chest")
            ColorChange("error")
            Panic()
          end
        end
      end
    end
  end
end

function ProcessAnotherSeedbag()
  EquipItem("spade")
  r.use(sides.bottom)
  PlaceSticksDown()
  DropToChest()
  return "sticks"
end

function CalculateDelta(scan)
  delta = math.abs(scan["crop:growth"] - sampleStats[1]) + 
          math.abs(scan["crop:gain"] - sampleStats[2]) + 
          math.abs(scan["crop:resistance"] - sampleStats[3])
  return delta
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
  plantCount = 0
  for j = 1, fieldLength/3 do
    for i = (j % 2 == 0 and fieldLength or 1),
            (j % 2 == 0 and 1 or fieldLength),
            (j % 2 == 0 and -1 or 1) do
      MoveTo(i, j)
      if i >= fieldCenter - 1 and i <= fieldCenter + 1 and
         j >= fieldCenter - 1 and j <= fieldCenter + 1 then
        field[i][j] = "center"
      else
        field[i][j] = ProcessBlock()
        if IsDelta(i, j) and (i + j) % 2 == 0 and mode ~= "fill" then
          ProcessSeedbag(field[i][j], false)
          MoveTo(i, j)
          r.swing(sides.bottom)
          field[i][j] = "empty"
        end 
      end
      if IsDelta(i, j) then plantCount = plantCount + 1 end
    end
  end
  print("Scan complete")
  CalculateAvgDelta()
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
        if newBlock then field[i][j] = ProcessSeedbag(newBlock, true) end
      end
    end
  end
  if checksForScanLeft == 0 then
    checksForScanLeft = 20
    DropToChest()
    ScanField()
  else checksForScanLeft = checksForScanLeft - 1 end
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
