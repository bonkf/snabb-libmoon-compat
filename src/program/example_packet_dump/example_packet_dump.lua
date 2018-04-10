module(..., package.seeall)

local pcap = require("apps.pcap.pcap")
local dpdkdev = require("apps.dpdk_device.dpdk_device")
local log = require("log")

function run(parameters)
  log:info("running example_packet_dump")
  if #parameters ~= 2 then
    log:warn("Usage: example_packet_dump <pcap-file> <dev-id>\nexiting...")
    main.exit(1)
  end
  local pcap_file = parameters[1]
  local devid = tonumber(parameters[2])

  local c = config.new()
  config.app(c, "dpdk", dpdkdev.DPDKDevice, devid)
  config.app(c, "capture", pcap.PcapWriter, pcap_file)

  config.link(c, "dpdk.output -> capture.input")

  engine.configure(c)
  engine.main()
end
