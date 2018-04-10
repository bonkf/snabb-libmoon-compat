module(..., package.seeall)

local log = require("log")
local link = require("core.link")

Echo = {}

function Echo:new()
  return setmetatable({transmitted = 0}, {__index = Echo})
end

function Echo:pull()
  if not self.output.output then
    log:fatal("Echo: output link not created")
  elseif not self.input.input then
    log:fatal("Echo: input link not created")
  end
  local n = link.nreadable(self.input.input)
  for _ = 1, n do
    link.transmit(self.output.output, link.receive(self.input.input))
  end
  self.transmitted = self.transmitted + n
end

function Echo:report()
  log:info("Echo '%s' transmitted %d packets",
    self.appname, self.transmitted)
end
