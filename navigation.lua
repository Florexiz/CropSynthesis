local sides = {up = 0, right = 1, down = 2, left = 3}
local currentDir = sides.up

local function Rotate(side)
  while currentDir ~= side do
    if currentDir - 1 == side or (side == sides.left and currentDir == sides.up) then
      r.turn(false)
      currentDir = currentDir - 1
      if currentDir == -1 then currentDir = 3 end
    else
      r.turn(true)
      currentDir = currentDir + 1
      if currentDir == 4 then currentDir = 0 end
    end
  end
end

function TryMove(side)
  if side == "top" then dir = 1
  elseif side == "bottom" then dir = 0
  else dir = 3 Rotate(side) end
  for i = 1, 10 do
    if r.move(dir) then return end
  end
  misc.SetColor("error")
  print("Stuck!")
  os.exit()
end

function MoveTo(x, y)
  dx = x - currentPos.x
  dy = y - currentPos.y
  for i = 1, math.abs(dx) do
    if dx > 0 then
      TryMove(sides.right)
      currentPos.x = currentPos.x + 1
    else
      TryMove(sides.left)
      currentPos.x = currentPos.x - 1
    end
  end
  for i = 1, math.abs(dy) do
    if dy > 0 then
      TryMove(sides.down)
      currentPos.y = currentPos.y + 1
    else
      TryMove(sides.up)
      currentPos.y = currentPos.y - 1
    end
  end
end

navigation = {
  Initialize = Initialize,
  TryMove = TryMove,
  MoveTo = MoveTo
}
return navigation