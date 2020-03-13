local function CalculateDelta(scan)
  delta = math.abs(scan["crop:growth"] - sampleStats[1]) + 
          math.abs(scan["crop:gain"] - sampleStats[2]) + 
          math.abs(scan["crop:resistance"] - sampleStats[3])
  return delta
end

local function IsDelta(i, j)
  if tonumber(field[i][j]) ~= nil then return true else return false end
end

local function Panic()
  print("Removing empty crop sticks")
  for j = 1, fieldLength do
    for i = 1, fieldLength do
      if field[i][j] == "sticks" then
        nav.MoveTo(i, j)
        r.swing(0)
      end
    end
  end
  os.exit()
end

local function IsValidPlaceSticks(i, j)
  if field[i][j] ~= "empty" then return false end
  count = 0
  if i > 1 and IsDelta(i - 1 , j) then count = count + 1 end
  if i < fieldLength and IsDelta(i + 1, j) then count = count + 1 end
  if j > 1 and IsDelta(i , j - 1) then count = count + 1 end
  if j < fieldLength and IsDelta(i, j + 1) then count = count + 1 end
  if count >= 2 then return true else return false end
end

local function CalculateAvgDelta()
  sum = 0
  for j = 1, fieldLength do
    for i = 1, fieldLength do
      if IsDelta(i, j) then sum = sum + field[i][j] end
    end
  end
  avgDelta = sum / plantCount
  print("New average delta: " .. avgDelta)
end

local function AnotherSeedbag()
  inv.Equip("spade")
  r.use(0)
  inv.Equip("sticks")
  r.use(0)
  inv.DropToChest()
end

local function PlaceSticks()
  inv.Equip("sticks")
  r.use(0)
  sticksCount = sticksCount - 1
end

local function RemoveWeed()
  inv.Equip("spade")
  r.use(0)
  PlaceSticks()
end

local function AnalyzeScan(scan)
  if scan == nil then return "sticks"
  elseif scan.name == "minecraft:air" then return "empty"
  elseif scan.name == "IC2:blockCrop" then
    if scan["crop:name"] == "weed" then return "weed" end
    if plantName == "?" then plantName = scan["crop:name"] end
    if scan["crop:name"] == plantName then return CalculateDelta(scan)
    else return "seedbag" end
  else return "unknown" end
end

farmutils = {
  AnalyzeScan = AnalyzeScan,
  IsDelta = IsDelta,
  CalculateDelta = CalculateDelta,
  CalculateAvgDelta = CalculateAvgDelta,
  IsValidPlaceSticks = IsValidPlaceSticks,
  RemoveWeed = RemoveWeed,
  PlaceSticks = PlaceSticks,
  AnotherSeedbag = AnotherSeedbag,
  Panic = Panic
}
return farmutils