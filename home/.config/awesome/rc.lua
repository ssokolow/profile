-- ### TODO: Verify the following Openbox behaviours are copied over:
--
-- * Make the appicon in the titlebar into a WM functions menu
-- * Add an iconify button and icon to the left of maximize
-- * Look into getting Vim to fold on markdown comments
--   [(1)](http://stackoverflow.com/questions/3828606/vim-markdown-folding/3842504#3842504)
--   [(2)](http://vim.1045645.n5.nabble.com/markdown-folds-td3331979.html)
-- * See if it's possible to implement windowshading
-- * `<resistance>` (Full-blown snap-to if possible. Otherwise, match OB value)
-- * `<mouse><dragThreshold>`
-- * `<mouse><screenEdgeWarpTime>`
-- * `<mouse><context name="...">`

-- #### Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")

-- Load Debian menu entries
require("debian.menu")

-- #### 3rd-party additions
-- deitarion/SSokolow's helper routines
require("helpful")
-- Scratchpad/Dropdown addon
require("scratch")

-- ### Variable definitions

-- Themes define colours, icons, and wallpapers
beautiful.init(awful.util.getdir("config") .. "/themes/defburn/theme.lua")

-- #### Default applications used by various menu entries and keybinds
terminal = "xterm"
editor_cmd = "gvim"
-- **Example:** Autodetect shell editor and run in terminal
--     editor = os.getenv("EDITOR") or "nano"
--     editor_cmd = terminal .. " -e " .. editor

-- #### Default modkey:
-- Usually, `Mod4` is the key with a logo between `Control` and `Alt`.
-- If you do not like this or do not have such a key,
-- I suggest you remap `Mod4` to another key using `xmodmap` or other tools.
-- However, you can use another modifier like `Mod1`, but it may conflict with
-- other applications.
modkey = "Mod4"

-- I don't want ScrapBook's Firefox notifications covering the tab closer
naughty.config.default_preset.position         = "bottom_right"

-- #### Table of layouts to cover with awful.layout.inc, order matters.
-- **TODO:** Figure out how to persist layout state across Mod4+Ctrl+r
layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
}

-- ### Tags

-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
end

-- ### Menu

-- Define a submenu for WM control
myawesomemenu = {
   { "run...", function () mypromptbox[mouse.screen]:run() end},
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

-- ...and a main menu to put it in
mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "Debian", debian.menu.Debian_menu.Debian },
                                    { "open terminal", terminal }
                                  }
                        })

-- Create a laucher widget to show it
mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })

-- ### Wibox

-- Create a textclock widget
mytextclock = awful.widget.textclock({ align = "right" }, "%Y-%m-%d %R ")

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewprev),
                    awful.button({ }, 5, awful.tag.viewnext)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if not c:isvisible() then
                                                  awful.tag.viewonly(c:tags()[1])
                                              end
                                              if client.focus == c and not c.minimized then
                                                  c.minimized = not c.minimized
                                              else
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "bottom", screen = s, ontop = true })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        -- **TODO:** [wiki: Widgets in awesome](https://awesome.naquadah.org/wiki/Widgets_in_awesome)
        {
            mylauncher,
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        mytextclock,
        s == screen.count() and mysystray or nil,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end

-- ### Global mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle({keygrabber=true}) end),
    awful.button({ }, 4, awful.tag.viewprev),
    awful.button({ }, 5, awful.tag.viewnext),
    -- My mouse's side buttons
    awful.button({ }, 8, awful.tag.viewnext),
    awful.button({ }, 9, awful.tag.viewprev)
))

-- ### Global key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    -- #### Focus
    -- **TODO:** These also need to `raise()`
    awful.key({ modkey,           }, "Up",    function () awful.client.focus.bydirection("up")    end),
    awful.key({ modkey,           }, "Down",  function () awful.client.focus.bydirection("down")  end),
    awful.key({ modkey,           }, "Left",  function () awful.client.focus.bydirection("left")  end),
    awful.key({ modkey,           }, "Right", function () awful.client.focus.bydirection("right") end),
    awful.key({ modkey, "Shift"   }, "Up",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey, "Shift"   }, "Down",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey, "Shift"   }, "Left" , function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey, "Shift"   }, "Right", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey,           }, "Prior", awful.tag.viewprev),
    awful.key({ modkey,           }, "Next",  awful.tag.viewnext),
    awful.key({ modkey,           }, "u",     awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- #### Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey,           }, "w", function () mymainmenu:toggle({keygrabber=true}) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- #### Layout manipulation
    awful.key({ modkey, "Control" }, "Up",    function () awful.client.swap.bydirection("up")       end),
    awful.key({ modkey, "Control" }, "Down",  function () awful.client.swap.bydirection("down")     end),
    awful.key({ modkey, "Control" }, "Left",  function () awful.client.swap.bydirection("left")     end),
    awful.key({ modkey, "Control" }, "Right", function () awful.client.swap.bydirection("right")    end),
    awful.key({ modkey, "Control", "Shift" }, "Up",    function () awful.client.swap.byidx( -1)     end),
    awful.key({ modkey, "Control", "Shift" }, "Down",  function () awful.client.swap.byidx(  1)     end),

    -- #### Window Dimensions
    awful.key({ modkey, "Mod1"    }, "Left", function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Mod1"    }, "Right",  function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey, "Mod1"    }, "Up",    function () awful.client.incwfact( 0.05) end),
    awful.key({ modkey, "Mod1"    }, "Down",  function () awful.client.incwfact(-0.05) end),

    -- #### Window Counts
    awful.key({ modkey, "Mod1", "Shift" }, "Up",    function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Mod1", "Shift" }, "Down",  function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Mod1", "Shift" }, "Left",  function () awful.tag.incncol(-1)         end),
    awful.key({ modkey, "Mod1", "Shift" }, "Right", function () awful.tag.incncol( 1)         end),

    -- #### Prompts
    -- TODO: I'll probably want to replace the default prompt `run()` with a
    -- port of my `address_bar.py` to Lua.
    awful.key({ modkey }, "r",     function () mypromptbox[mouse.screen]:run() end),
    awful.key({ modkey }, "x",
              function () awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),

    -- #### Drop-down
    -- **TODO:** Figure out how to make this hide on loss of focus
    -- **TODO:** Figure out how to reattach on reboot via the DropTerm WM_CLASS.
    awful.key({ modkey }, "F12", function () scratch.drop("xterm -class DropTerm", "top", "center", 1, 0.80, true) end),

    -- #### More de facto standard floating WM keybinds for awesome
    -- **TODO:** Keybinds for `W-d` and `C-A-d` to toggle show desktop
    awful.key({ "Mod1"            }, "F2",     function () mypromptbox[mouse.screen]:run() end),
    awful.key({ "Control"         }, "Escape", function () mymainmenu:show({keygrabber=true}) end),
    awful.key({ "Control", "Mod1" }, "Escape", function () awful.util.spawn("xkill") end),
    awful.key({ "Control", "Mod1" }, "Left",   awful.tag.viewprev),
    awful.key({ "Control", "Mod1" }, "Right",  awful.tag.viewnext),

    awful.key({ "Mod1"            }, "Tab",
        function ()
        -- If you want to always position the menu on the same place set coordinates
            awful.client.focus.byidx(1)
            if client.focus then client.focus:raise() end

            -- TODO: Figure out how to make this behave completely like in other WMs
            --awful.menu.menu_keys.down = { "Down", "Tab" }
            --local cmenu = awful.menu.clients({width=245}, { keygrabber=true, coords={x=525, y=330} })
        end),
    awful.key({ "Mod1", "Shift"   }, "Tab",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end)
)

-- ### Per-window key bindings
clientkeys = awful.util.table.join(
    awful.key({ modkey, "Control", "Shift"   }, "Left",  function () awful.client.movetoscreen(c, (c.screen-1) % screen.count()) end),
    awful.key({ modkey, "Control", "Shift" },   "Right", function () awful.client.movetoscreen(c, (c.screen+1) % screen.count()) end),

    -- **TODO:** Tidy up and normalize these
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey, "Control" }, "space",  function (c) awful.client.floating.toggle(c)  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "s",      function (c) c.sticky = not c.sticky          end),
    awful.key({ modkey,           }, "t",      function (c) helpful.toggle_titlebar(c)       end),
    -- **TODO:** Add `c.below` toggle (and replace `c.ontop` with `c.above`?)
    awful.key({ modkey, "Shift"   }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
    -- #### More de facto standard floating WM keybinds for awesome
    -- **TODO:** Keybinds for `S-A-Left/Right` for "move window to prev/next tag"
)

-- #### Bind all key numbers to tags.

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    -- **F:** Split this out so it can be reused
    switch_func = function ()
        local screen = mouse.screen
        if tags[screen][i] then
            awful.tag.viewonly(tags[screen][i])
        end
    end

    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9, switch_func),
        -- **F:** Also bind to F1 through F9 to match common keybinds from other WMs
        awful.key({ "Mod1", "Control" }, "F" .. i),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

-- ### Per-window mouse bindings
clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Actually bind global keys
root.keys(globalkeys)

-- ### Rules
awful.rules.rules = {
    -- All clients will match this rule (On-create defaults).
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     maximized_vertical   = false,
                     maximized_horizontal = false,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },

    -- Windows which need a little help to be exempt from tiling
    -- **TODO:** Figure out how to override Audacious's repositioning.
    { rule = { class = "Audacious", type = "normal" },
        properties = helpful.properties_float_right(screen[1], 475)
    },
    { rule = { class = "Chromium-browser" }, properties = { border_width = 0 } },
    { rule = { class = "Conky" },    properties = { floating = true, sticky = true } },
    { rule = { class = "DropTerm" }, properties = { border_width = 0 } },
    { rule = { class = "gimp" },     properties = { floating = true } },
    { rule = { class = "MPlayer" },  properties = { floating = true } },
    { rule = { class = "pinentry" }, properties = { floating = true } },
    -- **TODO:** Look into what awesome users tend to do for desktop stickies
    { rule = { class = "xpad" },     properties = { floating = true, sticky = true } },
    { rule = { class = "yakuake" },  properties = { floating = true } },

    -- **Example:** Set Firefox to always map on tags number 2 of screen 1.
    --     { rule = { class = "Firefox" },
    --       properties = { tag = tags[1][2] } },
}

-- ### Signals

-- #### Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add titlebar
    if c.border_width > 0 then
        awful.titlebar.add(c, { modkey = modkey })
    end

    -- Ensure all newly created windows have at least one tag
    if #c:tags() == 0 then c:tags({tags[c.screen][1]}) end

    -- TODO: What does the startup argument mean again?
    if not startup then
        -- Set the window as a slave,
        -- i.e. put it at the end of others instead of setting it master.
        --     awful.client.setslave(c)

        -- Place windows in a smart way only if they do not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
            -- **TODO:** [Centered](http://awesome.naquadah.org/doc/api/modules/awful.placement.html#centered)
            -- on the monitor [with the mouse](http://awesome.naquadah.org/doc/api/modules/awful.placement.html#under_mouse)
        end
    end
end)

-- #### Hide/show the titlebar when entering/leaving fullscreened
-- **TODO:** Is there an easy way to save the titlebar state and restore it?
client.add_signal("fullscreen", function ()
    -- Remove the titlebar if fullscreen
    if c.fullscreen then
        awful.titlebar.remove(c)
    else
        awful.titlebar.add(c, { modkey = modkey })
    end
end)

-- #### Hook up the titlebar colorization for focus/unfocus
client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- ### [Calculator Prompt](https://awesome.naquadah.org/wiki/Naughty#rc.lua_.2F_calculator_prompt_with_naughty_output)
--     val = nil
--     keybinding({ modkey}, "c", function ()
--         awful.prompt.run({  text = val and tostring(val),
--                 selectall = true,
--                 fg_cursor = "black",bg_cursor="orange",
--                 prompt = "<span color='#00A5AB'>Calc:</span> " }, mypromptbox,
--                 function(expr)
--                   val = awful.util.eval(expr)
--                   naughty.notify({ text = expr .. ' = <span color="white">' .. val .. "</span>",
--                                    timeout = 0,
--                                    run = function() io.popen("echo ".. val .. " | xsel -i"):close() end, })
--                 end,
--                 nil, awful.util.getdir("cache") .. "/calc")
--     end):add()
