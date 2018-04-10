module(..., package.seeall)

local packet_counter = require("apps.packet_counter.packet_counter")
local dpdkdev = require("apps.dpdk_device.dpdk_device")
local log = require("log")

function run(parameters)
  log:info("running example_packet_count")
  if #parameters ~= 2 then
    log:warn("Usage: example_packet_count <dev-id0> <dev-id1>\nexiting...")
    main.exit(1)
  end
  local devid0 = tonumber(parameters[1])
  local devid1 = tonumber(parameters[2])

  local c = config.new()
  config.app(c, "dpdk0", dpdkdev.DPDKDevice, devid0)
  config.app(c, "counter0", packet_counter.PacketCounter)

  config.app(c, "dpdk1", dpdkdev.DPDKDevice, devid1)
  config.app(c, "counter1", packet_counter.PacketCounter)

  config.link(c, "dpdk0.output -> counter0.input")
  config.link(c, "dpdk1.output -> counter1.input")

  engine.configure(c)
  engine.main()
end
