local mod = {}

local log = require("log")
local ffi = require("ffi")

local ptr_name_mapping = {}
local name_ptr_mapping = {}

function map(name, type, readonly, create)
  if readonly then log:warn("shm: readonly will be ignored") end
  if create then
    local obj = ffi.new(ffi.typeof(type))
    local ptr = pointer_to_number(obj)
    name_ptr_mapping[name] = ptr
    ptr_name_mapping[ptr] = name
    return obj
  else
    local obj = shmbufs[name]
    if not obj then log:fatal("shm: %s does not exist", name) end
    return obj
  end
end

function mod.create(name, type)
  return map(name, type, false, true)
end

function mod.open(name, type, readonly)
  return map(name, type, readonly, false)
end

function mod.exists(name)
  return shmbufs[name] ~= nil
end

function mod.unmap(ptr)
  local name = ptr_name_mapping[ptr]
  if not name then log:fatal("shm mapping not found") end
  ptr_name_mapping[ptr] = nil
  name_ptr_mapping[name] = nil
end

function mod.unlink(name)
  local ptr = name_ptr_mapping[ptr]
  if not ptr then log:fatal("shm mapping %s not found", name) end
  ptr_name_mapping[ptr] = nil
  name_ptr_mapping[name] = nil
end

-- direct copy from snabb/src/core/shm.lua
function pointer_to_number(ptr)
  return tonumber(ffi.cast("uint64_t", ffi.cast("void*", ptr)))
end

function mod.children(name)
  return {}
end

mod.types = {}

function mod.register(type, module)
  if not module then log:fatal("shm: must supply module") end
  if types[type] then log:fatal("shm: duplicate name: %s", type) end
  if not type(module.create) == "function" then
    log:fatal("shm: module needs 'create' function") 
  end
  if not type(module.open) == "function" then
    log:fatal("shm: module needs 'open' function")
  end
  types[type] = module
  return type
end

return mod