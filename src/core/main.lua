local mod = {}

local lm = require "libmoon"
local engine = require "core.app"

function mod.exit(_)
  engine.configure(config.new())
  lm.stop()
end

return mod
