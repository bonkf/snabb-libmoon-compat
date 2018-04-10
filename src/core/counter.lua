local mod = {}

-- non-threadsafe

local counters = {}

function mod.create(name, initval)
  if counters[name] then return counters[name] end
  local counter = {c = initval or 0}
  counters[name] = counter
  return counter
end

function mod.open(name)
  return counters[name]
end

function mod.delete(name)
  counters[name] = nil
end

function mod.commit()
  return
end

function mod.set(counter, value)
  counter.c = value
end

function mod.add(counter, value)
  if counter then -- workaround for incomplete shm implementation
    counter.c = counter.c + (value or 1)
  end
end

function mod.read(counter)
  return counter.c
end

return mod
