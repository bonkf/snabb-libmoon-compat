module(..., package.seeall)

local log = require("log")

local link = require("core.link")
local packet = require("core.packet")
local datagram = require("lib.protocol.datagram")
local ethernet = require("lib.protocol.ethernet")
local ipv4 = require("lib.protocol.ipv4")
local udp = require("lib.protocol.udp")

Pktgen = {}

function Pktgen:new(mode)
  local p
  if mode == "snabb" then
    log:info("Pktgen snabb mode")
    local dgram = datagram:new(nil, nil, {delayed_commit = true})
    local ethernet_header = ethernet:new{
      dst = ethernet:pton("01:02:03:04:05:06"),
      src = ethernet:pton("00:1b:21:bc:40:0e"),
      type = 0x0800
    }
    local ipv4_header = ipv4:new{
      ttl = 255,
      src = ipv4:pton("192.168.0.1"),
      dst = ipv4:pton("10.0.0.1"),
      protocol = 17
    }
    local udp_header = udp:new{
      src_port = 2000,
      dst_port = 3000
    }
    dgram:push(udp_header)
    dgram:push(ipv4_header)
    dgram:push(ethernet_header)
    dgram:commit()
    p = dgram:packet()
  elseif mode == "libmoon" then
    log:info("Pktgen libmoon mode")
    p = packet.allocate()
    packet.resize(p, 60)
    p:getUdpPacket():fill{
      ethSrc = "01:02:03:04:05:06",
      ethDst = "00:1b:21:bc:40:0e",
      ip4Src = "192.168.0.1",
      ip4Dst = "10.0.0.1",
      udpSrc = 2000,
      udpDst = 3000,
      pktLength = 60
    }
  else
    log:fatal("Pktgen: mode is neither snabb nor libmoon")
  end
  return setmetatable({p = p, mode = mode}, {__index = Pktgen})
end

function Pktgen:pull()
  if not self.output.output then
    log:fatal("Pktgen: output link not created")
  end
  for i = 0, 100 do
    link.transmit(self.output.output, packet.clone(self.p))
  end
end

function Pktgen:report()
  log:info("Pktgen '%s' ran in %s mode", self.appname, self.mode)
end
