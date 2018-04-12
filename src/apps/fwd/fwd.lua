module(..., package.seeall)

local log = require("log")
local link = require("core.link")

Fwd = {}

function Fwd:new()
  return setmetatable({transmitted = 0}, {__index = Fwd})
end

function Fwd:pull()
  if not self.output.output then
    log:fatal("Fwd: output link not created")
  elseif not self.input.input then
    log:fatal("Fwd: input link not created")
  end
  local n = link.nreadable(self.input.input)
  for _ = 1, n do
    link.transmit(self.output.output, link.receive(self.input.input))
  end
  self.transmitted = self.transmitted + n
end

function Fwd:report()
  log:info("Fwd '%s' transmitted %d packets",
    self.appname, self.transmitted)
end
