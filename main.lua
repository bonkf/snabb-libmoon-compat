local lm = require "libmoon"
local log = require "log"

function configure(parser)
  parser:description("snabb-libmoon compatibility module")
  parser:argument("snabbprogram", "path to snabb program")
  parser:option("--snabbapps", "path to custom snabb app directory")
  parser:argument("snabbprogparams", "parameters passed to snabb program"):args("*")
  return parser:parse()
end

local function prepend_path(str)
  local path
  if string.sub(str, #str, #str) == "/" then
    path = str
  else
    path = str .. "/"
  end
  log:debug("adding " .. path .. " to package.path")
  package.path = path .. "?.lua;" .. package.path
end

function snabb_libmoon_compat_entrypoint(progpath, args)
  log:setLevel("DEBUG")
  log:debug("enabled DEBUG log level in slave")
  if args.snabbapps ~= nil then
    prepend_path(args.snabbapps)
    log:info("snabb app directory: " .. args.snabbapps)
  end
  prepend_path("./src") -- overlay our own version of the snabb api

  -- loading default modules into global scope
  config = require("core.config")
  engine = require("core.app")
  -- memory = require("core.memory")
  link = require("core.link")
  packet = require("core.packet")
  -- timer  = require("core.timer")
  main = require("core.main") -- unlike snabb we have a separate main module

  require("lib.lua.class")

  main.parameters = args.snabbprogparams

  log:info("launching snabb program at %s", progpath)
  local program = require(progpath)
  if not program.run then
    log:fatal("snabb program at %s not found/has no 'run' function", progpath)
  end
  if not args.snabbprogparams then
    program.run{}
  else
    program.run(args.snabbprogparams)
  end
  main.exit()
end

function master(args)
  log:setLevel("DEBUG")
  log:debug("enabled DEBUG log level in master")
  log:info("snabb program: " .. args.snabbprogram)
  s = "snabb program parameters:"
  for k,v in pairs(args.snabbprogparams) do
    s = s .. "\n\t\t" .. k .. ":" .. v
  end
  log:info(s)
  lm.startTask("snabb_libmoon_compat_entrypoint", "program." .. args.snabbprogram .. "." .. args.snabbprogram, args)
  lm.waitForTasks()
end
