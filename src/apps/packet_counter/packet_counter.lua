module(..., package.seeall)

local log = require("log")
local memory = require("memory")

local link = require("core.link")
local packet = require("core.packet")

PacketCounter = {}

function PacketCounter:new()
  return setmetatable({counter = 0, bufs = memory.bufArray(link.max)}, {__index = PacketCounter})
end

function PacketCounter:push()
  if not self.input.input then
    log:fatal("PacketCounter: input link not created")
  end
  local n = link.nreadable(self.input.input)
  if n > 0 then
    for i = 1, n do
      self.bufs[i] = link.receive(self.input.input)
    end
    self.counter = self.counter + n
  end
end

function PacketCounter:stop()
  log:info("PacketCounter '%s' stopped; counted %d packets in total", self.appname, self.counter)
end

function PacketCounter:report()
  log:info("PacketCounter '%s' counted %d packets", self.appname, self.counter)
end
