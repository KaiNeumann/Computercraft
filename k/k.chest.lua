local chestsizes = {
  single = 27,
  double = 54,
  compartment1 = 4*25, -- FIXME
  ender = 27,
}

local chest = {}
chest.new = function(x,y,z,chesttype,allowMixedContent)
  local self = {}
  
  local _data = {
    id = math.random(1,65000), -- FIXME
    slots = {},
    freeSlots = {},
    usedItems = {},
    chesttype = chesttype,
    allowMixedContent = allowMixedContent
    position = vector.new(x,y,z)
  }
  
  for i=1,chestsizes[chesttype] do
    self.data.slots[i] = { name = nil, ammount = 0 }
  end
  
  self.serialize = function()
    
  end
  self.unserialize = function()
  
  end
  self.load = function()
  
  end
  self.save = function()
  
  end
  self.get = function(ammount)
  
  end
  self.put = function(ammount)
    
  end
  
  return self
end

return chest
