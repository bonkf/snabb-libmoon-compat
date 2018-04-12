module(..., package.seeall)

local fwd = require("apps.fwd.fwd")
local dpdkdev = require("apps.dpdk_device.dpdk_device")
local log = require("log")

function run(parameters)
  log:info("running echo")

  if #parameters > 3 or #parameters < 1 then
    log:warn("Usage: echo <dev-id> [chain-length] [duration]\nexiting...")
    main.exit(1)
  end

  local devid = tonumber(parameters[1])
  local chainlen = tonumber(parameters[2]) or 1

  if chainlen < 1 then
    log:warn("chain-length < 1, defaulting to 1")
    chainlen = 1
  end

  local c = config.new()

  config.app(c, "dpdk", dpdkdev.DPDKDevice, devid)

  for i = 1, chainlen do
    config.app(c, "fwd" .. i, fwd.Fwd)
  end

  for i = 1, chainlen - 1 do
    config.link(c, string.format("fwd%d.output -> fwd%d.input", i, i + 1))
  end

  config.link(c, "dpdk.output -> fwd1.input")
  config.link(c, string.format("fwd%d.output -> dpdk.input", chainlen))

  engine.configure(c)
  engine.main{duration = tonumber(parameters[3])}
end
