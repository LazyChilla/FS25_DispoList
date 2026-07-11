DL_Display_XmlBox = {}

function DL_Display_XmlBox:loadBox(name, onSave)
    -- ── Hauptbox ──────────────────────────────────────────────────────────────
    if name == "DL_Display_Box" then
        local box = g_currentMission.hlHudSystem.hlBox.generate(
            {
                name             = name,
                width            = 420,
                height           = 200,
                info             = "DispoList\nLagerbestand + Bestpreise",
                autoZoomOutIn    = "text",
                hiddenMod        = "FS25_DispoList",
                show             = false,
                loadDefaultIcons = true,   -- loadIcons aus icons.xml laden (textUp, textDown, lineHorizontalUpDown, search ...)
            }
        )
        if box == nil then print("#ERROR DispoList: box generate() returned nil"); return end
        box.onDraw = DL_Display_DrawBox.setBox
        box.autoClose = false  -- WICHTIG: ohne Cursor nicht automatisch schliessen
        box.screen.canBounds.on = true
        box.screen.canBounds.setInfo = false  -- keine Scroll-Pfeile, Scrollen via Mausrad
        box.resetBoundsByDragDrop = false
        -- HL-System Titelleisten-Icons aktivieren
        box.overlays.settingIcons.up.visible   = true   -- Schriftgröße +
        box.overlays.settingIcons.down.visible = true   -- Schriftgröße -
        box.viewExtraLine = true  -- Zeilenabstand-Icon in Extra-Zeile
        box.isHelp = true

        -- Hauptbox schließen → Filter-Box + Settings-Box mitschließen
        box.onClick = function(args)
            if args == nil then return end
            if args.clickAreaTable ~= nil and
               args.clickAreaTable.areaClick == "closeIcon_" then
                -- Settings GuiBox schliessen
                if g_currentMission.hlHudSystem ~= nil and
                   g_currentMission.hlHudSystem.guiBox ~= nil then
                    for _, gb in ipairs(g_currentMission.hlHudSystem.guiBox) do
                        if gb ~= nil and gb.show then gb.show = false end
                    end
                end
                if DL_ColSettings ~= nil then DL_ColSettings.guiBox = nil end
                local fbox = g_currentMission.hlHudSystem.hlBox:getData("DL_Filter_Box")
                if fbox ~= nil and fbox.show then
                    fbox.show = false
                    DispoList.filterMenuOpen = false
                    -- Pause aufheben falls aktiv
                    if DispoList.filterPauseEnabled then
                        if DispoList.previousTimeScale ~= nil then
                            g_currentMission.timeScale = DispoList.previousTimeScale
                        end
                        if g_currentMission.missionInfo ~= nil and DispoList.previousMissionTimeScale ~= nil then
                            g_currentMission.missionInfo.timeScale = DispoList.previousMissionTimeScale
                        end
                        if g_currentMission.paused ~= nil then
                            g_currentMission.paused = false
                        end
                        DispoList.previousTimeScale = nil
                        DispoList.previousMissionTimeScale = nil
                    end
                end
            end
        end

        if onSave == nil or box.show then
            DispoList:refreshDispoTable()
        end

    -- ── Filter-Box ────────────────────────────────────────────────────────────
    elseif name == "DL_Filter_Box" then
        local fbox = g_currentMission.hlHudSystem.hlBox.generate(
            {
                name             = name,
                width            = 350,
                height           = 300,
                info             = "DispoList\nFilter-Einstellungen",
                autoZoomOutIn    = "text",
                hiddenMod        = "FS25_DispoList",
                show             = false,
                loadDefaultIcons = true,
            }
        )
        -- Standardzeilenabstand setzen
        fbox.screen.size.distance.textLine = fbox.screen.pixelH * 1.5
        fbox.onDraw = DL_FilterMenu_Draw.setBox
        fbox.screen.canBounds.on = true
        fbox.screen.bounds[1] = 1
        fbox.screen.bounds[4] = 1
        fbox.resetBoundsByDragDrop = false
        -- WICHTIG: ohne explizites false hier kann eine global gespeicherte
        -- autoClose="true" aus einer frueheren Session (modSettings/HL/HudSystem/
        -- box/DL_Filter_Box.xml) gewinnen -> Box schliesst sich ohne aktiven
        -- Mauszeiger sofort wieder selbst. Siehe DL_Display_Box weiter oben.
        fbox.autoClose = false

        -- Filter-Box schließen → Pause aufheben
        fbox.onClick = function(args)
            if args == nil then return end
            if args.clickAreaTable ~= nil and
               args.clickAreaTable.areaClick == "closeIcon_" then
                DispoList.filterMenuOpen = false
                if DispoList.filterPauseEnabled then
                    if DispoList.previousTimeScale ~= nil then
                        g_currentMission.timeScale = DispoList.previousTimeScale
                    end
                    if g_currentMission.missionInfo ~= nil and DispoList.previousMissionTimeScale ~= nil then
                        g_currentMission.missionInfo.timeScale = DispoList.previousMissionTimeScale
                    end
                    if g_currentMission.paused ~= nil then
                        g_currentMission.paused = false
                    end
                    DispoList.previousTimeScale = nil
                    DispoList.previousMissionTimeScale = nil
                end
            end
        end
    end
end
