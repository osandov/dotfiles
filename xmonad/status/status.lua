do
    local red = "\\#dc322f"
    local yellow = "\\#b58900"
    local green = "\\#859900"

    function conky_color_percent(arg, low, high)
        local val = tonumber(conky_parse(arg))
        local lo = tonumber(low)
        local hi = tonumber(high)
        local color = ""

        if lo <= hi then
            if val <= lo then
                color = ""
            elseif val <= hi then
                color = green
            else
                color = red
            end
        end

        return string.format("^fg(%s)%3d%%^fg()", color, val)
    end

    function conky_battery(acad, bat)
        local ac = conky_parse(string.format("${acpiacadapter %s}", acad))
        local charge = tonumber(conky_parse(string.format("${battery_percent %s}", bat)))
        local icon = ""
        local color = ""

        if charge >= 55 then
            icon = "^i(.xmonad/icons/bat_full.xbm)"
            color = green
        elseif charge > 20 then
            icon = "^i(.xmonad/icons/bat_low.xbm)"
            color = yellow
        else
            icon = "^i(.xmonad/icons/bat_empty.xbm)"
            color = red
        end

        if ac == "on-line" then
            icon = "^i(.xmonad/icons/ac.xbm)"
        end

        return string.format("%s ^fg(%s)%3d%%^fg()", icon, color, charge)
    end
end
