module(..., package.seeall)

local pcap = require("pcap")
local memory = require("memory")
local log = require("log")

local engine = require("core.app")
local link = require("core.link")
local packet = require("core.packet")

PcapReader = {}

function PcapReader:new(filename)
  local obj = {
    reader = pcap:newReader(filename),
    mempool = memory.createMemPool(),
    transmitted = 0
  }
  return setmetatable(obj, {__index = PcapReader})
end

function PcapReader:pull()
  if not self.output.output then
    log:fatal("PcapReader: output link not created")
  end
  local limit = engine.pull_npackets
  while limit > 0 and not self.done do
    limit = limit - 1
    local buf = self.reader:readSingle(self.mempool, 1024)
    if buf then
      local pkt = packet.from_pointer(buf:getBytes(), buf:getSize())
      link.transmit(self.output.output, pkt)
      self.transmitted = self.transmitted + 1
    else
      self.done = true
    end
  end
end

function PcapReader:stop()
  log:debug("stopping pcap reader '%s'", self.appname)
  self.reader:close()
end

function PcapReader:report()
  log:debug("PcapReader '%s' transmitted %d packets", self.appname, self.transmitted)
end

PcapWriter = {}

function PcapWriter:new(filename)
  local obj = {
    writer = pcap:newWriter(filename),
    received = 0
  }
  return setmetatable(obj, {__index = PcapWriter})
end

function PcapWriter:push()
  if not self.input.input then
    log:fatal("PcaPWriter: input link not created")
  end
  local received = 0
  while not link.empty(self.input.input) do
    local p = link.receive(self.input.input)
    self.writer:writeBuf(engine.now(), p)
    packet.free(p)
    self.received = self.received + 1
  end
end

function PcapWriter:stop()
  log:debug("stopping pcap writer '%s'", self.appname)
  self.writer:close()
end

function PcapWriter:report()
  log:debug("PcapWriter '%s' received %d packets", self.appname, self.received)
end
