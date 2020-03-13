local function PrintField()
  os.execute("cls")
  for i = 1, fieldLength do
    print(field[i][1].."\t"..field[i][2].."\t"..field[i][3])
  end
end

local function AvailiblePlace()
  for j = 4, fieldLength do
    for i = 1, fieldLength do
      if field[i][j] == "empty" then return true end
    end
  end
  return false
end

local function PlaceNewCrop(slot, delta)
  for j = 4, fieldLength do
    for i = 1, fieldLength do
      if field[i][j] == "empty" then
        nav.MoveTo(i, j)
        farm.PlaceSticks()
        r.select(slot)
        r.place(0)
        plantCount = plantCount + 1
        field[i][j] = delta
        farm.CalculateAvgDelta()
        return
      end
    end
  end
  r.select(slot)
  r.drop(0)
end

local function CheckCrops()
  misc.SetColor("care")
  emptySpace = false
  for j = 1, 3 do
    for i = (j % 2 == 0 and fieldLength or 1),
            (j % 2 == 0 and 1 or fieldLength),
            (j % 2 == 0 and -1 or 1) do
      if field[i][j] == "sticks" then
        emptySpace = true
        nav.MoveTo(i, j)
        raw = s.analyze(0)
        scan = farm.AnalyzeScan(raw)
        if scan == "weed" then farm.RemoveWeed() end
        if scan == "seedbag" then farm.AnotherSeedbag() end
        if tonumber(scan) ~= nil then
          if maxDelta >= farm.CalculateDelta(raw) then
            if raw["crop:size"] == maxStage then
              if AvailiblePlace() then
                r.swing(0)
                farm.PlaceSticks()
                farm.PlaceSticks()
                slots = inv.SeedSlots()
                for c = 1, #slots do
                  PlaceNewCrop(slots[c], farm.CalculateDelta(raw))
                end
              else
                field[i][j] = farm.CalculateDelta(raw)
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
  return emptySpace
end

local function Start()
  print("Fill mode")
  plantCount = 0
  misc.SetColor("scan")
  for j = 1, fieldLength do
    for i = (j % 2 == 0 and fieldLength or 1),
            (j % 2 == 0 and 1 or fieldLength),
            (j % 2 == 0 and -1 or 1) do
      if j >= fieldCenter - 1 and j <= fieldCenter + 1 and
         i >= fieldCenter - 1 and i <= fieldCenter + 1 then
        field[i][j] = "center"
      else
        nav.MoveTo(i, j)
        field[i][j] = farm.AnalyzeScan(s.analyze(0))
        if field[i][j] == "weed" then farm.RemoveWeed() field[i][j] = "sticks" end
        if field[i][j] == "seedbag" then farm.AnotherSeedbag() field[i][j] = "sticks" end
        if farm.IsDelta(i, j) then
          if j <= 3 and (i + j) % 2 == 0 then
            field[i][j] = "sticks"
          else plantCount = plantCount + 1 end
        end
      end
    end
  end
  farm.CalculateAvgDelta()
  while CheckCrops() do PrintField() misc.Charge() os.sleep(1) end
  print("Fill mode complete")
end

fill = {
    Start = Start
}
return fill