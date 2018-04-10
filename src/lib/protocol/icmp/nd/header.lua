--[[
   Copyright The Snabb Authors.
   Licensed under the Apache License, Version 2.0 (the "License").
   See LICENSE or https://www.apache.org/licenses/LICENSE-2.0
--]]

-- Use of this source code is governed by the Apache 2.0 license; see LICENSE.

module(..., package.seeall)
local ffi = require("ffi")
local proto_header = require("lib.protocol.header")
local tlv = require("lib.protocol.icmp.nd.options.tlv")

-- This header implements the common structure of IPv6 ND options.
-- They are *not* of type lib.protocol.header.  Instead, this is a
-- hack to work around the fact that the current class.lua does not
-- support multiple inheritance. Classes derived from here also derive
-- from lib.protocol.header.

local nd_header = subClass(proto_header)

function nd_header:options (mem, size)
   local result = {}
   while size > 0 do
      local tlv = tlv:new_from_mem(mem, size)
      assert(tlv, "corrupt ND options")
      table.insert(result, tlv)
      local tlv_size = tlv:length()*8
      mem = mem + tlv_size
      size = size - tlv_size
   end
   assert(size == 0, "corrupt ND options")
   return(result)
end

return nd_header
