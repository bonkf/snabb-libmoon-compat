--[[
   Copyright The Snabb Authors.
   Licensed under the Apache License, Version 2.0 (the "License").
   See LICENSE or https://www.apache.org/licenses/LICENSE-2.0

   Modifications by Fabian Bonk.
--]]

local mod = {}

local log = require "log"

function mod.new()
  return {apps = {}, links = {}} -- appname -> info, canonical link -> true/false
end

function mod.app(config, name, class, arg)
   if type(name) ~= "string" then log:fatal("name must be a string") end
   if type(class) ~= "table" then log:fatal("class must be a table") end
   config.apps[name] = {class = class, arg = arg}
end

function mod.link(config, spec)
  config.links[canonical_link(spec)] = true
end

function canonical_link(spec)
  return ("%s.%s -> %s.%s"):format(mod.parse_link(spec))
end

function mod.parse_link(spec)
  local link_syntax = [[ *([%w_]+)%.([%w_]+) *-> *([%w_]+)%.([%w_]+) *]]
  local from_app, from_link, to_app, to_link = spec:gmatch(link_syntax)()
  if from_app and from_link and to_app and to_link then
    return from_app, from_link, to_app, to_link
  else
    log:fatal("link parse error: " .. spec)
  end
end

return mod
