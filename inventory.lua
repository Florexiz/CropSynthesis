local function DropToChest()
  for i = 1, r.inventorySize() do
    itemName = invent.getStackInInternalSlot(i)
    if itemName ~= nil then
      itemName = itemName.name
      if itemName ~= "berriespp:itemSpade" and
         itemName ~= "IC2:blockCrop" then
        nav.MoveTo(fieldCenter, fieldCenter)
        r.select(i)
        for j = 1, invent.getInventorySize(1) do
          if invent.dropIntoSlot(1, j) then break end
          if j == invent.getInventorySize(1) then
            print("No free space in chest")
            misc.SetColor("error")
            farm.Panic()
          end
        end
      end
    end
  end
end

local function SeedSlots()
  slots = {}
  for i = 1, r.inventorySize() do
    itemName = invent.getStackInInternalSlot(i)
    if itemName ~= nil then
      itemName = itemName.name
      if itemName == "IC2:itemCropSeed" then
        slots[#slots + 1] = i
      end
    end
  end
  return slots
end

local function Equip(item)
  if sticksCount > 1 and item == "sticks" then return end
  if sticksCount == -1 and item == itemInHand then return end
  for i = 1, r.inventorySize() do
    itemName = invent.getStackInInternalSlot(i)
    if itemName ~= nil then
      itemName = itemName.name
      if item == "sticks" and itemName == "IC2:blockCrop" then
        r.select(i)
        if r.count() > 1 then
          sticksCount = r.count()
          invent.equip()
          itemInHand = item
          return
        end
      elseif item == "spade" and itemName == "berriespp:itemSpade" then
        r.select(i)
        invent.equip()
        sticksCount = -1
        itemInHand = item
        return
      end
    end
  end
  print("Missing item: " .. item)
  misc.SetColor("error")
  farm.Panic()
end

inventory = {
  DropToChest = DropToChest,
  Equip = Equip,
  SeedSlots = SeedSlots
}
return inventory