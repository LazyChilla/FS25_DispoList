--
-- FS25 DispoList - Filter-Box Draw v5
-- Modus 1: Bereich-Definition — gemeinsamer FillType-Pool, Zuordnung zu Bereichen
-- Modus 2: Station-Filter — Bereiche+FillTypes pro Station an/aus
--

DL_FilterMenu_Draw = {}

-- Gibt alle FillTypes zurück die noch KEINEM Bereich zugeordnet sind
-- plus die des aktuell gewählten Bereichs (damit man sie sieht)
function DL_FilterMenu_Draw.getPoolForBereich(selBereich)
    -- Alle zugeordneten FillTypes sammeln
    local zugeordnet = {}
    if DL_Filter.bereichZuordnung ~= nil then
        for ber, fts in pairs(DL_Filter.bereichZuordnung) do
            if ber ~= selBereich then
                for ftName, _ in pairs(fts) do
                    zugeordnet[ftName] = true
                end
            end
        end
    end

    -- Alle FillTypes der Karte
    local allFT = DL_FilterMenu_Draw.getAllMapFillTypes()
    local result = {}
    for _, item in ipairs(allFT) do
        local inSelBereich = DL_Filter.bereichZuordnung ~= nil
            and DL_Filter.bereichZuordnung[selBereich] ~= nil
            and DL_Filter.bereichZuordnung[selBereich][item.ftName] == true
        if selBereich == "Sonstiges" then
            if not zugeordnet[item.ftName] then
                table.insert(result, {ftName=item.ftName, title=item.title, zugeordnet=false})
            end
        elseif not zugeordnet[item.ftName] or inSelBereich then
            table.insert(result, {ftName=item.ftName, title=item.title, zugeordnet=inSelBereich})
        end
    end
    -- Zugeordnete zuerst, dann alphabetisch
    table.sort(result, function(a, b)
        if a.zugeordnet ~= b.zugeordnet then
            return a.zugeordnet
        end
        return string.lower(a.title) < string.lower(b.title)
    end)
    return result
end

-- Cache für teure Berechnungen
DL_FilterMenu_Draw._allFTCache    = nil
DL_FilterMenu_Draw._stationCache  = nil
DL_FilterMenu_Draw._cacheTimer    = 0

-- ── Bereichsliste: einmal sortieren, dann cachen (nicht pro Frame) ───────────
-- Die Bereiche ändern sich nur bei Anlegen/Umbenennen/Löschen/Preset — nicht pro
-- Frame. Darum die alphabetisch sortierte Namensliste cachen und nur neu bauen,
-- wenn sich die Bereichszahl ändert ODER invalidateBereicheCache() gerufen wurde
-- (Letzteres deckt das Umbenennen ab, das die Anzahl nicht ändert).
DL_FilterMenu_Draw._bereicheCache      = nil
DL_FilterMenu_Draw._bereicheCacheCount = -1

function DL_FilterMenu_Draw.invalidateBereicheCache()
    DL_FilterMenu_Draw._bereicheCache      = nil
    DL_FilterMenu_Draw._bereicheCacheCount = -1
end

-- Liefert die NICHT-Spezial-Bereiche als {name, order}, alphabetisch sortiert.
-- Spezialbereiche (Unverkaeuflich/Sonstiges) hängt jeder Modus selbst an, weil
-- er sie unterschiedlich behandelt. Rückgabe ist die gecachte Liste (read-only).
function DL_FilterMenu_Draw.getSortedBereichNames()
    local count = 0
    if DispoList.BEREICHE ~= nil then
        for _ in pairs(DispoList.BEREICHE) do count = count + 1 end
    end
    if DL_FilterMenu_Draw._bereicheCache ~= nil
       and DL_FilterMenu_Draw._bereicheCacheCount == count then
        return DL_FilterMenu_Draw._bereicheCache
    end
    local list = {}
    local specialNames = {["Unverkaeuflich"] = true, ["Sonstiges"] = true}
    for name, data in pairs(DispoList.BEREICHE or {}) do
        if not specialNames[name] then
            list[#list + 1] = {name = name, order = data.order}
        end
    end
    table.sort(list, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
    DL_FilterMenu_Draw._bereicheCache      = list
    DL_FilterMenu_Draw._bereicheCacheCount = count
    return list
end

function DL_FilterMenu_Draw.setBox(args)
    if args == nil or type(args) ~= "table" or args.typPos == nil then return end
    local box = g_currentMission.hlHudSystem.box[args.typPos]
    if box == nil then return end

    local x, y, w, h = box:getScreen()
    local distance = box:getSize({"distance"})
    local difW     = distance.textWidth
    local difH     = distance.textHeight
    local size     = box.screen.size.zoomOutIn.text[1] or getCorrectTextSize(0.013)
    if box.needsUpdate or box.ownTable.lineHeight == nil then
        box.ownTable.lineHeight = getTextHeight(size, utf8Substr("Äg", 0)) + distance.textLine
    end
    local lineH    = box.ownTable.lineHeight
    local bgLine   = box.overlays.bgLine
    local inArea   = args.inArea

    -- Hintergrund-Alpha vom Haupt-HUD übernehmen (4 Stufen, sync mit DL_Display_DrawBox)
    local bgAlphas = {0.88, 0.45, 0.12, 0.97}
    local bgAlpha  = bgAlphas[DispoList._bgAlphaIdx or 1]
    if box.overlays.bg ~= nil then
        g_currentMission.hlUtils.setBackgroundColor(box.overlays.bg, {0, 0, 0, bgAlpha})
    end

    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(unpack(DL_Colors.white))

    -- ── Icon-Zeile (Zeile 1) + Info-Zeile (Zeile 2) ─────────────────────────
    -- Wie im Haupt-HUD: alle Icons permanent sichtbar, kein Zahnrad-Modus
    local iconW, iconH = box:getOptiWidthHeight(
        {typ="icon", height=math.max(size * 0.8, size * 1.4 - difH), width=w - difW * 2})
    iconW = iconW or (size * 1.0)
    iconH = iconH or (size * 1.0)
    local iconLineY = y + h - lineH * 0.6    -- Zeile 1: Icons (etwas tiefer)
    local iconPosY  = iconLineY - iconH * 0.5
    local infoLineY = iconLineY - lineH * 1.6  -- Zeile 2: Info/Titel (mehr Abstand)
    local infoPosY  = infoLineY - iconH * 0.5

    -- Layout-Buendel fuer den gemeinsamen Icon-Renderer (DispoList.drawHoverIcon)
    local iconGeo = {x=x, w=w, size=size, difW=difW, lineH=lineH,
                     iconW=iconW, iconH=iconH, iconPosY=iconPosY, iconLineY=iconLineY, inArea=inArea}

    -- Hilfsfunktion PNG-Icon laden -> gemeinsamer Renderer (drawHoverIcon)
    local function drawFIcon(key, filename, posX, activeCol, inactiveCol, whereClick, tooltip)
        if box.overlays[key] == nil then
            local path = DispoList.modDir and (DispoList.modDir .. "images/" .. filename) or nil
            if path == nil then return posX end
            box.overlays[key] = Overlay.new(path, 0, 0, iconW, iconH)
        end
        local o = box.overlays[key]
        if o == nil then return posX end
        return DispoList.drawHoverIcon(box, args, iconGeo, o, posX, activeCol, inactiveCol, whereClick, tooltip)
    end

    -- onSettingClick (gecacht wie Haupt-HUD)
    if box.onSettingClick == nil then
        box.ownTable.zoomActive = box.ownTable.zoomActive or false
        box.onSettingClick = function(a)
            if a == nil then return end
            if a.clickAreaTable == nil then return end
            local wc  = a.clickAreaTable.whereClick
            local btn = a.button
            -- dlf_mode_ feuert bei isDown=false (mouseUp), alle anderen bei isDown=true
            if wc ~= "dlf_mode_" and not a.isDown then return end

            -- "Klick woanders bestaetigt die Suche": ein echter Klick auf IRGENDEIN
            -- anderes Bedienelement (nicht die Lupe, nicht das Suchfeld selbst)
            -- loest den Tipp-Fokus -> Fahren wieder frei. Laeuft nur ueber echte,
            -- registrierte Klick-Areas (kein rohes mouseEvent-Rauschen).
            if DispoList.searchFocused and a.isDown
               and wc ~= "dlf_search_" and wc ~= "dlf_searchfield_" then
                DispoList.setSearchFocus(false)
            end
            local now = g_currentMission.time or 0
            local function cooldown(ms)
                if DispoList.dlClickCooldown ~= nil and now - DispoList.dlClickCooldown < (ms or 400) then return true end
                DispoList.dlClickCooldown = now
                return false
            end
            if wc == "dlf_zoomToggle_" then
                local zoom = box.screen.size.zoomOutIn.text
                if zoom ~= nil then
                    local step = zoom[2] or 0.1
                    local cur  = zoom[1] or 0.012
                    local minS = zoom[4] or 0.006
                    local maxS = zoom[3] or 0.030
                    if btn == Input.MOUSE_BUTTON_LEFT then
                        box.screen.size.zoomOutIn.text[1] = math.min(cur + step, maxS)
                        box.needsUpdate = true
                    elseif btn == Input.MOUSE_BUTTON_RIGHT then
                        box.screen.size.zoomOutIn.text[1] = math.max(cur - step, minS)
                        box.needsUpdate = true
                    end
                end
            elseif wc == "dlf_lineDistance_" then
                local maxD = box.screen.pixelH * 8
                local cur  = box.screen.size.distance.textLine
                local step = box.screen.pixelH / 2
                if btn == Input.MOUSE_BUTTON_LEFT then
                    if cur + step <= maxD then box.screen.size.distance.textLine = cur + step; box.ownTable.lineHeight = nil; box.needsUpdate = true end
                elseif btn == Input.MOUSE_BUTTON_RIGHT then
                    if cur - step >= 0 then box.screen.size.distance.textLine = cur - step; box.ownTable.lineHeight = nil; box.needsUpdate = true end
                end
            elseif wc == "dlf_search_" then
                if btn == Input.MOUSE_BUTTON_LEFT then
                    if cooldown(400) then return end
                    if DispoList.filterSearchActive then
                        DispoList.resetSearch()             -- schliessen: Fokus+Kontext frei, Query leer
                    else
                        -- Nur EINE Lupe aktiv: Haupt-Lupe zu, damit Getippe eindeutig hier landet
                        if DispoList.resetMainSearch ~= nil then DispoList.resetMainSearch() end
                        DispoList.filterSearchActive = true
                        DispoList.filterSearchCursorTimer = 0
                        DispoList.setSearchFocus(true)      -- oeffnen + Fokus (tippen)
                    end
                end
            elseif wc == "dlf_searchfield_" then
                if btn == Input.MOUSE_BUTTON_LEFT then
                    if cooldown(300) then return end
                    DispoList.filterSearchCursorTimer = 0
                    DispoList.setSearchFocus(true)          -- wieder ins Feld: weiter tippen
                end
            elseif wc == "dlf_preset_reset_" then
                if btn == Input.MOUSE_BUTTON_LEFT then
                    if cooldown(400) then return end
                    if DL_ColSettings ~= nil then
                        DL_ColSettings:toggle_guibox()
                    end
                end
            end
        end
    end  -- if box.onSettingClick == nil

    -- Hintergrund Zeile 1 (Icons)
    if bgLine ~= nil then
        g_currentMission.hlUtils.setOverlay(bgLine, x, iconLineY - lineH*0.55, w, lineH*0.9)
        g_currentMission.hlUtils.setBackgroundColor(bgLine, DL_Colors.panelBg)
        bgLine:render()
    end

    -- Versionsanzeige: rechts in der Icon-Zeile (innerhalb der Box)
    local verStr = utf8Substr("DispoList " .. (DispoList.VERSION or "?"), 0)
    setTextAlignment(RenderText.ALIGN_RIGHT)
    setTextColor(unpack(DL_Colors.grauDim))
    setTextBold(false)
    renderText(x + w - difW, iconLineY - size * 0.35, size * 0.7, verStr)
    setTextAlignment(RenderText.ALIGN_LEFT)

    -- ── Icons Zeile 1: links nach rechts ─────────────────────────────────────
    -- Icon-Overlays (box-Gruppe) -- muss VOR den Mode-Draws (nutzen fOvGroup/fOvByName) definiert sein
    local fOvGroup  = box.overlays.icons and box.overlays.icons["defaultIcons"] and box.overlays.icons["defaultIcons"]["box"] or nil
    local fOvByName = box.overlays.icons and box.overlays.icons.byName and box.overlays.icons.byName["defaultIcons"] and box.overlays.icons.byName["defaultIcons"]["box"] or {}
    if fOvGroup == nil then
        local mbox = g_currentMission.hlHudSystem.hlBox:getData("DL_Display_Box")
        if mbox ~= nil and mbox.overlays.icons then
            fOvGroup  = mbox.overlays.icons["defaultIcons"] and mbox.overlays.icons["defaultIcons"]["box"] or nil
            fOvByName = mbox.overlays.icons.byName and mbox.overlays.icons.byName["defaultIcons"] and mbox.overlays.icons.byName["defaultIcons"]["box"] or {}
        end
    end

    local ixPos = x + difW * 2
    local hasSel = DispoList.filterSelBereich ~= nil and DispoList.filterMode == "bereich"

    -- 1. Schrift (PNG)
    ixPos = drawFIcon("dlf_png_schrift", "icon_schrift.dds", ixPos,
        nil, DL_Colors.iconIdle,
        "dlf_zoomToggle_", "Schriftgroesse (L=groesser / R=kleiner)")

    -- 2. Zeilenabstand (PNG)
    ixPos = drawFIcon("dlf_png_zeilen", "icon_zeilenabstand.dds", ixPos,
        nil, DL_Colors.iconIdle,
        "dlf_lineDistance_", "Zeilenabstand (L=groesser / R=kleiner)")

    -- Trenner |
    setTextColor(unpack(DL_Colors.trenner))
    renderText(ixPos, iconPosY, size * 0.9, utf8Substr("|", 0))
    ixPos = ixPos + getTextWidth(size * 0.9, "|") + difW

    -- 3. Suche (PNG)
    local sActive = DispoList.filterSearchActive
    ixPos = drawFIcon("dlf_png_suche", "icon_suche.dds", ixPos,
        sActive and DL_Colors.iconActive or nil, DL_Colors.iconIdle,
        "dlf_search_", sActive and DL_t("tt_suche_schliessen") or DL_t("tt_suche_oeffnen"))

    -- Suchtext rechts neben Lupe (wenn aktiv) - gemeinsamer Renderer, siehe DispoList.renderSearchField
    if sActive then
        ixPos = DispoList.renderSearchField(box, args.typPos, ixPos, iconPosY, iconH, size, difW,
            bgLine, inArea, DispoList.filterSearchText, DispoList.filterSearchCursorVisible, "dlf_searchfield_")
    end

    -- Trenner |
    setTextColor(unpack(DL_Colors.trenner))
    renderText(ixPos, iconPosY, size * 0.9, utf8Substr("|", 0))
    ixPos = ixPos + getTextWidth(size * 0.9, "|") + difW

    -- Bereiche / Stationen Tabs in Icon-Zeile
    DispoList.filterModeTabs = {}
    local tabTooltips = {bereich=DL_t("tooltip_bereiche"), station=DL_t("tooltip_stationen"), freischalt=DL_t("tooltip_freischalt")}
    for _, tab in ipairs({{mode="bereich",label=DL_t("tab_bereiche")},{mode="station",label=DL_t("tab_stationen")},{mode="freischalt",label=DL_t("tab_freischalt")}}) do
        local isAct = (DispoList.filterMode == tab.mode)
        local tw = getTextWidth(size * 1.0, tab.label)
        if isAct then
            setTextColor(unpack(DL_Colors.gold))
            setTextBold(true)
        else
            setTextColor(unpack(DL_Colors.grauDim))
            setTextBold(false)
        end
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(ixPos, iconPosY, size * 1.0, utf8Substr(tab.label, 0))
        local mx = DispoList._mouseX or -1
        local my = DispoList._mouseY or -1
        if inArea and mx >= ixPos and mx <= ixPos + tw + difW
           and my >= iconPosY - iconH*0.3 and my <= iconPosY + iconH*0.7
           and g_currentMission.hlHudSystem.infoDisplay.on then
            local ttSize = size * 0.85
            local tooltip = tabTooltips[tab.mode] or ""
            local ttW = getTextWidth(ttSize, utf8Substr(tooltip .. "  ", 0)) * 1.1
            g_currentMission.hlHudSystem:addTextDisplay({txt=tooltip, maxLine=0, txtSize=ttSize,
                posX = x + (w - ttW) * 0.5,
                posY = iconLineY + lineH * 1.0})
        end
        table.insert(DispoList.filterModeTabs, {
            mode=tab.mode, label=tab.label,
            x1=ixPos, y1=iconPosY-iconH*0.3, x2=ixPos+tw+difW, y2=iconPosY+iconH*0.7
        })
        ixPos = ixPos + tw + difW * 3
        setTextBold(false)
    end
    setTextAlignment(RenderText.ALIGN_LEFT)

    -- Trenner + "Presets"-Textbutton (öffnet Einstellungs-HUD)
    setTextColor(unpack(DL_Colors.trenner))
    renderText(ixPos, iconPosY, size * 0.9, utf8Substr("|", 0))
    ixPos = ixPos + getTextWidth(size * 0.9, "|") + difW
    local presetLabel = utf8Substr("Presets", 0)
    local presetW = getTextWidth(size, presetLabel)
    local presetInArea = false
    do
        local mx = DispoList._mouseX or -1
        local my = DispoList._mouseY or -1
        presetInArea = inArea and mx >= ixPos and mx <= ixPos + presetW
                       and my >= iconPosY and my <= iconPosY + iconH
    end
    setTextColor(presetInArea and 0.95 or 0.65, presetInArea and 0.85 or 0.65, presetInArea and 0.0 or 0.65, 1)
    setTextBold(presetInArea)
    renderText(ixPos, iconPosY, size, presetLabel)
    setTextBold(false)
    if presetInArea and not g_currentMission.hlUtils:disableInArea() then
        if g_currentMission.hlHudSystem.infoDisplay.on then
            local ttSize = size * 0.85
            local tooltip = DL_t("tooltip_presets")
            local ttW = getTextWidth(ttSize, utf8Substr(tooltip .. "  ", 0)) * 1.1
            g_currentMission.hlHudSystem:addTextDisplay({txt=tooltip, maxLine=0, txtSize=ttSize,
                posX = x + (w - ttW) * 0.5,
                posY = iconLineY + lineH * 1.0})
        end
        box:setClickArea({ixPos, ixPos + presetW + difW, iconPosY - iconH * 0.3, iconPosY + iconH * 0.7,
            onClick = box.onSettingClick, whereClick = "dlf_preset_reset_", typPos = args.typPos})
    end
    ixPos = ixPos + presetW + difW * 2

    -- ── Zeile 2: Info-Zeile ───────────────────────────────────────────────────
    -- Hintergrund
    if bgLine ~= nil then
        g_currentMission.hlUtils.setOverlay(bgLine, x, infoLineY - lineH*0.55, w, lineH*0.9)
        g_currentMission.hlUtils.setBackgroundColor(bgLine, {0.04, 0.06, 0.04, 0.9})
        bgLine:render()
    end

    -- Titel links
    setTextColor(unpack(DL_Colors.gold))
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_LEFT)
    renderText(x + difW, infoLineY, size, utf8Substr(DL_t("filter_titel"), 0))
    setTextBold(false)

    -- Kontext-Info rechts (aktiver Bereich / Station / Suche)
    setTextAlignment(RenderText.ALIGN_LEFT)
    local infoX = x + difW + getTextWidth(size, DL_t("filter_titel")) + difW * 3
    if DispoList.filterSearchActive and DispoList.filterSearchText ~= "" then
        setTextColor(0.0, 1.0, 0.8, 1)
        renderText(infoX, infoLineY, size * 0.85, utf8Substr(DL_t("filter_suche_lbl") .. " " .. DispoList.filterSearchText, 0))
    elseif DispoList.filterMode == "bereich" and DispoList.filterSelBereich ~= nil then
        setTextColor(unpack(DL_Colors.gruenHead))
        renderText(infoX, infoLineY, size * 0.85, utf8Substr(DL_t("filter_bereich_lbl") .. " " .. DispoList.filterSelBereich, 0))
        -- Rückgängig-Option wenn vorhanden
        if DispoList.filterSnapshot ~= nil and DispoList.filterResetDone then
            local undoTxt = DL_t("btn_rueckgaengig")
            local undoX = x + w - getTextWidth(size * 0.85, undoTxt) - difW * 2
            setTextColor(0.4, 0.85, 1.0, 1)
            renderText(undoX, infoLineY, size * 0.85, utf8Substr(undoTxt, 0))
            local undoW = getTextWidth(size * 0.85, undoTxt)
            DispoList.filterUndoArea = {x1=undoX, y1=infoPosY, x2=undoX+undoW+difW, y2=infoPosY+iconH}
        end
    elseif (DispoList.filterMode == "station" or DispoList.filterMode == "freischalt") and DispoList.filterSelStation ~= nil then
        setTextColor(unpack(DL_Colors.gruenHead))
        renderText(infoX, infoLineY, size * 0.85, utf8Substr(DL_t("filter_station_lbl") .. " " .. DispoList.filterSelStation, 0))
    else
        setTextColor(unpack(DL_Colors.grauDim))
        local hint = DispoList.filterMode == "bereich" and DL_t("hint_bereich_wahl") or DL_t("hint_station_wahl")
        renderText(infoX, infoLineY, size * 0.85, utf8Substr(hint, 0))
    end

    -- ── Trennlinie unter Info-Zeile ───────────────────────────────────────────
    local sepY = infoLineY - lineH * 0.85
    DispoList.filterPauseBtnArea = nil
    if bgLine ~= nil then
        g_currentMission.hlUtils.setOverlay(bgLine, x, sepY, w, difH * 0.12)
        g_currentMission.hlUtils.setBackgroundColor(bgLine, {0.95, 0.85, 0.1, 0.3})
    end

    -- ── Layout ────────────────────────────────────────────────────────────────
    local listTop = sepY - difH * 0.3
    -- colW dynamisch: nach längstem Stationsnamen (gecacht)
    if box.needsUpdate or box.ownTable.filterColW == nil then
        local maxSW = w * 0.25  -- Minimum
        if DispoList.filterMode == "station" or DispoList.filterMode == "freischalt" then
            local stations = DL_FilterMenu_Draw.buildStationList()
            for _, st in ipairs(stations or {}) do
                local tw = getTextWidth(size, utf8Substr((st.name or "") .. "  ", 0))
                if tw > maxSW then maxSW = tw end
            end
        end
        -- Bereiche-Namen prüfen
        for name, _ in pairs(DispoList.BEREICHE or {}) do
            local tw = getTextWidth(size, utf8Substr(name .. "  ", 0))
            if tw > maxSW then maxSW = tw end
        end
        box.ownTable.filterColW = math.min(maxSW + difW * 2, w * 0.45)
    end
    local colW    = box.ownTable.filterColW
    local col2X   = x + colW

    if bgLine ~= nil then
        g_currentMission.hlUtils.setOverlay(bgLine, col2X, y, difW * 0.1, listTop - y)
        g_currentMission.hlUtils.setBackgroundColor(bgLine, {0.4, 0.4, 0.4, 0.4})
    end

    -- Spalten-Überschriften
    setTextColor(unpack(DL_Colors.grau))
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_LEFT)
    if DispoList.filterSearchActive and DispoList.filterSearchText ~= "" then
        -- Suchmodus Header
        setTextColor(0.0, 1.0, 0.8, 1)
        setTextBold(true)
        local cursor = DispoList.filterSearchCursorVisible and "|" or " "
        renderText(x + difW, listTop, size * 0.95,
            utf8Substr(DL_t("filter_suche_lbl") .. " " .. DispoList.filterSearchText .. cursor .. "  -  " .. DL_t("spalte_ware") .. " -> " .. DL_t("filter_bereich_col"), 0))
        setTextBold(false)
    elseif DispoList.filterMode == "bereich" then
        setTextColor(unpack(DL_Colors.grau))
        renderText(x + difW, listTop, size * 1.0, utf8Substr(DL_t("filter_bereich_col"), 0))
        local remaining = DL_FilterMenu_Draw.getRemainingCount()
        local hdrR = "Ware  (" .. remaining .. " frei)"
        renderText(col2X + difW, listTop, size * 1.0, utf8Substr(hdrR, 0))

        -- Farblegende (kein Hover noetig), normale Schriftgroesse
        setTextBold(false)
        local legendY = listTop - lineH * 1.2
        local lx = col2X + difW
        setTextColor(unpack(DL_Colors.gruenHead))
        renderText(lx, legendY, size * 1.0, utf8Substr(DL_t("filter_legende_gruen"), 0))
        lx = lx + getTextWidth(size * 1.0, "Gruen = zugeordnet   ")
        setTextColor(unpack(DL_Colors.grau65))
        renderText(lx, legendY, size * 1.0, utf8Substr(DL_t("filter_legende_grau"), 0))
        if DispoList.dlSelectedFt ~= nil then
            lx = lx + getTextWidth(size * 1.0, "Grau = nicht zugeordnet   ")
            setTextColor(0.0, 0.6, 1.0, 1)
            renderText(lx, legendY, size * 1.0, utf8Substr(DL_t("filter_legende_blau"), 0))
        end
    elseif DispoList.filterMode == "freischalt" then
        setTextColor(unpack(DL_Colors.grau))
        renderText(x + difW, listTop, size * 1.0, utf8Substr(DL_t("filter_station_col"), 0))
        renderText(col2X + difW, listTop, size * 1.0, utf8Substr(DL_t("fs_col_ware"), 0))
        -- Farblegende
        setTextBold(false)
        local legendY = listTop - lineH * 1.2
        local lx = col2X + difW
        setTextColor(unpack(DL_Colors.gruen))
        renderText(lx, legendY, size * 1.0, utf8Substr("v " .. DL_t("fs_leg_frei"), 0))
        lx = lx + getTextWidth(size * 1.0, "v " .. DL_t("fs_leg_frei") .. "    ")
        setTextColor(0.82, 0.82, 0.82, 1)
        renderText(lx, legendY, size * 1.0, utf8Substr("- " .. DL_t("fs_leg_verfuegbar"), 0))
        lx = lx + getTextWidth(size * 1.0, "- " .. DL_t("fs_leg_verfuegbar") .. "    ")
        setTextColor(unpack(DL_Colors.grauMit))
        renderText(lx, legendY, size * 1.0, utf8Substr("# " .. DL_t("fs_leg_native"), 0))
        lx = lx + getTextWidth(size * 1.0, "# " .. DL_t("fs_leg_native") .. "    ")
        setTextColor(unpack(DL_Colors.gruen))
        renderText(lx, legendY, size * 1.0, utf8Substr("# " .. DL_t("fs_leg_erzwungen"), 0))
        -- Hilfe-Zeile: erklaert den #-Klick (Palette/andere Form freischalten)
        setTextColor(unpack(DL_Colors.grauDim))
        renderText(col2X + difW, legendY - lineH, size * 0.9, utf8Substr(DL_t("fs_hint_erzwingen"), 0))
    else
        -- Station-Modus: normaler Header, kein Banner
        setTextColor(unpack(DL_Colors.grau))
        renderText(x + difW, listTop, size * 1.0, utf8Substr(DL_t("filter_station_col"), 0))
        renderText(col2X + difW, listTop, size * 1.0, utf8Substr(DL_t("filter_bereich_ware"), 0))
    end
    setTextBold(false)

    DispoList.filterClearAllArea = nil
    -- filterUndoArea wird weiter oben in der Info-Zeile gesetzt wenn vorhanden

    local listStart = listTop - lineH * 1.2
    local showLegend = (DispoList.filterMode == "bereich" or DispoList.filterMode == "freischalt")
        and not (DispoList.filterSearchActive and DispoList.filterSearchText ~= "")
    if showLegend then
        listStart = listStart - lineH
        -- Zusatzabnahme-Tab hat zusaetzlich eine Hilfe-Zeile unter der Legende
        if DispoList.filterMode == "freischalt" then
            listStart = listStart - lineH
        end
    end
    DispoList.filterLeftAreas  = {}
    DispoList.filterRightAreas = {}

    local rightScrollOffset = box.screen.bounds[1] or 1
    local totalRightLines   = 0

    if DispoList.filterSearchActive and DispoList.filterSearchText ~= "" then
        totalRightLines = DL_FilterMenu_Draw.drawSearchMode(
            x, y, w, h, col2X, colW, listStart, listTop, size, lineH, difW, bgLine, rightScrollOffset)
    elseif DispoList.filterMode == "bereich" then
        totalRightLines = DL_FilterMenu_Draw.drawBereichMode(
            x, y, w, h, col2X, colW, listStart, listTop, size, lineH, difW, bgLine, rightScrollOffset, fOvGroup, fOvByName)
    elseif DispoList.filterMode == "freischalt" then
        totalRightLines = DL_FilterMenu_Draw.drawFreischaltMode(
            x, y, w, h, col2X, colW, listStart, listTop, size, lineH, difW, bgLine, rightScrollOffset, fOvGroup, fOvByName)
    else
        totalRightLines = DL_FilterMenu_Draw.drawStationMode(
            x, y, w, h, col2X, colW, listStart, listTop, size, lineH, difW, bgLine, rightScrollOffset, fOvGroup, fOvByName)
    end

    box.screen.bounds[4] = math.max(1, totalRightLines)
    -- Mausrad-Scroll via DispoList:mouseEvent (linke Spalte)
    -- Mausrad-Scroll rechte Spalte: HL-System via canBounds.on + bounds[1]/[4]
    DispoList.filterScrollAreas = {}  -- keine Pfeil-Klickbereiche mehr

    -- ── Klick-Handler ─────────────────────────────────────────────────────────
    box:setClickArea({
        x, x+w, y, y+h,
        whereClick = "box_",
        onClick = function(clickArgs)
            -- Linksklick: nur bei isDown=false (mouseUp) reagieren
            -- Rechtsklick: bei isDown=true reagieren (mouseDown)
            if clickArgs.isDown and clickArgs.button ~= Input.MOUSE_BUTTON_RIGHT then return end
            if not clickArgs.isDown and clickArgs.button == Input.MOUSE_BUTTON_RIGHT then return end

            -- Mausposition: DispoList._mouseX/Y wird von eigenem mouseEvent-Listener gecacht
            -- (wird vor HL-System aufgerufen, daher immer aktuell)
            local px = DispoList._mouseX
            local py = DispoList._mouseY
            if px == nil or py == nil then
                -- Fallback: mouseCursor
                local mc = g_currentMission.hlUtils.mouseCursor
                if mc == nil then return end
                px, py = mc.posX, mc.posY
            end

            -- Kontextmenü-Klick (Linksklick auf Option)
            if DispoList.contextMenuAreas ~= nil then
                for _, opt in ipairs(DispoList.contextMenuAreas) do
                    if px>=opt.x1 and px<=opt.x2 and py>=opt.y1 and py<=opt.y2 then
                        local cm = DispoList.contextMenu
                        if cm ~= nil then
                            DL_Filter:toggleBereichZuordnung(opt.bereich, cm.ftName, opt.alreadyIn)
                            DL_FilterMenu_Draw._remainingCache = nil
                            DispoList.filterAllStations = nil
                            DispoList:refreshDispoTable()
                        end
                        DispoList.contextMenu = nil
                        return
                    end
                end
                -- Klick ausserhalb schliesst Kontextmenü
                DispoList.contextMenu = nil
            end

            -- filterContextMenu: Rechtsklick-Kontextmenü für Bereiche
            -- Nur bei Linksklick auswerten -- sonst schliesst das wiederholt feuernde
            -- HL-onClick beim gehaltenen Rechtsklick das gerade erst geoeffnete Menue
            -- sofort wieder selbst (verifiziert 02.07., Symptom: Menue "blitzt" nur
            -- Millisekunden auf). Rechtsklick soll das Menue ausschliesslich OEFFNEN,
            -- niemals schliessen.
            if DispoList.filterContextMenu ~= nil and clickArgs.button == Input.MOUSE_BUTTON_LEFT then
                local fcm = DispoList.filterContextMenu
                for _, opt in ipairs(fcm.areas or {}) do
                    if px>=opt.x1 and px<=opt.x2 and py>=opt.y1 and py<=opt.y2 then
                        local now = g_currentMission.time or 0
                        if DispoList.dlClickCooldown ~= nil and now - DispoList.dlClickCooldown < 400 then return end
                        DispoList.dlClickCooldown = now
                        if opt.action == "rename" then
                            local dialog = g_gui:showDialog("TextInputDialog")
                            if dialog ~= nil then
                                dialog.target:setText(DL_t("dlg_bereich_umbenennen"))
                                dialog.target:setDialogType(DialogElement.TYPE_QUESTION)
                                dialog.target:setButtonTexts(g_i18n:getText("button_ok"), g_i18n:getText("button_cancel"))
                                dialog.target:setCallback(function(result, yes)
                                    if not yes or result == nil then return end
                                    result = result:match("^%s*(.-)%s*$")
                                    if result == "" or result == fcm.bereich then return end
                                    if utf8Strlen(result) > 32 then result = utf8Substr(result, 0, 32) end
                                    if DispoList.BEREICHE[result] ~= nil then return end
                                    -- Bereich umbenennen
                                    DispoList.BEREICHE[result] = DispoList.BEREICHE[fcm.bereich]
                                    DispoList.BEREICHE[fcm.bereich] = nil
                                    DL_FilterMenu_Draw.invalidateBereicheCache()  -- Umbenennen -> Sortier-Cache neu
                                    DL_Filter.bereichZuordnung[result] = DL_Filter.bereichZuordnung[fcm.bereich]
                                    DL_Filter.bereichZuordnung[fcm.bereich] = nil
                                    -- Cache der automatischen Vorgabe-Zuordnung neu bauen -- sonst zeigen
                                    -- automatisch (nicht manuell) zugeordnete Waren weiter auf den alten Namen
                                    DispoList.buildFillTypeToBereich()
                                    -- Kein eager save mehr -- zentral ueber ItemSystem.save-Hook
                                    DL_FilterMenu_Draw._remainingCache = nil
                                    if DispoList.filterSelBereich == fcm.bereich then
                                        DispoList.filterSelBereich = result
                                    end
                                    DispoList:refreshDispoTable()
                                end, nil, fcm.bereich)
                            end
                        elseif opt.action == "delete" then
                            local dialog = g_gui:showDialog("YesNoDialog")
                            if dialog ~= nil then
                                dialog.target:setTitle(DL_t("dlg_bereich_loeschen"))
                                dialog.target:setText(DL_t("dlg_loeschen_frage") .. " '" .. DL_bereichLabel(fcm.bereich) .. "'?")
                                dialog.target:setCallback(function(yes)
                                    if yes then DL_FilterMenu_Draw.loescheBereich(fcm.bereich) end
                                end)
                            end
                        end
                        DispoList.filterContextMenu = nil
                        return
                    end
                end
                -- Klick ausserhalb schliesst Menü
                DispoList.filterContextMenu = nil
                return
            end

            -- Modus-Tabs
            for _, tab in ipairs(DispoList.filterModeTabs or {}) do
                if px>=tab.x1 and px<=tab.x2 and py>=tab.y1 and py<=tab.y2 then
                    if clickArgs.button == Input.MOUSE_BUTTON_LEFT then
                        DispoList.filterMode       = tab.mode
                        DispoList.filterLeftScroll  = 1
                        box.screen.bounds[1]       = 1
                        DispoList.filterSelStation  = nil
                        DispoList.filterSelBereich  = nil
                        DispoList.dlSelectedFt      = nil
                        DispoList.dlSelectedFtTitle = nil
                        DispoList.dlSelectedFtBereich = nil
                        DispoList.contextMenu       = nil
                        box.ownTable.filterColW     = nil  -- Cache invalidieren
                    end
                    return
                end
            end

            -- Alle zurücksetzen
            -- Rückgängig
            local ua = DispoList.filterUndoArea
            if ua and px>=ua.x1 and px<=ua.x2 and py>=ua.y1 and py<=ua.y2 then
                if clickArgs.button == Input.MOUSE_BUTTON_LEFT and DispoList.filterSnapshot ~= nil then
                    -- Snapshot wiederherstellen
                    DL_Filter.blacklist        = DispoList.filterSnapshot.blacklist
                    DL_Filter.bereichZuordnung = DispoList.filterSnapshot.bereichZuordnung
                    -- Kein eager save mehr -- zentral ueber ItemSystem.save-Hook
                    DispoList.filterSnapshot     = nil
                    DispoList.filterResetConfirm = false
                    DispoList.filterResetDone    = false
                    DispoList.filterAllStations  = nil
                    DispoList:refreshDispoTable()
                end
                return
            end
            -- Reset (mit Bestätigung)
            local ca = DispoList.filterClearAllArea
            if ca and px>=ca.x1 and px<=ca.x2 and py>=ca.y1 and py<=ca.y2 then
                if clickArgs.button == Input.MOUSE_BUTTON_LEFT then
                    if not DispoList.filterResetConfirm then
                        -- Erster Klick: Snapshot speichern + Bestätigung anfordern
                        DispoList.filterResetConfirm = true
                        DispoList.filterSnapshot = {
                            blacklist        = {},
                            bereichZuordnung = {},
                        }
                        -- Deep copy blacklist
                        if DL_Filter.blacklist then
                            for st, fts in pairs(DL_Filter.blacklist) do
                                DispoList.filterSnapshot.blacklist[st] = {}
                                for ft, v in pairs(fts) do
                                    DispoList.filterSnapshot.blacklist[st][ft] = v
                                end
                            end
                        end
                        -- Deep copy bereichZuordnung
                        if DL_Filter.bereichZuordnung then
                            for ber, fts in pairs(DL_Filter.bereichZuordnung) do
                                DispoList.filterSnapshot.bereichZuordnung[ber] = {}
                                for ft, v in pairs(fts) do
                                    DispoList.filterSnapshot.bereichZuordnung[ber][ft] = v
                                end
                            end
                        end
                    else
                        -- Zweiter Klick: wirklich löschen
                        DispoList.filterResetConfirm = false
                        DispoList.filterResetDone    = true
                        if DispoList.filterMode == "bereich" then
                            DL_Filter.bereichZuordnung = {}
                            -- Kein eager save mehr -- zentral ueber ItemSystem.save-Hook
                        else
                            DL_Filter:clearAll()
                        end
                        DispoList.filterAllStations = nil
                        DispoList:refreshDispoTable()
                    end
                end
                return
            end
            -- Klick ausserhalb Reset-Button: Bestätigung abbrechen
            DispoList.filterResetConfirm = false

            -- Linke Scroll-Pfeile
            for _, sa in ipairs(DispoList.filterScrollAreas or {}) do
                if px>=sa.x1 and px<=sa.x2 and py>=sa.y1 and py<=sa.y2 then
                    if clickArgs.button == Input.MOUSE_BUTTON_LEFT then
                        DispoList.filterLeftScroll = math.max(1, (DispoList.filterLeftScroll or 1) + sa.dir)
                    end
                    return
                end
            end

            -- Linke Liste
            for _, area in ipairs(DispoList.filterLeftAreas or {}) do
                if px>=area.x1 and px<=area.x2 and py>=area.y1 and py<=area.y2 then
                    if clickArgs.button == Input.MOUSE_BUTTON_LEFT then
                        -- "+ Neuer Bereich" Button
                        if area.key == "__neu__" then
                            local now = g_currentMission.time or 0
                            if DispoList.dlClickCooldown ~= nil and now - DispoList.dlClickCooldown < 400 then return end
                            DispoList.dlClickCooldown = now
                            local dialog = g_gui:showDialog("TextInputDialog")
                            if dialog ~= nil then
                                dialog.target:setText(DL_t("dlg_neuer_bereich"))
                                dialog.target:setDialogType(DialogElement.TYPE_QUESTION)
                                dialog.target:setButtonTexts(g_i18n:getText("button_ok"), g_i18n:getText("button_cancel"))
                                dialog.target:setCallback(function(result, yes)
                                    if not yes then return end
                                    if result == nil then return end
                                    result = result:match("^%s*(.-)%s*$")
                                    if result == "" then return end
                                    if utf8Strlen(result) > 32 then result = utf8Substr(result, 0, 32) end
                                    if DispoList.BEREICHE[result] ~= nil then return end
                                    local maxOrder = 0
                                    for _, data in pairs(DispoList.BEREICHE) do
                                        if (data.order or 0) > maxOrder then maxOrder = data.order or 0 end
                                    end
                                    DispoList.BEREICHE[result] = {order=maxOrder+1, fillTypes={}}
                                    DL_FilterMenu_Draw.invalidateBereicheCache()  -- neuer Bereich -> Sortier-Cache neu
                                    DL_Filter.bereichZuordnung[result] = DL_Filter.bereichZuordnung[result] or {}
                                    if DL_Filter.xmlPath == nil then
                                        local saveDir = g_currentMission and g_currentMission.missionInfo and g_currentMission.missionInfo.savegameDirectory
                                        if saveDir ~= nil then DL_Filter.xmlPath = saveDir .. "/dispoList_filter.xml" end
                                    end
                                    -- Kein eager save mehr -- zentral ueber ItemSystem.save-Hook
                                    DispoList.filterSelBereich = result
                                end, nil, "")
                            end
                            return
                        end
                        if DispoList.filterMode == "bereich" and DispoList.dlSelectedFt ~= nil then
                            -- Click-Drop: selektierten FillType diesem Bereich zuordnen
                            local ftName = DispoList.dlSelectedFt
                            local fromBereich = DispoList.dlSelectedFtBereich
                            local zielBereich = area.key
                            if fromBereich ~= nil and fromBereich ~= zielBereich then
                                DL_Filter:toggleBereichZuordnung(fromBereich, ftName, true)
                            end
                            if zielBereich ~= fromBereich then
                                DL_Filter:toggleBereichZuordnung(zielBereich, ftName, false)
                                DL_FilterMenu_Draw._remainingCache = nil
                                DispoList.filterAllStations = nil
                                DispoList:refreshDispoTable()
                            end
                            DispoList.dlSelectedFt = nil
                            DispoList.dlSelectedFtBereich = nil
                        elseif DispoList.filterMode == "bereich" then
                            DispoList.filterSelBereich = area.key
                            box.screen.bounds[1] = 1
                            box.screen.bounds[4] = 1
                            DispoList.filterLeftScroll = 1
                            DL_FilterMenu_Draw._remainingCache = nil
                        else
                            DispoList.filterSelStation = area.station
                            DispoList.filterExpandedBereich = nil
                            box.screen.bounds[1] = 1
                            box.screen.bounds[4] = 1
                            DispoList.filterLeftScroll = 1
                            DL_FilterMenu_Draw._remainingCache = nil
                        end
                    elseif clickArgs.button == Input.MOUSE_BUTTON_RIGHT then
                        -- Rechtsklick: Kontextmenü öffnen (nicht für __neu__)
                        -- Verhalten A: Ist bereits ein Menue offen, laesst der Rechtsklick
                        -- es in Ruhe (kein Neuoeffnen, kein Umziehen). Rechtsklick OEFFNET
                        -- ausschliesslich, Schliessen ist Aufgabe des Linksklicks.
                        if DispoList.filterContextMenu ~= nil then return end
                        if area.key ~= "__neu__" and DispoList.filterMode == "bereich" then
                            local now = g_currentMission.time or 0
                            if DispoList.dlClickCooldown ~= nil and now - DispoList.dlClickCooldown < 400 then
                                return
                            end
                            DispoList.dlClickCooldown = now
                            DispoList.filterContextMenu = {
                                bereich = area.key,
                                posX    = px,
                                posY    = py,
                            }
                        end
                    end
                    return
                end
            end

            -- Rechte Liste (nur Linksklick - Rechtsklick via mouseEvent)
            if clickArgs.button ~= Input.MOUSE_BUTTON_LEFT then return end
            for _, area in ipairs(DispoList.filterRightAreas or {}) do
                if px>=area.x1 and px<=area.x2 and py>=area.y1 and py<=area.y2 then
                    if area.typ == "bereich_zuordnung" then
                        -- Cooldown: HL-System feuert wiederholt, nur einmal pro 400ms reagieren
                        local now = g_currentMission.time or 0
                        if DispoList.dlClickCooldown ~= nil and now - DispoList.dlClickCooldown < 400 then return end
                        DispoList.dlClickCooldown = now
                        -- Click-Select: erster Klick selektiert immer (blau)
                        -- zweiter Klick auf denselben = Auswahl aufheben + direkt togglen
                        if DispoList.dlSelectedFt == area.ftName then
                            -- Nochmal klicken = Auswahl aufheben UND togglen
                            DL_Filter:toggleBereichZuordnung(area.bereich, area.ftName, area.zugeordnet)
                            DL_FilterMenu_Draw._remainingCache = nil
                            DispoList:refreshDispoTable()
                            DispoList.dlSelectedFt = nil
                            DispoList.dlSelectedFtBereich = nil
                        else
                            -- Erster Klick (oder anderer FillType): selektieren, NICHT togglen
                            DispoList.dlSelectedFt = area.ftName
                            DispoList.dlSelectedFtTitle = area.title or area.ftName
                            DispoList.dlSelectedFtBereich = area.zugeordnet and area.bereich or nil
                        end
                    elseif area.typ == "station_filter" then
                        -- Einzelklick: Filter an/aus
                        if area.filtered then
                            DL_Filter:removeFilter(area.station, area.ftName)
                        else
                            DL_Filter:addFilter(area.station, area.ftName)
                        end
                        DispoList:refreshDispoTable()
                    elseif area.typ == "bereich_toggle" then
                        -- Ganzen Bereich für diese Station an/aus schalten
                        local forceState = area.allOff and "ON" or "OFF"
                        for _, item in ipairs(area.berFTs) do
                            if forceState == "OFF" then
                                DL_Filter:addFilter(area.station, item.ftName)
                            else
                                DL_Filter:removeFilter(area.station, item.ftName)
                            end
                        end
                        -- Kein eager save mehr -- zentral ueber ItemSystem.save-Hook
                        DispoList.filterAllStations = nil  -- Cache leeren
                        DispoList:refreshDispoTable()
                    elseif area.typ == "su_toggle" then
                        -- Freischalt-Modus: Ware an dieser Station freischalten / entfernen
                        local now = g_currentMission.time or 0
                        if DispoList.dlClickCooldown ~= nil and now - DispoList.dlClickCooldown < 400 then return end
                        DispoList.dlClickCooldown = now
                        if DL_SellpointUnlock ~= nil then
                            DL_SellpointUnlock.guiToggle(area.station, area.ftName)
                        end
                        DispoList:refreshDispoTable()
                    elseif area.typ == "su_scale" then
                        -- Freischalt-Modus: Preis-Faktor +/- 0.05
                        local now = g_currentMission.time or 0
                        if DispoList.dlClickCooldown ~= nil and now - DispoList.dlClickCooldown < 250 then return end
                        DispoList.dlClickCooldown = now
                        if DL_SellpointUnlock ~= nil then
                            DL_SellpointUnlock.guiScale(area.station, area.ftName, area.dir)
                        end
                        DispoList:refreshDispoTable()
                    elseif area.typ == "bereich_expand" then
                        -- Akkordeon: aufgeklappten Bereich umschalten (nur einer offen)
                        if DispoList.filterExpandedBereich == area.bereich then
                            DispoList.filterExpandedBereich = nil
                        else
                            DispoList.filterExpandedBereich = area.bereich
                        end
                        box.screen.bounds[1] = 1
                    end
                    return
                end
            end
        end,
    })

    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(unpack(DL_Colors.white))
    setTextBold(false)

    -- ── Kontextmenü zeichnen (Rechtsklick auf Ware) ──────────────────────────
    DispoList.contextMenuAreas = nil
    local cm = DispoList.contextMenu
    if cm ~= nil then
        local cmX  = cm.posX
        local cmY  = cm.posY
        local cmW  = size * 18
        local cmLH = lineH * 1.1
        local cmH  = cmLH * (2 + #cm.bereiche)
        -- Hintergrund
        if box.overlays.bgLine ~= nil then
            g_currentMission.hlUtils.setOverlay(box.overlays.bgLine, cmX, cmY - cmH, cmW, cmH)
            g_currentMission.hlUtils.setBackgroundColor(box.overlays.bgLine, {0.05, 0.12, 0.18, 0.97})
            box.overlays.bgLine:render()
        end
        -- Titel
        setTextBold(true)
        setTextColor(unpack(DL_Colors.lagerBlau))
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(cmX + difW, cmY - cmLH * 0.8, size * 0.85,
            utf8Substr(DL_t("filter_zu_bereich"), 0))
        renderText(cmX + difW, cmY - cmLH * 1.7, size * 0.8,
            utf8Substr(utf8Substr(cm.title, 0), 0))
        setTextBold(false)
        -- Bereich-Optionen
        DispoList.contextMenuAreas = {}
        for i, ber in ipairs(cm.bereiche) do
            local optY = cmY - cmLH * (1.7 + i)
            local alreadyIn = DL_Filter.bereichZuordnung ~= nil and
                              DL_Filter.bereichZuordnung[ber] ~= nil and
                              DL_Filter.bereichZuordnung[ber][cm.ftName] == true
            setTextColor(alreadyIn and 0.4 or 0.85, alreadyIn and 0.9 or 0.85, alreadyIn and 0.4 or 0.85, 1)
            local prefix = alreadyIn and "[v] " or "    "
            renderText(cmX + difW * 2, optY, size * 0.85,
                utf8Substr(prefix .. ber, 0))
            table.insert(DispoList.contextMenuAreas, {
                bereich = ber,
                alreadyIn = alreadyIn,
                x1 = cmX, y1 = optY - cmLH * 0.4,
                x2 = cmX + cmW, y2 = optY + cmLH * 0.6
            })
        end
    end

    -- ── filterContextMenu zeichnen (Rechtsklick auf Bereich) ─────────────────
    local fcm = DispoList.filterContextMenu
    if fcm ~= nil then
        fcm.areas = nil  -- Klickflaechen jeden Frame frisch neu berechnen (analog contextMenuAreas)
        local cmLH = lineH * 1.1
        local opts = {
            {label = DL_t("ctx_umbenennen"), action = "rename"},
            {label = DL_t("ctx_loeschen"),   action = "delete"},
        }
        local cmH = cmLH * (#opts + 1.5)
        local gap  = difW * 0.5

        -- ── Position: rechtsbuendig an die Box-Kante (x+w) ────────────
        -- Menue nur so breit wie noetig (Inhalt) und flush an x+w geklemmt, damit
        -- es im freien Platz RECHTS neben der (schmalen) Warenspalte sitzt statt
        -- ueber den Warennamen. Bleibt komplett INNERHALB der Box-ClickArea, sonst
        -- feuert HL den onClick nicht (verifiziert 02.07.). Links nie ueber col2X
        -- hinaus (nie in die Bereichsliste ragen). Vertikal an Maushoehe geklemmt.
        local cmContentW = getTextWidth(size * 0.85, utf8Substr(DL_bereichLabel(fcm.bereich) .. "  ", 0))
        for _, opt in ipairs(opts) do
            local ow = getTextWidth(size * 0.85, utf8Substr(opt.label .. "  ", 0))
            if ow > cmContentW then cmContentW = ow end
        end
        local cmW  = cmContentW + difW * 4
        local maxW = (x + w) - col2X - gap * 2
        if cmW > maxW then cmW = maxW end
        local cmX  = (x + w) - cmW - gap                       -- rechtsbuendig an Box-Kante
        if cmX < col2X then cmX = col2X end                    -- nie in linke Bereichsliste ragen
        local cmY  = fcm.posY                                  -- Oberkante an Maushoehe
        if cmY - cmH < y then cmY = y + cmH + gap end          -- unten an Box-Kante klemmen
        if cmY > y + h then cmY = y + h - gap end              -- oben an Box-Kante klemmen
        -- Hintergrund (voll deckend, damit die Warenliste nicht durchscheint)
        if box.overlays.bgLine ~= nil then
            g_currentMission.hlUtils.setOverlay(box.overlays.bgLine, cmX, cmY - cmH, cmW, cmH)
            g_currentMission.hlUtils.setBackgroundColor(box.overlays.bgLine, {0.05, 0.10, 0.05, 1.0})
            box.overlays.bgLine:render()
        end
        -- Titel
        setTextBold(true)
        setTextColor(unpack(DL_Colors.gruenHead))
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(cmX + difW, cmY - cmLH * 0.8, size * 0.85, utf8Substr(DL_bereichLabel(fcm.bereich), 0))
        setTextBold(false)
        -- Optionen
        fcm.areas = {}
        for i, opt in ipairs(opts) do
            local optY = cmY - cmLH * (1.0 + i)
            local col = opt.action == "delete" and DL_Colors.rot
                     or                            {0.85,0.85,0.85,1}
            setTextColor(table.unpack(col))
            renderText(cmX + difW * 2, optY, size * 0.85, utf8Substr(opt.label, 0))
            table.insert(fcm.areas, {
                action=opt.action,
                x1=cmX, y1=optY-cmLH*0.4, x2=cmX+cmW, y2=optY+cmLH*0.6
            })
        end
    end
end

-- Anzahl noch nicht zugeordneter FillTypes (gecacht)
DL_FilterMenu_Draw._remainingCache = nil
function DL_FilterMenu_Draw.getRemainingCount()
    if DL_FilterMenu_Draw._remainingCache ~= nil then
        return DL_FilterMenu_Draw._remainingCache
    end
    local allFT = DL_FilterMenu_Draw.getAllMapFillTypes()
    local zugeordnet = {}
    if DL_Filter.bereichZuordnung ~= nil then
        for _, fts in pairs(DL_Filter.bereichZuordnung) do
            for ftName, _ in pairs(fts) do
                zugeordnet[ftName] = true
            end
        end
    end
    local count = 0
    for _, item in ipairs(allFT) do
        if not zugeordnet[item.ftName] then count = count + 1 end
    end
    DL_FilterMenu_Draw._remainingCache = count
    return count
end

-- ── MODUS 1: Bereich-Definition ───────────────────────────────────────────────
-- Zeichnet einen farbigen Status-Punkt via bgLine-Overlay:
--   state = "on"/"mixed"/"sel"/"off" -> gruen/gelb/blau/rot
-- Gibt die gezeichnete Breite (inkl. Abstand) zurueck.
function DL_FilterMenu_Draw.drawCheckIcon(fOvGroup, fOvByName, state, posX, posY, iconSize, difW, tooltip, lineH, bgLine)
    local col
    if     state == "on"    then col = {0.0, 1.0, 0.2, 1}
    elseif state == "mixed" then col = DL_Colors.gold
    elseif state == "sel"   then col = {0.0, 0.6, 1.0, 1}
    else                         col = DL_Colors.rot
    end
    -- Farbigen Text-Marker zeichnen (bgLine ist fuer Zeilenhintergrund reserviert)
    setTextColor(table.unpack(col))
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(true)
    local marker = state == "off" and "x" or state == "mixed" and "~" or "v"
    renderText(posX, posY, iconSize * 1.1, utf8Substr(marker, 0))
    setTextBold(false)
    return iconSize + difW
end

-- Zeichnet den Auf-/Zuklapp-Pfeil (Akkordeon) aus der normalen Box-Icon-Gruppe.
-- expanded=true  -> Pfeil nach unten (boundsDown, aufgeklappt)
-- expanded=false -> Pfeil nach oben  (boundsUp, zugeklappt -> klappt nach unten auf)
-- Gibt die gezeichnete Breite (inkl. Abstand) zurück.
-- Zeichnet ein Icon aus dem HL-Atlas (loadIcons/box-Gruppe) mit Tinting.
-- Gibt die neue X-Position (posX + iconSize + difW) zurück.
function DL_FilterMenu_Draw.drawHLIcon(fOvGroup, fOvByName, iconName, posX, posY, iconSize, difW, col)
    if fOvGroup == nil or fOvByName == nil then return posX + iconSize + difW end
    local idx = fOvByName[iconName]
    local o = idx ~= nil and fOvGroup[idx] or nil
    if o == nil then return posX + iconSize + difW end
    g_currentMission.hlUtils.setOverlay(o, posX, posY - iconSize * 0.15, iconSize, iconSize)
    g_currentMission.hlUtils.setBackgroundColor(o, col or DL_Colors.iconIdle)
    o:render()
    return posX + iconSize + difW
end

function DL_FilterMenu_Draw.drawExpandIcon(fOvGroup, fOvByName, expanded, posX, posY, iconSize, difW)
    if fOvGroup == nil or fOvByName == nil then return 0 end
    local idx = expanded and fOvByName["boundsDown"] or fOvByName["boundsUp"]
    local o = idx ~= nil and fOvGroup[idx] or nil
    if o == nil then return 0 end
    g_currentMission.hlUtils.setOverlay(o, posX, posY - iconSize * 0.15, iconSize, iconSize)
    g_currentMission.hlUtils.setBackgroundColor(o, {0.8, 0.8, 0.8, 1})
    o:render()
    return iconSize + difW
end


-- Alle FillTypes der Karte (gecacht)
function DL_FilterMenu_Draw.getAllMapFillTypes()
    if DL_FilterMenu_Draw._allFTCache ~= nil then
        return DL_FilterMenu_Draw._allFTCache
    end
    local result = {}
    local seen   = {}
    for _, station in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
        if station:isa(SellingStation) and not station.hideFromPricesMenu then
            if station.ownerFarmId ~= g_currentMission:getFarmId() then
                for ftIdx, accepted in pairs(station.acceptedFillTypes) do
                    if DL_Filter.isAcceptedByStation(station, ftIdx) and not seen[ftIdx] then
                        seen[ftIdx] = true
                        local ft = g_fillTypeManager:getFillTypeByIndex(ftIdx)
                        if ft ~= nil and ft.name ~= nil then
                            local title = ft.title
                            -- Animal-FillTypes haben keinen echten title (title == name)
                            -- -> animalSystem fragen wie hlUtils es macht
                            if (title == nil or title == ft.name) and g_currentMission.animalSystem ~= nil then
                                local subTypeIdx = g_currentMission.animalSystem:getSubTypeIndexByFillTypeIndex(ftIdx)
                                local subType    = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIdx)
                                if subType ~= nil and subType.visuals ~= nil and subType.visuals[1] ~= nil
                                   and subType.visuals[1].store ~= nil and subType.visuals[1].store.name ~= nil then
                                    title = ft.title .. "/" .. subType.visuals[1].store.name
                                end
                            end
                            if title == nil or title == "" then title = ft.name end
                            table.insert(result, {title=title, ftName=ft.name})
                        end
                    end
                end
            end
        end
    end
    table.sort(result, function(a,b) return string.lower(a.title) < string.lower(b.title) end)
    DL_FilterMenu_Draw._allFTCache = result
    return result
end

-- Anzahl aller handelbaren Karten-Waren je Bereich (gecacht) -> Nenner fuer "N/M"
-- Sonstiges = alle die keinem Bereich zugeordnet sind.
function DL_FilterMenu_Draw.getMapFTCountsByBereich()
    if DL_FilterMenu_Draw._mapFTCountByBerCache ~= nil then
        return DL_FilterMenu_Draw._mapFTCountByBerCache
    end
    local counts   = {}
    local assigned = {}
    if DL_Filter.bereichZuordnung ~= nil then
        for berName, fts in pairs(DL_Filter.bereichZuordnung) do
            for ftName, _ in pairs(fts) do assigned[ftName] = true end
        end
    end
    for _, item in ipairs(DL_FilterMenu_Draw.getAllMapFillTypes()) do
        local z = DL_Filter.bereichZuordnung
        local placed = false
        if z ~= nil then
            for berName, fts in pairs(z) do
                if fts[item.ftName] == true then
                    counts[berName] = (counts[berName] or 0) + 1
                    placed = true
                end
            end
        end
        if not placed then counts["Sonstiges"] = (counts["Sonstiges"] or 0) + 1 end
    end
    DL_FilterMenu_Draw._mapFTCountByBerCache = counts
    return counts
end

-- Stationsliste (gecacht)
function DL_FilterMenu_Draw.buildStationList()
    if DL_FilterMenu_Draw._stationCache ~= nil then
        return DL_FilterMenu_Draw._stationCache
    end
    local result = {}
    local seen   = {}
    for _, station in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
        if station:isa(SellingStation) and not station.hideFromPricesMenu then
            if station.ownerFarmId ~= g_currentMission:getFarmId() then
                -- Nur Stationen mit mindestens einem echten FillType aufnehmen
                local hasft = false
                if station.acceptedFillTypes ~= nil then
                    for ftIdx, acc in pairs(station.acceptedFillTypes) do
                        if DL_Filter.isAcceptedByStation(station, ftIdx) then hasft = true; break end
                    end
                end
                if hasft then
                    local name = station:getName()
                    if not seen[name] then
                        seen[name] = true
                        table.insert(result, {name=name})
                    end
                end
            end
        end
    end
    table.sort(result, function(a,b) return string.lower(a.name) < string.lower(b.name) end)
    DL_FilterMenu_Draw._stationCache = result
    return result
end

-- Cache leeren (bei Bedarf)
function DL_FilterMenu_Draw.clearCache()
    DL_FilterMenu_Draw._allFTCache      = nil
    DL_FilterMenu_Draw._stationCache    = nil
    DL_FilterMenu_Draw._remainingCache  = nil
    DL_FilterMenu_Draw._poolColW        = nil
    DL_FilterMenu_Draw._poolColWBereich = nil
end

-- ── SUCHMODUS: FillTypes mit Bereichszuordnung ────────────────────────────────
function DL_FilterMenu_Draw.drawSearchMode(x, y, w, h, col2X, colW, listStart, listTop, size, lineH, difW, bgLine, scrollOffset)
    local q = string.lower(DispoList.filterSearchText or "")
    if q == "" then return 0 end

    -- Alle FillTypes sammeln die den Suchbegriff enthalten
    local allFT = DL_FilterMenu_Draw.getAllMapFillTypes()
    local results = {}
    for _, item in ipairs(allFT) do
        local titleL = string.lower(item.title or "")
        local nameL  = string.lower(item.ftName or "")
        if titleL:find(q, 1, true) or nameL:find(q, 1, true) then
            -- Bereichszuordnung ermitteln
            local bereich = "Sonstiges"
            if DL_Filter.bereichZuordnung ~= nil then
                for ber, fts in pairs(DL_Filter.bereichZuordnung) do
                    if fts[item.ftName] == true then
                        bereich = ber
                        break
                    end
                end
            end
            table.insert(results, {ftName=item.ftName, title=item.title, bereich=bereich})
        end
    end
    table.sort(results, function(a,b) return string.lower(a.title) < string.lower(b.title) end)

    -- Ergebnisse rendern
    local posYR   = listStart
    local lineIdx = 0
    for _, item in ipairs(results) do
        lineIdx = lineIdx + 1
        if lineIdx >= scrollOffset and posYR >= y + lineH then
            local isSonstiges = (item.bereich == "Sonstiges")
            -- Spalte 1: FillType-Name (feste Breite = 32 Zeichen)
            local col1W = getTextWidth(size * 0.85, "MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM") + difW * 3
            local col2Xs = x + difW + col1W
            setTextAlignment(RenderText.ALIGN_LEFT)
            setTextColor(0.85, 0.85, 0.85, 1)
            renderText(x + difW, posYR, size * 0.85, utf8Substr(item.title, 0))
            -- Spalte 2: Bereich ab fester Position
            local berColor = isSonstiges and {0.5, 0.5, 0.5, 1} or {0.25, 0.85, 0.25, 1}
            setTextColor(table.unpack(berColor))
            setTextAlignment(RenderText.ALIGN_LEFT)
            renderText(col2Xs, posYR, size * 0.85, utf8Substr("→ " .. DL_bereichLabel(item.bereich), 0))
            table.insert(DispoList.filterRightAreas, {
                typ="search_result",
                ftName=item.ftName,
                title=item.title,
                bereich=item.bereich,
                x1=x+difW*0.3, y1=posYR-lineH*0.4, x2=x+w-difW*0.3, y2=posYR+lineH*0.6
            })
            posYR = posYR - lineH
        end
    end

    -- Kein Ergebnis
    if #results == 0 then
        setTextColor(unpack(DL_Colors.grauMit))
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(col2X + difW, listStart, size * 0.85, utf8Substr(DL_t("filter_keine_treffer"), 0))
    end

    return #results
end

-- ── Bereich löschen ───────────────────────────────────────────────────────────
function DL_FilterMenu_Draw.loescheBereich(bereichName)
    if bereichName == nil or bereichName == "Sonstiges" then return end
    if DispoList.BEREICHE[bereichName] == nil then return end

    -- 1. Aus BEREICHE entfernen + Blacklist
    DispoList.BEREICHE[bereichName] = nil
    DL_FilterMenu_Draw.invalidateBereicheCache()  -- Bereich geloescht -> Sortier-Cache neu
    if DispoList.BEREICHE_DELETED ~= nil then
        DispoList.BEREICHE_DELETED[bereichName] = true
    end

    -- 2. Zuordnungen entfernen — FillTypes wandern nach Sonstiges
    -- (Sonstiges = alles was in keinem bereichZuordnung-Eintrag steht)
    -- Wir löschen einfach die Zuordnungen, der Bereich fällt dann automatisch raus
    if DL_Filter.bereichZuordnung ~= nil then
        DL_Filter.bereichZuordnung[bereichName] = nil
    end

    -- Cache der automatischen Vorgabe-Zuordnung neu bauen -- sonst zeigen
    -- automatisch (nicht manuell) zugeordnete Waren weiter auf den geloeschten Namen
    DispoList.buildFillTypeToBereich()

    -- 3. Selektion zurücksetzen
    DispoList.filterSelBereich = nil

    -- 4. Speichern + UI aktualisieren
    -- xmlPath sicherstellen
    if DL_Filter.xmlPath == nil then
        local saveDir = g_currentMission and g_currentMission.missionInfo and g_currentMission.missionInfo.savegameDirectory
        if saveDir ~= nil then
            DL_Filter.xmlPath = saveDir .. "/dispoList_filter.xml"
        end
    end
    -- Kein eager save mehr -- zentral ueber ItemSystem.save-Hook
    DL_FilterMenu_Draw._remainingCache = nil
    DispoList.filterAllStations = nil
    DispoList:refreshDispoTable()

end
