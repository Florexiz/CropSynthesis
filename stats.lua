local function PlaceSticks()
  for j = 1, 3 do
    for i = 1, 3 do
      if farm.IsValidPlaceSticks(i, j) then 
        nav.MoveTo(i, j)
        farm.PlaceSticks()
        farm.PlaceSticks()
        field[i][j] = "sticks"
      end
    end
  end
end

local function IncreaseStat(slot, delta)
  max = {0, 1, 1}
  for j = 1, 3 do
    for i = 1, 3 do
      if farm.IsDelta(i, j) and field[i][j] > max[1] then
        max[1] = field[i][j]
        max[2] = i
        max[3] = j
      end
    end
  end
  nav.MoveTo(max[2], max[3])
  r.swing(0)
  farm.PlaceSticks()
  r.select(slot)
  r.place(0)
  field[max[2]][max[3]] = delta
  farm.CalculateAvgDelta()
end

local function CheckCrops()
  misc.SetColor("care")
  for j = 1, 3 do
    for i = ((j + 1) % 2) + 1, 3, 2 do
      if field[i][j] == "sticks" then
        nav.MoveTo(i, j)
        raw = s.analyze(0)
        scan = farm.AnalyzeScan(raw)
        if scan == "weed" then farm.RemoveWeed() end
        if scan == "seedbag" then farm.AnotherSeedbag() end
        if tonumber(scan) ~= nil then
          if avgDelta > farm.CalculateDelta(raw) then
            if raw["crop:size"] == maxStage then
              r.swing(0)
              farm.PlaceSticks()
              farm.PlaceSticks()
              slots = inv.SeedSlots()
              for c = 1, #slots do
                IncreaseStat(slots[c], farm.CalculateDelta(raw))
              end
              slots = inv.SeedSlots()
              for c = 1, #slots do
                r.select(slots[c])
                r.drop(0)
              end
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
end

local function Start()
  misc.SetColor("scan")
  print("Stats mode")
  for j = 1, 3 do
    for i = 1, 3 do
      nav.MoveTo(i, j)
      field[i][j] = farm.AnalyzeScan(s.analyze(0))
      if farm.IsDelta(i, j) then
        plantCount = plantCount + 1
      end
    end
  end
  farm.CalculateAvgDelta()
  PlaceSticks()
  while avgDelta > maxDelta do CheckCrops() misc.Charge() end
  print("Stats mode complete")
end

stats = {
  Start = Start
}
return stats