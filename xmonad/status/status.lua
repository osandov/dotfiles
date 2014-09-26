do
    local red = "\\#dc322f"
    local yellow = "\\#b58900"
    local green = "\\#859900"
    local orange = "\\#cb4b16"

    local home = os.getenv("HOME")

    function icon_file(icon_name)
        return string.format("^i(%s/.xmonad/icons/%s.xbm)", home, icon_name)
    end

    function color_percent(val, low, high)
        local lo = tonumber(low)
        local hi = tonumber(high)
        local color = ""

        if lo > hi or val == nil then
            return ""
        end

        if val <= lo then
            color = ""
        elseif val <= hi then
            color = green
        else
            color = red
        end

        return string.format("^fg(%s)%3d%%^fg()", color, val)
    end

    function conky_dropbox_status()
        local handle = io.popen("dropbox status", "r")
        local dropbox_status = handle:read()
        handle:close()

        if dropbox_status == "Dropbox isn't running!" then
            return ""
        else
            local idle = dropbox_status == "Up to date" or dropbox_status == "Idle"
            local icon = ""

            if os.time() % 2 == 0 or idle then
                icon = icon_file("dropbox_idle")
            else
                icon = icon_file("dropbox_busy")
            end

            local format = "^ca(1, %s/.xmonad/dropdowns/dropbox_dropdown)%s^ca() | "
            return string.format(format, home, icon)
        end
    end

    function conky_wifi_status(nic)
        local ssid = conky_parse(string.format("${wireless_essid %s}", nic))
        local qual = tonumber(conky_parse(string.format("${wireless_link_qual_perc %s}", nic)))
        local icon = ""

        if ssid == "off/any" or qual == nil then
            icon = icon_file("wifi0")
        elseif qual >= 66 then
            icon = icon_file("wifi3")
        elseif qual >= 33 then
            icon = icon_file("wifi2")
        else
            icon = icon_file("wifi1")
        end

        local format = "^ca(1, %s/.xmonad/dropdowns/wifi_dropdown %s)" ..
                       "^ca(3, xterm -e 'sudo wifi-menu')%s^ca()^ca() | "
        return string.format(format, home, nic, icon)

    end

    function conky_cpu_usage()
        local val = tonumber(conky_parse("$cpu"))
        return icon_file("cpu") .. color_percent(val, 15, 50) .. " | "
    end

    function conky_mem_usage()
        local val = tonumber(conky_parse("$memperc"))
        return icon_file("mem") .. color_percent(val, 75, 75) .. " | "
    end

    function conky_battery(acad, bat)
        local ac = conky_parse(string.format("${acpiacadapter %s}", acad))
        local charge = tonumber(conky_parse(string.format("${battery_percent %s}", bat)))
        local icon = ""
        local color = ""

        if charge == nil then
            return ""
        end

        if charge >= 55 then
            icon = icon_file("bat_full")
            color = green
        elseif charge > 20 then
            icon = icon_file("bat_low")
            color = yellow
        else
            icon = icon_file("bat_empty")
            color = red
        end

        if ac == "on-line" then
            icon = icon_file("ac")
        end

        return string.format("%s ^fg(%s)%3d%%^fg() | ", icon, color, charge)
    end

    function conky_volume()
        local handle = io.popen(home .. "/.dotfiles/bin/volume_get", "r")
        local volume_str = handle:read()
        local icon = ""
        handle:close()

        if volume_str == "MUTE" then
            icon = string.format("%s ^fg(%s)MUTE^fg()", icon_file("spkr_mute"), red)
        else
            local volume = tonumber(volume_str)
            icon = string.format("%s %3d%%", icon_file("spkr_play"), volume)
        end

        return string.format("^ca(1, xterm -e alsamixer)%s^ca() | ", icon)
    end

    function conky_clock()
        local format = "%s ^fg(%s)${time %%a %%b %%_d %%Y %%I:%%M:%%S %%p}"
        return string.format(format, icon_file("clock"), orange)
    end
end
