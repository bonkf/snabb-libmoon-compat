module(..., package.seeall)

local pcap = require("apps.pcap.pcap")
local dpdkdev = require("apps.dpdk_device.dpdk_device")
local packet_counter = require("apps.packet_counter.packet_counter")

local log = require("log")

function run(parameters)
  log:info("running example_packet_loop")
  if #parameters ~= 3 then
    log:warn("Usage: example_packet_loop <pcap-input> <output-dev-id> <input-dev-id>\nexiting...")
    main.exit(1)
  end
  local infile = parameters[1]
  local outdevid = tonumber(parameters[2])
  local indevid = tonumber(parameters[3])

  log:debug("infile %s, outdevid %d, indevid %d", infile, outdevid, indevid)

  local c = config.new()
  config.app(c, "replay", pcap.PcapReader, infile)
  config.app(c, "playback", dpdkdev.DPDKDevice, outdevid)
  config.app(c, "receive", dpdkdev.DPDKDevice, indevid)
  config.app(c, "counter", packet_counter.PacketCounter)

  config.link(c, "replay.output -> playback.input")
  config.link(c, "receive.output -> counter.input")

  engine.configure(c)
  engine.main{duration = 0.1}
end
