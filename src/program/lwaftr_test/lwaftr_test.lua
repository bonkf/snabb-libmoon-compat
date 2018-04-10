module(..., package.seeall)

local pcap = require("apps.pcap.pcap")
local dpdkdev = require("apps.dpdk_device.dpdk_device")
local lwaftr = require("apps.lwaftr.lwaftr")
local log = require("log")

function run(parameters)
  log:info("running lwaftr_test")
  if #parameters ~= 2 then
    log:warn("Usage: lwaftr_test \nexiting...")
    main.exit(1)
  end

  local c = config.new()
  config.app(c, "lwaftr", lwaftr.LwAftr)

  engine.configure(c)
  engine.main()
end
