--[[
   Copyright The Snabb Authors.
   Licensed under the Apache License, Version 2.0 (the "License").
   See LICENSE or https://www.apache.org/licenses/LICENSE-2.0

   Modifications by Fabian Bonk.
--]]

local mod = {}

local band, bor, bnot, lshift, rshift, bswap =
   bit.band, bit.bor, bit.bnot, bit.lshift, bit.rshift, bit.bswap

mod.htons = hton16
mod.ntohs = ntoh16

mod.htonl = hton
mod.ntohl = ntoh

mod.getenv = os.getenv

-- direct copy from snabb/src/core/lib.lua
function string:split(pat)
  local st, g = 1, self:gmatch("()("..pat..")")
  local function getter(self, segs, seps, sep, cap1, ...)
    st = sep and seps + #sep
    return self:sub(segs, (seps or 0) - 1), cap1 or sep, ...
  end
  local function splitter(self)
    if st then return getter(self, st, g()) end
  end
  return splitter, self
end

local bitfield_endian_conversion = 
   { [16] = { ntoh = ntoh16, hton = hton16 },
     [32] = { ntoh = ntoh, hton = hton }
  }

function mod.bitfield(size, struct, member, offset, nbits, value)
   local conv = bitfield_endian_conversion[size]
   local field
   if conv then
      field = conv.ntoh(struct[member])
   else
      field = struct[member]
   end
   local shift = size-(nbits+offset)
   local mask = lshift(2^nbits-1, shift)
   local imask = bnot(mask)
   if value then
      field = bor(band(field, imask),
                  band(lshift(value, shift), mask))
      if conv then
         struct[member] = conv.hton(field)
      else
         struct[member] = field
      end
   else
      return rshift(band(field, mask), shift)
   end
end

return mod