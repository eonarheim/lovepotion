R"luastring"--(
-- DO NOT REMOVE THE ABOVE LINE. It is used to load this file as a C++ string.
-- There is a matching delimiter at the bottom of the file.

--[[
Copyright (c) 2006-2022 LOVE Development Team

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
--]]

-- Make sure love exists.
local love = require("love")
local nestlink = nil

-- Essential code boot/init.
require("love.arg")
require("love.callbacks")

local is_debug, log = pcall(require, "love.log")
local function TRACE(format, ...) end

if is_debug then
    local file = log.new("boot.log")
    TRACE = function(format, ...)
        file:trace(format, ...)
    end
end

local function uridecode(s)
    return s:gsub("%%%x%x", function(str)
        return string.char(tonumber(str:sub(2), 16))
    end)
end

local function https_setup_certs()
    local https = require("https")

    if love._os == "Cafe" then
        return https.setCertificateFile("/sdcard/config/ssl/cacert.pem")
    end
    https.setCertificateFile("sdmc/config/ssl/cacert.pem")
end

local no_game_code = false
local invalid_game_path = nil
local main_file = "main.lua"

-- This can't be overridden.
function love.boot()
    -- This is absolutely needed.
    require("love.filesystem")

    love.rawGameArguments = arg

    local arg0 = love.arg.getLow(love.rawGameArguments)

    love.filesystem.init(arg0)

    local exepath = love.filesystem.getExecutablePath()
    if #exepath == 0 then
        -- This shouldn't happen, but just in case we'll fall back to arg0.
        exepath = arg0
    end

    no_game_code = false
    invalid_game_path = nil

    -- Is this one of those fancy "fused" games?
    local can_has_game = pcall(love.filesystem.setSource, exepath)

    -- It's a fused game, don't parse --game argument
    if can_has_game then
        love.arg.options.game.set = true
    end

    -- Parse options now that we know which options we're looking for.
    love.arg.parseOptions(love.rawGameArguments)

    -- parseGameArguments can only be called after parseOptions.
    love.parsedGameArguments = love.arg.parseGameArguments(love.rawGameArguments)

    local o = love.arg.options

    local is_fused_game = can_has_game or love.arg.options.fused.set

    love.filesystem.setFused(is_fused_game)

    -- love.setDeprecationOutput(not love.filesystem.isFused())

    main_file = "main.lua"
    local custom_main_file = false

    local identity = ""
    if not can_has_game and o.game.set and o.game.arg[1] then
        local nouri = o.game.arg[1]

        if nouri:sub(1, 7) == "file://" then
            nouri = uridecode(nouri:sub(8))
        end

        local full_source = love.path.getFull(nouri)
        local source_leaf = love.path.leaf(full_source)

        if source_leaf:match("%.lua$") then
            main_file = source_leaf
            custom_main_file = true
            full_source = love.path.getFull(full_source:sub(1, -(#source_leaf + 1)))
        elseif nouri:match("%.love$") then
            full_source = nouri
        end

        can_has_game = pcall(love.filesystem.setSource, full_source)
        if not can_has_game then
            invalid_game_path = full_source
        end

        -- Use the name of the source .love as the identity for now.
        identity = love.path.leaf(full_source)
    else
        -- Use the name of the exe as the identity for now.
        identity = love.path.leaf(exepath)
    end

    -- Try to use the archive containing main.lua as the identity name. It
    -- might not be available, in which case the fallbacks above are used.
    local realdir = love.filesystem.getRealDirectory(main_file)
    if realdir then
        identity = love.path.leaf(realdir)
    end

    identity = identity:gsub("^([%.]+)", "")    -- strip leading "."'s
    identity = identity:gsub("%.([^%.]+)$", "") -- strip extension
    identity = identity:gsub("%.", "_")         -- replace remaining "."'s with "_"
    identity = #identity > 0 and identity or "game"

    -- When conf.lua is initially loaded, the main source should be checked
    -- before the save directory (the identity should be appended.)
    pcall(love.filesystem.setIdentity, identity, true)

    local has_main_file = love.filesystem.getInfo(main_file)
    local has_conf_file = love.filesystem.getInfo("conf.lua")

    if can_has_game and not (has_main_file or (not custom_main_file and has_conf_file)) then
        no_game_code = true
    end

    https_setup_certs()

    if not can_has_game then
        invalid_game_path = false
        local nogame = require("love.nogame")
        nogame()
    end
end

function love.init()
    -- Create default configuration settings.
    -- NOTE: Adding a new module to the modules list
    -- will NOT make it load, see below.
    local c = {
        title = "Untitled",
        version = love._version,
        window = {
            width = 800,
            height = 600,
            x = nil,
            y = nil,
            minwidth = 1,
            minheight = 1,
            fullscreen = false,
            fullscreentype = "desktop",
            displayindex = 1,
            vsync = 1,
            msaa = 0,
            borderless = false,
            resizable = false,
            centered = true,
            usedpiscale = true,
        },
        modules = {
            data = true,
            event = true,
            keyboard = true,
            mouse = false,
            timer = true,
            joystick = true,
            touch = true,
            image = true,
            graphics = true,
            audio = true,
            math = true,
            physics = true,
            sensor = true,
            sound = true,
            system = true,
            font = true,
            thread = true,
            window = true,
            video = false,
        },
        audio = {
            mixwithsystem = true, -- Only relevant for Android / iOS.
            mic = false,          -- Only relevant for Android.
        },
        console = false,          -- Only relevant for windows.
        identity = false,
        appendidentity = false,
        externalstorage = false,      -- Only relevant for Android.
        accelerometerjoystick = true, -- Only relevant for Android / iOS.
        gammacorrect = false,
        highdpi = false,
        renderers = nil,
        excluderenderers = nil,
    }

    -- If config file exists, load it and allow it to update config table.
    local confok, conferr
    if (not love.conf) and love.filesystem and love.filesystem.getInfo("conf.lua") then
        confok, conferr = pcall(require, "conf")
    end

    -- Yes, conf.lua might not exist, but there are other ways of making
    -- love.conf appear, so we should check for it anyway.
    if love.conf then
        confok, conferr = pcall(love.conf, c)
        -- If love.conf errors, we'll trigger the error after loading modules so
        -- the error message can be displayed in the window.
    end

    -- Open the nestlink client
    local console_ok, console_error
    if c.console and type(c.console) == "table" then
        console_ok, nestlink = pcall(require, "nestlink")

        if console_ok then
            console_ok, console_error = pcall(function() nestlink.connect(unpack(c.console)) end)
        end
    end

    -- Hack for disabling accelerometer-as-joystick on Android / iOS.
    if love._setAccelerometerAsJoystick then
        love._setAccelerometerAsJoystick(c.accelerometerjoystick)
    end

    if love._setGammaCorrect then
        love._setGammaCorrect(c.gammacorrect)
    end

    if love._setRenderers then
        local renderers = love._getDefaultRenderers()
        if type(c.renderers) == "table" then
            renderers = {}
            for i, v in ipairs(c.renderers) do
                renderers[i] = v
            end
        end

        if love.arg.options.renderers.set then
            local renderersstr = love.arg.options.renderers.arg[1]
            renderers = {}
            for r in renderersstr:gmatch("[^,]+") do
                table.insert(renderers, r)
            end
        end
        local excluderenderers = c.excluderenderers
        if love.arg.options.excluderenderers.set then
            local excludestr = love.arg.options.excluderenderers.arg[1]
            excluderenderers = {}
            for r in excludestr:gmatch("[^,]+") do
                table.insert(excluderenderers, r)
            end
        end

        if type(excluderenderers) == "table" then
            for i, v in ipairs(excluderenderers) do
                for j = #renderers, 1, -1 do
                    if renderers[j] == v then
                        table.remove(renderers, j)
                        break
                    end
                end
            end
        end

        love._setRenderers(renderers)
    end

    if love._setHighDPIAllowed then
        love._setHighDPIAllowed(c.highdpi)
    end

    if love._setAudioMixWithSystem then
        if c.audio and c.audio.mixwithsystem ~= nil then
            love._setAudioMixWithSystem(c.audio.mixwithsystem)
        end
    end

    if love._requestRecordingPermission then
        love._requestRecordingPermission(c.audio and c.audio.mic)
    end

    -- for 3DS
    local dsp_error = false

    -- Gets desired modules.
    for k, v in ipairs {
        "data",
        "thread",
        "timer",
        "event",
        "keyboard",
        "joystick",
        "mouse",
        "touch",
        "sound",
        "system",
        "sensor",
        "audio",
        "image",
        "video",
        "font",
        "window",
        "graphics",
        "math",
        "physics",
    } do
        if c.modules[v] then
            local success, error_msg = pcall(require, "love." .. v)
            if v == "audio" and not success then
                dsp_error = error_msg
            end
        end
    end

    if love.event then
        love.createhandlers()
    end

    -- Check the version
    -- c.potionversion = tostring(c.potionversion)
    -- if not love.isVersionCompatible(c.potionversion) then
    --     local major, minor, revision = c.potionversion:match("^(%d+)%.(%d+)%.(%d+)$")
    --     if (not major or not minor or not revision) or (major ~= love._potion_version_major and minor ~= love._potion_version_minor) then
    --         local msg = ("This game indicates it was made for version '%s' of LOVE.\n" ..
    --             "It may not be compatible with the running version (%s)."):format(c.potionversion, love._potion_version)

    --         print(msg)

    --         if love.window then
    --             love.window.showMessageBox("Compatibility Warning", msg, "warning")
    --         end
    --     end
    -- end

    if dsp_error then
        error(dsp_error)
    end

    if not confok and conferr then
        error(conferr)
    end

    if not console_ok and console_error then
        error(console_error)
    end

    -- Setup window here.
    if c.window and c.modules.window and love.window then
        love.window.setTitle(c.window.title or c.title)
        assert(love.window.setMode(c.window.width, c.window.height,
            {
                fullscreen = c.window.fullscreen,
                fullscreentype = c.window.fullscreentype,
                vsync = c.window.vsync,
                msaa = c.window.msaa,
                stencil = c.window.stencil,
                depth = c.window.depth,
                resizable = c.window.resizable,
                minwidth = c.window.minwidth,
                minheight = c.window.minheight,
                borderless = c.window.borderless,
                centered = c.window.centered,
                display = c.window.display,
                highdpi = c.window.highdpi, -- deprecated
                usedpiscale = c.window.usedpiscale,
                x = c.window.x,
                y = c.window.y,
            }), "Could not set window mode")
        if c.window.icon then
            assert(love.image, "If an icon is set in love.conf, love.image must be loaded!")
            love.window.setIcon(love.image.newImageData(c.window.icon))
        end
    end

    -- The first couple event pumps on some systems (e.g. macOS) can take a
    -- while. We'd rather hit that slowdown here than in event processing
    -- within the first frames.
    if love.event then
        for _ = 1, 2 do love.event.pump() end
    end

    -- Our first timestep, because window creation can take some time
    if love.timer then
        love.timer.step()
    end

    if love.filesystem then
        -- love.filesystem._setAndroidSaveExternal(c.externalstorage)
        love.filesystem.setIdentity(c.identity or love.filesystem.getIdentity(), c.appendidentity)
        if love.filesystem.getInfo(main_file) then
            require(main_file:gsub("%.lua$", ""))
        end
    end

    if no_game_code then
        local opts = love.arg.options
        local gamepath = opts.game.set and opts.game.arg[1] or ""
        local gamestr = gamepath == "" and "" or " at " .. '"' .. gamepath .. '"'

        error(("No code to run %s\nYour game might be packaged incorrectly.\nMake sure %s is at the top level of the zip or folder.")
        :format(gamestr, main_file))
    elseif invalid_game_path then
        error(("Cannot load game at path '%s'.\nMake sure a folder exists at the specified path."):format(
        invalid_game_path))
    end
end

local print, debug, tostring = print, debug, tostring

local function error_printer(msg, layer)
    local trace = debug.traceback("Error: " .. tostring(msg), 1 + (layer or 1)):gsub("\n[^\n]+$", "")
    TRACE(trace)
end

-----------------------------------------------------------
-- The root of all calls.
-----------------------------------------------------------

return function()
    local func
    local inerror = false

    local function deferErrhand(...)
        local errhand = love.errorhandler or love.errhand
        local handler = (not inerror and errhand) or error_printer
        inerror = true
        func = handler(...)
    end

    local function earlyinit()
        -- If love.boot fails, return 1 and finish immediately
        local result = xpcall(love.boot, error_printer)
        if not result then return 1 end

        -- If love.init or love.run fails, don't return a value,
        -- as we want the error handler to take over
        result = xpcall(love.init, deferErrhand)
        if not result then return end

        -- NOTE: We can't assign to func directly, as we'd
        -- overwrite the result of deferErrhand with nil on error
        local main
        result, main = xpcall(love.run, deferErrhand)
        if result then
            func = main
        end
    end

    func = earlyinit

    while func do
        local _, retval, restartvalue = xpcall(func, deferErrhand)
        if retval then
            if nestlink then
                nestlink.disconnect()
            end
            return retval, restartvalue
        end
        coroutine.yield()
    end

    return 1
end
-- DO NOT REMOVE THE NEXT LINE. It is used to load this file as a C++ string.
--)luastring"--"
