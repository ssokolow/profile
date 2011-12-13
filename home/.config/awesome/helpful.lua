local awful = require("awful")

module("helpful")

function toggle_titlebar (c)
    if c.titlebar then
        awful.titlebar.remove(c)
    else
        awful.titlebar.add(c, { modkey = modkey })
    end
end

-- **TODO:** Generalize/tidy this
function properties_float_right(screen, width)
    area = screen.workarea

    return {
        floating = true,
        x = area.x - width,
        y = area.y,
        width = width,
        height = area.height
    }
end



