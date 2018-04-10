module(..., package.seeall)

local pcap = require("apps.pcap.pcap")
local dpdkdev = require("apps.dpdk_device.dpdk_device")
local log = require("log")

function run(parameters)
  log:info("running example_replay")
  if #parameters ~= 2 then
    log:warn("Usage: example_replay <pcap-file> <dev-id>\nexiting...")
    main.exit(1)
  end
  local pcap_file = parameters[1]
  local devid = tonumber(parameters[2])

  local c = config.new()
  config.app(c, "replay", pcap.PcapReader, pcap_file)
  config.app(c, "dpdk", dpdkdev.DPDKDevice, devid)

  config.link(c, "replay.output -> dpdk.input")

  engine.configure(c)
  engine.main()
end
