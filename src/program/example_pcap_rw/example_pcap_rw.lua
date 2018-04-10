module(..., package.seeall)

local pcap = require("apps.pcap.pcap")
local log = require("log")

function run(parameters)
  if #parameters ~= 2 then
    log:warn("Usage: example_pcap_rw <pcap-input> <pcap-output>\nexiting...")
    main.exit(1)
  end
  local infile = parameters[1]
  local outfile = parameters[2]

  log:debug("infile: " .. infile)
  log:debug("outfile: " .. outfile)

  local c = config.new()
  config.app(c, "playback", pcap.PcapReader, infile)
  config.app(c, "capture", pcap.PcapWriter, outfile)

  config.link(c, "playback.output -> capture.input")

  engine.configure(c)
  engine.main{duration = 0.01}
end
