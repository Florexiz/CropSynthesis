local function GetMaxStage()
  print("Enter max growth stage of crop")
  repeat
    input = io.read()
  until tonumber(input) and tonumber(input) > 1
  return input
end

local function Initialize()
  currentPos.x = fieldCenter
  currentPos.y = fieldCenter
  for i = 1, fieldLength do
    field[i] = {}
  end
end

local function SetColor(event)
  if event == "error" then r.setLightColor(0xFF0000)
  elseif event == "scan" then r.setLightColor(0x0000FF)
  elseif event == "care" then r.setLightColor(0x00FF00)
  elseif event == "idle" then r.setLightColor(0xFFFFFF)
  end
end

local function Charge()
  if comp.energy() / comp.maxEnergy() < 0.3 then
    print("Charging")
    SetColor("idle")
    MoveTo(fieldCenter, fieldCenter)
    TryMove("bottom")
    TryMove("bottom")
    os.sleep(timeCharge)
    TryMove("top")
    TryMove("top")
    if comp.energy() / comp.maxEnergy() < 0.9 then
      print("Cant charge!")
      misc.SetColor("error")
      farm.Panic()
    end
  end
end

misc = {
  GetMaxStage = GetMaxStage,
  Initialize = Initialize,
  SetColor = SetColor,
  Charge = Charge
}
return misc