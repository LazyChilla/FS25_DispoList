DL_TitelHud_DrawHud = {}

function DL_TitelHud_DrawHud.setHud(args)
    if args == nil or type(args) ~= "table" or args.typPos == nil or args.inArea == nil then return end
    local hud = g_currentMission.hlHudSystem.hud[args.typPos]
    if hud == nil then return end
    local inArea    = args.inArea
    local hudNumber = args.typPos

    if hud.overlays.modIcons["DispoList"] == nil or hud.overlays.modIcons["DispoList"]["hud"] == nil then return end
    if not g_currentMission.hlHudSystem.isSetting.hud then hud.isSetting = false end

    local box     = g_currentMission.hlHudSystem.hlBox:getData("DL_Display_Box")
    local showBox = box ~= nil and box.show

    local x, y, w, h = hud:getScreen()
    local distance = hud:getSize({"distance"})
    local difW = distance.iconWidth
    local difH = distance.iconHeight

    local overlayGroup  = hud.overlays.modIcons["DispoList"]["hud"]
    local overlayByName = hud.overlays.modIcons.byName["DispoList"]["hud"]

    if hud.ownTable.iconWidth == nil or hud.needsUpdate then
        hud.ownTable.iconWidth, hud.ownTable.iconHeight = hud:getOptiWidthHeight({typ = "hud", height = h - (difH * 2), width = w - difW})
        hud.needsUpdate = false
    end
    local iconWidth  = hud.ownTable.iconWidth
    local iconHeight = hud.ownTable.iconHeight

    local nextPosX = x + difW
    local nextPosY = y + (h / 2) - (iconHeight / 2) - difH

    -- Ein einfarbiges (weisses) Icon, das zur Laufzeit exakt in den HL-Farben
    -- der Nachbar-Icons eingefaerbt wird: grau (notActive) im Normalzustand,
    -- gruen (active) sobald Maus drueber ODER Box offen. Faerbt sich dadurch
    -- automatisch korrekt mit, falls der HL-Farbstil (ls22/ls25) gewechselt
    -- wird -- keine gebackenen Farbvarianten mehr im DDS noetig.
    local overlay = overlayGroup[overlayByName["dlTitel"]]

    if overlay ~= nil then
        -- Exakt HappyLoosers 3-Zustands-Faerbung (verifiziert aus FS25_VehicleManager,
        -- VehicleManager_Display_DrawHud): Ruhe = weiss (er nutzt color.txt, das im
        -- Farbstil nicht existiert -> getColor faellt sauber auf Weiss zurueck),
        -- Box offen (Maus weg) = dunkles ls25-Gruen (color.isShow), Maus drueber =
        -- helles ls25active-Gruen (color.inArea). Aus hud.overlays.color gelesen wie
        -- bei ihm -- faerbt sich dadurch bei Stil-Wechsel (ls22/ls25) automatisch mit.
        local hlCol = (hud.overlays ~= nil and hud.overlays.color)
                   or (g_currentMission.hlHudSystem ~= nil and g_currentMission.hlHudSystem.overlays ~= nil and g_currentMission.hlHudSystem.overlays.color)
                   or nil
        local col
        if inArea then
            col = (hlCol ~= nil) and g_currentMission.hlUtils.getColor(hlCol.inArea, true) or {118/255, 185/255, 0, 1}
        elseif showBox then
            col = (hlCol ~= nil) and g_currentMission.hlUtils.getColor(hlCol.isShow, true) or {0.2384, 0.4621, 0.0015, 1}
        else
            col = (hlCol ~= nil) and g_currentMission.hlUtils.getColor(hlCol.txt, true) or {1, 1, 1, 1}
        end

        g_currentMission.hlUtils.setOverlay(overlay, nextPosX, nextPosY, iconWidth, iconHeight)
        g_currentMission.hlUtils.setBackgroundColor(overlay, col)
        overlay:render()
        if hud.isSetting and inArea and g_currentMission.hlHudSystem.infoDisplay.on then
            g_currentMission.hlHudSystem:addTextDisplay({txt = tostring(hud.info), maxLine = 0})
        end
        if not g_currentMission.hlUtils:disableInArea() and not g_currentMission.hlHudSystem.isSetting.hud and inArea then
            hud:setClickArea({overlay.x, overlay.x + overlay.width, overlay.y, overlay.y + overlay.height, whatClick = "DL_TitelHud_DrawHud", typPos = hudNumber, whereClick = "dlTitelIcon_", ownTable = {}})
        end
    end
end
