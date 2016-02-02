-- k.inventory.lua

local db = {
  items = {},
  receipts = {},
}

local inventory = {}

inventory.new = function()
  local self = { data = {} }
  
  self.data.slots = {}
  self.data.freeslots = {}
  self.data.usedItems = {}
  
  self.build()
  
  self.build = function()
    self.data.slots = {}
    self.data.freeslots = {}
    self.data.usedItems = {}
    for i=1,16,1 do 
      local name,ammount = self.getSlotInfo(i)
      if name ~= nil or ammount == 0 then
        self.data.slots[i] = { name=name, ammount=ammount}
        if not self.data.usedItems[name] then self.data.usedItems[name] = 0 end
        self.data.usedItems[name] = self.data.usedItems[name] + ammount
      else
        self.data.slots[i] = { name = nil, ammount = 0 }
        table.insert(self.data.freeslots,i)
      end
    end
  end
  
  self.getSlotInfo = function(nr)
    assert(k.isInteger(nr) and k.isBetween(nr,1,16), "SlotInfo received bad slot number: "..nr)
    local detail = turtle.getItemDetail(nr)
    local name = detail and detail[ID] or nil
    if not db.items[name] then db.items[name] = detail end
    local ammount = turtle.getItemCount(nr)
    return name, ammount
  end
  
  self.getFreeSlot = function()
    if #self.data.freeslots == 0 then return false,0 end
    return true, table.remove(self.data.freeslots)
  end
  
  self.selectItem = function(name)
    for i=1,16,1 do 
      local n,_ = self.data.slots[i]
      if n==name then
        turtle.select(i)
        return true, i
      end
    end
    return false, nil
  end
  
  self.dropSlot = function(i,ammount)
    local block = turtle.detect() and turtle.inspect() or nil
    -- TODO there should be a chest in front of the turtle...
    if ammount==nil then ammount = 64 end
    turtle.select(i)
    if self.data.slots[i].ammount == 0 then return true
    local name = self.data.slots[i].name
    local oldammount = slot[i].ammount
    local success = turtle.drop(ammount)
    if success then 
      local newammount = oldammount - ammount
      if newammount < 1 then
        self.data.slots[i] = { name=nil, ammount=0 }
        self.data.usedItems[name] = self.data.usedItems[name] - oldammount
        table.insert(self.data.freeslots,i)
      else 
        self.data.slots[i].ammount = newammount
        self.data.usedItems[name] = self.data.usedItems[name] - ammount
      end
    end
    return success
  end
  
  self.dropAll = function()
    for i=1,16,1 do
      self.dropSlot(i)
    end
  end
  
  self.take = function(name, ammount)
    local wrongItem_slots = {}
    local cleanup = function()
      for _,i in pairs(wrongItem_slots) do
        self.dropSlot(i,64)
      end
    end
    for i=1,16,1 do
      local success, slot = self.getFreeSlot()
      if not success then break end
      turtle.select(slot)
      local success = turtle.suck(ammount)
      if success then 
        local name, ammount = self.getSlotInfo(slot)
        self.data.slots[slot] = { name=name, ammount=ammount }
        self.data.usedItems[name] = self.data.usedItems[name] + self.data.slots[slot].ammount
        if name == self.data.slots[slot].name then
          cleanup()
          return true
        end
        table.insert(wrongItem_slots,slot)
      else -- nothing taken
        table.insert(self.data.freeslots,slot)
      end
    end
    cleanup()
    return false
  end
  
  self.arrange = function(pattern)
    --[[
      for receipts have a look at https://github.com/jnordberg/minecraft-replicator/blob/master/lib/items.lua !!!
      receipe[name] = pattern = [ { slotNr, name, ammount } ]
    ]]
    -- find required amounts per name
    local items = {}
    for k,v in pairs(pattern) do
      if not items[v.name] then items[v.name] = 0 end
      items[v.name] = items[v.name] + v.amount
    end
    -- drop unused items, and fill up necessary amounts
    for i=1,16,1 do
      
    
    for k,v in pairs(items) do
      self.take(k, tonumber(v) )  -- what if > 64 ? or stacksize? does that happen at all or is every receipe only with single items?
    end
  end
  
  self.craft = function(receipeName)
  
  end
  
  self.learnReceipe = function()
    -- scan inventory
    self.build()
    -- save pattern
    local pattern = {}
    for k,v in pairs(self.data.slots)
      table.insert(pattern, { name = v.name, ammount = v.ammount })
    end
    -- craft
    turtle.craft()
    -- check outcome with stack capacity
    self.build()
    -- safe receipe
  end
  
  self.saveReceipts = function()
  
  end
  
  self.loadReceipts = function()
  
  end
  
  return self
end

return inventory
