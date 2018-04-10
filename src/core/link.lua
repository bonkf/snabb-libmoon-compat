--[[
   Copyright The Snabb Authors.
   Licensed under the Apache License, Version 2.0 (the "License").
   See LICENSE or https://www.apache.org/licenses/LICENSE-2.0

   Modifications by Fabian Bonk.
--]]

local mod = {}

local ffi = require "ffi"
local C = ffi.C

local log = require "log"

local packet = require "core.packet"

local link_size = 2048
mod.max = link_size - 1 -- not defined in the snabb API but still used by some apps

ffi.cdef [[
    struct link {
        struct rte_mbuf *packets[2048];
        int read, write;
    }
]]

local link_t = ffi.typeof("struct link")
local ptr_size = ffi.sizeof("struct rte_mbuf*")
local band = bit.band

function mod.new(name)
  return ffi.new(link_t)
end

function mod.free(link)
  while not mod.empty(link) do
    packet.free(mod.receive(link))
  end
end

function mod.empty(link)
  return link.read == link.write
end

function mod.full(link)
  return band(link.write + 1, mod.max) == link.read
end

function mod.nreadable(link)
  if link.read > link.write then
    return link.write + link_size - link.read
  else
    return link.write - link.read
  end
end

function mod.nwriteable(link)
  return mod.max - mod.nreadable(link)
end

function mod.receive(link)
  local p = link.packets[link.read]
  link.read = band(link.read + 1, mod.max)
  return p
end

function mod.front(link)
  return (link.read ~= link.write) and link.packets[link.read] or nil
end

function mod.transmit(link, p)
  if mod.full(link) then
    packet.free(p)
  else
    link.packets[link.write] = p
    link.write = band(link.write + 1, mod.max)
  end
end

function mod.stats(link)
  log:fatal("stats not supported")
end

return mod
