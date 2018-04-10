module(..., package.seeall)

local dpdkdev = require("apps.dpdk_device.dpdk_device")
local pktgen = require("apps.pktgen.pktgen")
local log = require("log")

function run(parameters)
  log:info("running pktgen")
  if #parameters ~= 2 then
    log:warn("Usage: pktgen [snabb|libmoon] <dev-id>\nexiting...")
    main.exit(1)
  end
  local mode = parameters[1]
  local devid = tonumber(parameters[2])

  local c = config.new()

  config.app(c, "pktgen", pktgen.Pktgen, mode)
  config.app(c, "dpdk", dpdkdev.DPDKDevice, devid)

  config.link(c, "pktgen.output -> dpdk.input")

  engine.configure(c)
  engine.main{duration = 1}
end
