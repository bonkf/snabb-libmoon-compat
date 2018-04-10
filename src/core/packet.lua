--[[
   Copyright The Snabb Authors.
   Licensed under the Apache License, Version 2.0 (the "License").
   See LICENSE or https://www.apache.org/licenses/LICENSE-2.0

   Modifications by Fabian Bonk.
--]]

local mod = {}

local ffi = require "ffi"

ffi.cdef[[
    void *memmove(void *dst, const void *src, size_t len);
]]

local packet = require "packet"
local memory = require "memory"

local mempool = memory.createMemPool{n=1e5}

mod.max_payload = 10 * 1024 -- same as snabb

function mod.allocate()
  return mempool:alloc(0) -- may be a performance concern
end

function mod.free(p)
  p:free()
end

function mod.clone(p)
  local pkt = mod.allocate()
  local len = p:getSize()
  mod.resize(pkt, len)
  ffi.copy(pkt:getBytes(), p:getBytes(), len)
  return pkt
end

function mod.resize(p, length)
  assert(length <= mod.max_payload, "packet payload overflow: " .. length)
  p:setSize(length)
end

function mod.append(p, ptr, length)
  -- size check is performed in resize
  mod.resize(p, p:getSize() + length)
  ffi.copy(p:getBytes() + p:getSize(), ptr, length)
  return p
end

function mod.prepend(p, ptr, length)
  local l = p:getSize()
  -- size check is performed in resize
  mod.resize(p, l + length)
  ffi.C.memmove(p:getBytes() + length, p:getBytes(), l)
  ffi.copy(p:getBytes(), ptr, length)
  return p
end

function mod.shiftleft(p, length)
  assert(0 <= length and length <= p:getSize())
  ffi.C.memmove(p:getBytes(), p:getBytes() + length, p:getSize() - length)
  mod.resize(p, p:getSize() - length)
  return p
end

function mod.shiftright(p, length)
  local l = p:getSize()
  mod.resize(p, l + length)
  ffi.C.memmove(p:getBytes() + length, p:getBytes(), l)
  ffi.fill(p:getBytes(), length)
  return p
end

function mod.from_pointer(ptr, length)
  local p = mod.allocate()
  mod.resize(p, length)
  ffi.copy(p:getBytes(), ptr, length)
  return p
end

function mod.from_string(str)
  return mod.allocate():setRawPacket(str)
end

-- Snabb doesn't implement this function even though it is in their documentation
function mod.clone_to_memory(ptr, p)
  ffi.copy(ptr, p:getBytes(), p:getSize())
end

return mod
