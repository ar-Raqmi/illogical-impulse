-- ######## Hyprbars Plugin Configuration ########

hl.config({
    plugin = {
        hyprbars = {
            enabled = true,
            bar_text_font = "Google Sans Flex Medium, Rubik, Geist, AR One Sans, Reddit Sans, Inter, Roboto, Ubuntu, Noto Sans, sans-serif",
            bar_height = 24,
            bar_padding = 10,
            bar_button_padding = 6,
            bar_precedence_over_border = true,
            bar_part_of_window = true,
            bar_title_enabled = false,
            on_double_click = "$HOME/.config/hypr/hyprland/scripts/toggle_float.sh",
        },
    },
})

-- ######## macOS Style Buttons ########

-- Close Button
hl.plugin.hyprbars.add_button({
    bg_color = "rgb(ff5f56)",
    fg_color = "rgb(ffffff)",
    size = 14,
    icon = "",
    action = "hyprctl dispatch 'hl.dsp.window.close()'",
})

-- Minimize/Special Workspace Button
hl.plugin.hyprbars.add_button({
    bg_color = "rgb(ffbd2e)",
    fg_color = "rgb(000000)",
    size = 14,
    icon = "",
    action = "$HOME/.config/hypr/hyprland/scripts/minimize.sh",
})

-- Fullscreen Button
hl.plugin.hyprbars.add_button({
    bg_color = "rgb(27c93f)",
    fg_color = "rgb(000000)",
    size = 14,
    icon = "",
    action = "hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"toggle\" })'",
})

-- ######## Window Rules (No Bar) ########

local function no_bar(match_table)
hl.window_rule({
    match = match_table,
    ["hyprbars:no_bar"] = true
})
end

no_bar({ initial_title = "^(WPS)(.*)$" })
no_bar({ initial_class = "^(et)$" })
no_bar({ initial_title = "^(ONLYOFFICE)(.*)$" })
no_bar({ title = "^(?i)(.*)(updater)(.*)$" })
no_bar({ title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" })
no_bar({ class = "^(discord)$" })
no_bar({ class = "^(code)$" })
no_bar({ class = "^(steam)$" })
no_bar({ title = "^(ar-Raqmi Dashboard)(.*)$" })
no_bar({ class = "^(.*)(quickshell)(.*)$" })
no_bar({ class = "^(net.lutris)(.*)$" })
no_bar({ tag = "nobar" })

hl.config({
    plugin = {
        csd_minimize = {
            command = "$HOME/.config/hypr/hyprland/scripts/minimize.sh"
        }
    }
})

