local function AvailiblePlace()
  for j = 1, 3 do
    for i = 1, fieldLength do
      if (i + j) % 2 == 1 and field[i][j] == "empty" then
        return true
      end
    end
  end
  return false
end

local function PlaceSticks()
  for j = 1, 3 do
    for i = 1, fieldLength do
      if farm.IsValidPlaceSticks(i, j) then 
        nav.MoveTo(i, j)
        farm.PlaceSticks()
        farm.PlaceSticks()
        field[i][j] = "sticks"
      end
    end
  end
end

local function PlaceNewCrop(slot, delta)
  for j = 1, 3 do
    for i = 1, fieldLength do
      if (i + j) % 2 == 1 and field[i][j] == "empty" then
        nav.MoveTo(i, j)
        farm.PlaceSticks()
        r.select(slot)
        r.place(0)
        plantCount = plantCount + 1
        field[i][j] = delta
        farm.CalculateAvgDelta()
        return true
      end
    end
  end
  return false
end

local function CheckCrops()
  misc.SetColor("care")
  emptySpace = true
  for j = 1, 3 do
    for i = (j % 2 == 0 and fieldLength or 1),
            (j % 2 == 0 and 1 or fieldLength),
            (j % 2 == 0 and -1 or 1) do
      if field[i][j] == "sticks" then
        nav.MoveTo(i, j)
        raw = s.analyze(0)
        scan = farm.AnalyzeScan(raw)
        if scan == "weed" then farm.RemoveWeed() end
        if scan == "seedbag" then farm.AnotherSeedbag() end
        if tonumber(scan) ~= nil then
          if maxDelta > farm.CalculateDelta(raw) then
            if raw["crop:size"] == maxStage then
              r.swing(0)
              farm.PlaceSticks()
              farm.PlaceSticks()
              slots = inv.SeedSlots()
              for c = 1, #slots do
                emptySpace = PlaceNewCrop(slots[c], farm.CalculateDelta(raw))
              end
              PlaceSticks()
            end
          else
            r.swing(0)
            farm.PlaceSticks()
            farm.PlaceSticks()
            slots = inv.SeedSlots()
            for c = 1, #slots do
              r.select(slots[c])
              r.drop(0)
            end
          end
        end
      end
    end
  end
  return emptySpace
end

local function Start()
  misc.SetColor("scan")
  skip = true
  plantCount = 0
  print("Spread mode")
  for j = 1, 3 do
    for i = (j % 2 == 0 and fieldLength or 1),
            (j % 2 == 0 and 1 or fieldLength),
            (j % 2 == 0 and -1 or 1) do
      nav.MoveTo(i, j)
      field[i][j] = farm.AnalyzeScan(s.analyze(0))
      if field[i][j] == "weed" then farm.RemoveWeed() field[i][j] = "sticks" end
      if field[i][j] == "seedbag" then farm.AnotherSeedbag() field[i][j] = "sticks" end
      if farm.IsDelta(i, j) then
        if j <= 3 and i <= 3 and (i + j) % 2 == 0 then
            field[i][j] = "sticks"
        else plantCount = plantCount + 1 end
      end
    end
  end
  farm.CalculateAvgDelta()
  PlaceSticks()
  if AvailiblePlace() then
    while CheckCrops() do misc.Charge() end
  end
  slots = inv.SeedSlots()
  for c = 1, #slots do
    r.select(slots[c])
    r.drop(0)
  end
  print("Spread complete")
end

spread = {
  Start = Start
}
return spread