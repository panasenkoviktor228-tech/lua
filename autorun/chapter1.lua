StorySteps = {
    [1] = { 
        pos = Vector(-3090, -6004, -543), 
        waitPos = Vector(11281, 1918, -329), 
        msg = "Покатайтесь на лифте", 
        name = "ЛИФТ" 
    },
    [2] = { 
        pos = Vector(9787, 2075, -329), 
        waitPos = Vector(483, -4156, 1802), 
        msg = "Осмотритесь", 
        name = "ЭТАЖ",
        hideMarker = true,
        onStart = {
            server = {
                "sv_story_night 1",
                "gmpa_enabled 1",
                "gmpa_max_active_ghosts 2",
                "gmpa_ghost_lifetime 3",
                "gmpa_delay_event_min 60",
                "gmpa_delay_event_max 120",
                "gmpa_ceiling_bleeding 1",
                "gmpa_shadow_figures 1",
                "gmpa_ghost_orbs 1",
                "gmpa_visible_ghosts 1",
                "gmpa_cockroach_swarms 1",
                "gmpa_prop_flinging 1",
                "gmpa_flickering_lights 1",
                "gmpa_flashlight_effect 0",
                "gmpa_flashlight_flicker_chance 75"
            },
            client = { "story_night 1" }
        }
    },
    [3] = { 
        pos = Vector(1576, -567, 184), 
        msg = "Бегите домой!", 
        name = "КВАРТИРА" 
    }
}
print("[LOG] Таблица Главы 1 загружена.")
