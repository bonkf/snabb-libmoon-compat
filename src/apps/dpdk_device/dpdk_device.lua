module(..., package.seeall)

local lm = require "libmoon"
local device = require "device"
local memory = require "memory"
local log = require "log"
local link = require "core.link"

local nreadable, receive, transmit = link.nreadable, link.receive, link.transmit

DPDKDevice = {}

function DPDKDevice:new(dev_id)
  local dev = device.config{
    port = dev_id,
    txQueues = 1,
    rxQueues = 1,
    disableOffloads = true
  }
  local obj = {
    dev = dev,
    tx = dev:getTxQueue(0),
    rx = dev:getRxQueue(0),
    bufs = memory.bufArray(link.max),
  }
  return setmetatable(obj, {__index = DPDKDevice})
end

function DPDKDevice:push()
  local n = nreadable(self.input.input)
  for i = 1, n do
    self.bufs[i] = receive(self.input.input)
  end
  self.tx:sendN(self.bufs, n)
end

function DPDKDevice:pull()
  local rx = self.rx:tryRecv(self.bufs, 0)
  for i = 1, rx do
    transmit(self.output.output, self.bufs[i])
  end
end

function DPDKDevice:report()
  local stats = self.dev:getStats()
  log:info("DPDKDevice '%s' sent %d packets and received %d packets",
    self.appname, tonumber(stats.opackets), tonumber(stats.ipackets))
end
