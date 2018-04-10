--[[
   Copyright The Snabb Authors.
   Licensed under the Apache License, Version 2.0 (the "License").
   See LICENSE or https://www.apache.org/licenses/LICENSE-2.0

   Modifications by Fabian Bonk.
--]]

local mod = {}

local ffi = require "ffi"
local config = require "core.config"
local link = require "core.link"
local log = require "log"
local lm = require "libmoon"
local device = require "device"

-- not defined in the snabb API but still used by pcap.lua
mod.pull_npackets = math.floor(link.max / 10)

local c = config.new()

-- pointers to app objects created by class:new()
local app_table = {}
-- pointers to link objects created by link.new()
local link_table = {}

local breathe_pull_order = {}
local breathe_push_order = {}

local running = false
monotonic_now = false -- snabb makes this public even though it's not defined in the API
function mod.now() -- util.lua in libmoon
  return (running and monotonic_now) or lm.getTime()
end

function update_cached_time()
  monotonic_now = lm.getTime()
end

function mod.configure(config)
  local actions = compute_config_actions(c, config)
  apply_config_actions(actions)
end

function compute_config_actions(old, new)
  -- actions to be performed: remove old links/apps, start new apps, connect new apps
  local actions = {}

  for linkspec, _ in pairs(old.links) do
    if not new.links[linkspec] then -- old link doesn't exist in new config
      local fa, fl, ta, tl = config.parse_link(linkspec)
      table.insert(actions, {"unlink_output", {fa, fl}})
      table.insert(actions, {"unlink_input", {ta, tl}})
      table.insert(actions, {"free_link", {linkspec}})
    end
  end

  for appname, _ in pairs(old.apps) do
    if not new.apps[appname] then -- old app doesn't exist in new config
      table.insert(actions, {"stop_app", {appname}})
    end
  end

  local fresh_apps = {}
  for appname, info in pairs(new.apps) do
    local class, arg, old_app = info.class, info.arg, old.apps[appname]
    if not old_app then -- app is not present in old config
      table.insert(actions, {"start_app", {appname, class, arg}})
      fresh_apps[appname] = true
    elseif old_app.class ~= class then -- app has different class
      table.insert(actions, {"stop_app", {appname}})
      table.insert(actions, {"start_app", {appname, class, arg}})
      fresh_apps[appname] = true
    elseif not equal(old_app.arg, arg) then -- app has new arguments
      if class.reconfig then -- we can reconfigure the app
        table.insert(actions, {"reconfig_app", {appname, arg}})
      else -- we have to kill the app and restart it
        table.insert(actions, {"stop_app", {appname}})
        table.insert(actions, {"start_app", {appname, class, arg}})
        fresh_apps[appname] = true
      end
    end
  end

  for linkspec, _ in pairs(new.links) do
    local fa, fl, ta, tl = config.parse_link(linkspec)
    if not new.apps[fa] then
      log:fatal("no such app: %s", fa)
    elseif not new.apps[ta] then
      log:fatal("no such app: %s", ta)
    end

    local fresh_link = not old.links[linkspec] -- link doesn't exist in old config
    if fresh_link then
      table.insert(actions, {"new_link", {linkspec}})
    end
    if fresh_link or fresh_apps[fa] then
      table.insert(actions, {"link_output", {fa, fl, linkspec}})
    end
    if fresh_link or fresh_apps[ta] then
      table.insert(actions, {"link_input", {ta, tl, linkspec}})
    end
  end

  local s = "config actions:"
  for k, v in pairs(actions) do
    s = s .. "\n\t" .. k .. " " .. v[1]
    for _, arg in pairs(v[2]) do
      if type(arg) ~= "table" then
        s = s .. " " .. arg
      else
        s = s .. " {...}"
      end
    end
  end
  log:debug(s)

  return actions
end

function equal(x, y) -- copy from snabb/src/core/lib.lua
  if type(x) ~= type(y) then return false end
  if type(x) == "table" then
    for k, v in pairs(x) do
      if not equal(v, y[k]) then return false end
    end
    for k, _ in pairs(y) do
      if x[k] == nil then return false end
    end
    return true
  elseif type(x) == "cdata" then
    if x == y then return true end
    if ffi.typeof(x) ~= ffi.typeof(y) then return false end
    local size = ffi.sizeof(x)
    if ffi.sizeof(y) ~= size then return false end
    return C.memcmp(x, y, size) == 0
  else
    return x == y
  end
end

function apply_config_actions(actions)
  local ops = {}

  function ops.unlink_output(appname, linkname)
    local app = app_table[appname]
    local output = app.output[linkname]
    -- we're not adding links by index unlike snabb
    -- adding by index isn't defined in the snabb API (anymore?)
    -- according to snabb/src/core/app.lua:284 this may have been the case at some point
    app.output[linkname] = nil
    if app.link then app:link() end
  end

  function ops.unlink_input(appname, linkname)
    local app = app_table[appname]
    local input = app.input[linkname]
    app.input[linkname] = nil
    if app.link then app:link() end
  end

  function ops.free_link(linkspec)
    link.free(link_table[linkspec])
    link_table[linkspec] = nil
    c.links[linkspec] = nil
  end

  function ops.new_link(linkspec)
    link_table[linkspec] = link.new(linkspec)
    c.links[linkspec] = true
  end

  function ops.link_output(appname, linkname, linkspec)
    local app = app_table[appname]
    app.output[linkname] = assert(link_table[linkspec])
    if app.link then app:link() end
  end

  function ops.link_input(appname, linkname, linkspec)
    local app = app_table[appname]
    app.input[linkname] = assert(link_table[linkspec])
    if app.link then app:link() end
  end

  function ops.stop_app(appname)
    local app = app_table[appname]
    if app.stop then
      app:stop()
      log:debug("stopped " .. appname)
    else
      log:debug(appname .. " doesn't have :stop()")
    end
    app_table[appname] = nil
    c.apps[appname] = nil
  end

  function ops.start_app(appname, class, arg)
    local app = class:new(arg)
    if type(app) ~= "table" then
      log:fatal("bad return value from app '%s' start () method: %s", appname, tostring(app))
    end
    -- no profile zone yet
    app.appname = appname
    app.input, app.output = {}, {}
    app_table[appname] = app
    c.apps[appname] = {class = class, arg = arg}
  end

  function ops.reconfig_app(appname, arg) -- snabb passes class here but doesn't use it
    local app = app_table[appname]
    if app.reconfig then
      app:reconfig(arg)
      log:debug("reconfigured " .. appname)
    end
    c.apps[appname].arg = arg
  end

  for _, action in ipairs(actions) do
    local name, args = unpack(action)
    ops[name](unpack(args))
  end

  compute_breathe_order()
end

function compute_breathe_order() -- copy from snabb/src/core/app.lua
  breathe_pull_order, breathe_push_order = {}, {}
  local entries = {} -- tracks links outputting to apps that can pull from them
  local inputs = {} -- tracks which app each link outputs to
  local successors = {}

  for _, app in pairs(app_table) do
    if app.pull and next(app.output) then
      table.insert(breathe_pull_order, app)
      for _, link in pairs(app.output) do
        entries[link] = true
        successors[link] = {}
      end
    end
    for _, link in pairs(app.input) do inputs[link] = app end
  end

  local s = "breathe_pull_order: "
  for _, app in pairs(breathe_pull_order) do
    s = s .. "\n\t" .. app.appname
  end
  log:debug(s)

  for link, app in pairs(inputs) do
    successors[link] = {}
    if not app.pull then
      for _, succ in pairs(app.output) do
        successors[link][succ] = true
        if not successors[succ] then successors[succ] = {} end
      end
    end
  end

  for link, succs in pairs(successors) do
    for succ, _ in pairs(succs) do
      if not successors[succ] then successors[succ] = {} end
    end
  end

  local link_order = tsort(inputs, entries, successors)
  for _, link in ipairs(link_order) do
    if breathe_push_order[#breathe_push_order] ~= inputs[link] then
      table.insert(breathe_push_order, inputs[link])
    end
  end

  s = "breathe_push_order: "
  for _, app in pairs(breathe_push_order) do
    s = s .. "\n\t" .. app.appname
  end
  log:debug(s)
end

function tsort(nodes, entries, successors) -- copy from snabb/src/core/app.lua
  local visited = {}
  local post_order = {}
  local maybe_visit

  local function visit(node)
    visited[node] = true
    for succ, _ in pairs(successors[node]) do
      maybe_visit(succ)
    end
    table.insert(post_order, node)
  end

  function maybe_visit(node)
    if not visited[node] then visit(node) end
  end

  for node, _ in pairs(entries) do
    maybe_visit(node)
  end

  for node, _ in pairs(nodes) do
    maybe_visit(node)
  end

  local ret = {}
  while #post_order > 0 do
    table.insert(ret, table.remove(post_order))
  end

  return ret
end

local breathe_count = 0

function breathe()
  running = true
  update_cached_time()
  for i = 1, #breathe_pull_order do
    -- only apps with :pull() defined will be in breathe_pull_order
    local app = breathe_pull_order[i]
    if app.pull then app:pull() end
  end

  for i = 1, #breathe_push_order do
    -- only apps with :push() defined will be in breathe_push_order
    local app = breathe_push_order[i]
    if app.push then app:push() end
  end
  breathe_count = breathe_count + 1
  running = false
end

function mod.main(options)
  options = options or {}
  local done = options.done
  if options.measure_latency or options.report then
    log:warn("options other than 'done' or 'no_report' not yet supported in snabb-libmoon-compat")
  end

  if options.duration then
    if done then
      log:warn("you can't have both 'duration' and 'done'; duration will be used")
    end -- done > duration
    log:info("duration set to %f seconds", options.duration)
    lm.setRuntime(options.duration)
  end

  device.waitForLinks()

  log:info("starting snabb main loop")
  while lm.running() do
    breathe()
    if done and done() then break end -- snabb only calls done after the first breath
  end
  log:info("snabb main loop terminated")
  log:debug("breathe_count: " .. breathe_count)

  if not options.no_report then
    for _, app in pairs(app_table) do
      if app.report then app:report() end
    end
  end

  main.exit()
end

return mod
