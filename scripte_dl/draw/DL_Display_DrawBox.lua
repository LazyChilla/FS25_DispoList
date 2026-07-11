--
-- FS25 DispoList - Hauptbox Draw v5
-- 3-zeilige Titelleiste, rechtsbündige Zahlen, HL-System Icons
--

DL_Display_DrawBox = {}

-- Globale Hilfsfunktionen (einmal definiert, nicht bei jedem Frame)
function DL_Display_DrawBox.fmtVol(val)
    return utf8Substr(g_i18n:formatVolume(math.floor(val or 0), 0), 0)
end
function DL_Display_DrawBox.fmtMon(val)
    return utf8Substr(g_i18n:formatMoney(math.floor(val or 0), 0, false), 0)
end

function DL_Display_DrawBox.setBox(args)
    if args == nil or type(args) ~= "table" or args.typPos == nil or args.inArea == nil then return end
    local box = g_currentMission.hlHudSystem.box[args.typPos]
    if box == nil then return end

    if DispoList.CurrentItems == nil or #DispoList.CurrentItems == 0 then
        DispoList:refreshDispoTable()
    end

    local x, y, w, h = box:getScreen()
    local distance    = box:getSize({"distance"})
    local difW        = distance.textWidth
    local difH        = distance.textHeight
    local size        = box.screen.size.zoomOutIn.text[1] or getCorrectTextSize(0.013)

    -- Maus-Cursor ausblenden wenn nicht im Bereich
    if not g_currentMission.hlUtils.isMouseCursor then
        box.isSetting = false
    end
    -- (Settings-Box wird über XmlBox onClick closeIcon_ geschlossen)

    -- ── Cache: Spaltenbreiten und Zeilenhöhe ──────────────────────────────────
    if box.needsUpdate or box.ownTable.lineHeight == nil then
        box.ownTable.lineHeight = getTextHeight(size, utf8Substr("Äg", 0)) + distance.textLine
        box.ownTable.iconWidth, box.ownTable.iconHeight = box:getOptiWidthHeight(
            {typ="icon", height=box.ownTable.lineHeight - distance.textLine - difH, width=w - difW * 2}
        )
        local gap = difW * 2.5
        box.ownTable.gap       = gap
        -- Spaltenbreiten: 0 wenn Spalte ausgeblendet
        local function colW(key, w1, w2)
            if DL_ColSettings ~= nil and not DL_ColSettings:isVisible(key) then return 0 end
            return math.max(w1, w2) + gap
        end
        box.ownTable.wBestand  = colW("bestand",  getTextWidth(size, utf8Substr(DL_t("spalte_bestand"), 0)),    getTextWidth(size, utf8Substr(g_i18n:formatVolume(9999999, 0), 0)))
        box.ownTable.wVerkauf  = colW("frei",     getTextWidth(size, utf8Substr(DL_t("spalte_frei"), 0)),       getTextWidth(size, utf8Substr(g_i18n:formatVolume(9999999, 0), 0)))
        box.ownTable.wPreis    = colW("preis",    getTextWidth(size, utf8Substr(DL_t("spalte_preis"), 0)),      getTextWidth(size, utf8Substr(g_i18n:formatMoney(99999, 0, false) .. " €", 0)))
        box.ownTable.wMaxPreis = colW("maxPreis", getTextWidth(size, utf8Substr("Max", 0)),        getTextWidth(size, utf8Substr(g_i18n:formatMoney(99999, 0, false) .. " €", 0)))
        box.ownTable.wWert     = colW("wert",     getTextWidth(size, utf8Substr(DL_t("spalte_wert"), 0)),       getTextWidth(size, utf8Substr(g_i18n:formatMoney(9999999, 0, false) .. " €", 0)))
        box.ownTable.wVkWert   = colW("vkWert",   getTextWidth(size, utf8Substr(DL_t("spalte_frei_wert"), 0)),    getTextWidth(size, utf8Substr(g_i18n:formatMoney(9999999, 0, false) .. " €", 0)))
        box.ownTable.wMax      = colW("max",      getTextWidth(size, utf8Substr("Max", 0)),        getTextWidth(size, utf8Substr(g_i18n:formatMoney(9999999, 0, false) .. " €", 0)))
        box.ownTable.wVkMax    = colW("vkMax",    getTextWidth(size, utf8Substr(DL_t("spalte_frei_max"), 0)),     getTextWidth(size, utf8Substr(g_i18n:formatMoney(9999999, 0, false) .. " €", 0)))
        box.ownTable.wMonat    = colW("monat",    getTextWidth(size, utf8Substr(DL_t("spalte_bester"), 0)),     getTextWidth(size, utf8Substr("Sept.", 0)))
    end
    box.needsUpdate = false

    local lineH  = box.ownTable.lineHeight
    local iconW  = box.ownTable.iconWidth
    local iconH  = box.ownTable.iconHeight
    local gap    = box.ownTable.gap
    local fmtVol = DL_Display_DrawBox.fmtVol
    local fmtMon = DL_Display_DrawBox.fmtMon

    -- Spalten-Positionen
    local totalFixedW = box.ownTable.wBestand + box.ownTable.wVerkauf + box.ownTable.wPreis +
                        box.ownTable.wMaxPreis + box.ownTable.wWert + box.ownTable.wVkWert +
                        box.ownTable.wMax + box.ownTable.wVkMax + box.ownTable.wMonat
    -- wWareFlex: Ware-Spalte bekommt den Rest, mindestens 4*difW
    -- Gesamtbreite = iconW(FillType) + difW + wWareFlex + totalFixedW + difW(rand)
    local availableW  = w - difW * 2 - iconW - difW
    local wWareFlex   = math.max(difW * 4, availableW - totalFixedW)
    -- Sicherheits-Check: wenn Spalten zu breit, Ware-Spalte auf Minimum
    if wWareFlex < difW * 4 then
        -- Skaliere alle Spalten proportional
        local scale = (availableW - difW * 4) / math.max(totalFixedW, 0.001)
        scale = math.min(1.0, scale)
        box.ownTable.wBestand  = box.ownTable.wBestand  * scale
        box.ownTable.wVerkauf  = box.ownTable.wVerkauf  * scale
        box.ownTable.wPreis    = box.ownTable.wPreis    * scale
        box.ownTable.wMaxPreis = box.ownTable.wMaxPreis * scale
        box.ownTable.wWert     = box.ownTable.wWert     * scale
        box.ownTable.wVkWert   = box.ownTable.wVkWert   * scale
        box.ownTable.wMax      = box.ownTable.wMax      * scale
        box.ownTable.wVkMax    = box.ownTable.wVkMax    * scale
        box.ownTable.wMonat    = box.ownTable.wMonat    * scale
        totalFixedW = totalFixedW * scale
        wWareFlex = difW * 4
    end

    local colWareX     = x + difW + iconW + difW
    local colBestandX  = colWareX + wWareFlex
    local colVerkaufX  = colBestandX  + box.ownTable.wBestand
    local colPreisX    = colVerkaufX  + box.ownTable.wVerkauf
    local colMaxPreisX = colPreisX    + box.ownTable.wPreis
    local colWertX     = colMaxPreisX + box.ownTable.wMaxPreis
    local colVkWertX   = colWertX     + box.ownTable.wWert
    local colMaxX      = colVkWertX   + box.ownTable.wVkWert
    local colVkMaxX    = colMaxX      + box.ownTable.wMax
    local colMonatX    = colVkMaxX    + box.ownTable.wVkMax

    -- Rechts-Positionen für ALIGN_RIGHT
    local rBestand  = colBestandX  + box.ownTable.wBestand  - gap*0.4
    local rVerkauf  = colVerkaufX  + box.ownTable.wVerkauf  - gap*0.4
    local rPreis    = colPreisX    + box.ownTable.wPreis    - gap*0.4
    local rMaxPreis = colMaxPreisX + box.ownTable.wMaxPreis - gap*0.4
    local rWert     = colWertX     + box.ownTable.wWert     - gap*0.4
    local rVkWert   = colVkWertX   + box.ownTable.wVkWert   - gap*0.4
    local rMax      = colMaxX      + box.ownTable.wMax      - gap*0.4
    local rVkMax    = colVkMaxX    + box.ownTable.wVkMax    - gap*0.4
    local rMonat    = colMonatX    + box.ownTable.wMonat    - gap*0.4
    -- Clamp: rechter Rand der Box
    local rightEdge = x + w - difW
    rBestand  = math.min(rBestand,  rightEdge)
    rVerkauf  = math.min(rVerkauf,  rightEdge)
    rPreis    = math.min(rPreis,    rightEdge)
    rMaxPreis = math.min(rMaxPreis, rightEdge)
    rWert     = math.min(rWert,     rightEdge)
    rVkWert   = math.min(rVkWert,   rightEdge)
    rMax      = math.min(rMax,      rightEdge)
    rVkMax    = math.min(rVkMax,    rightEdge)
    rMonat    = math.min(rMonat,    rightEdge)

    -- ── Scroll bounds: exakt wie lineIdx im Draw ─────────────────────────────
    local totalLines = 0
    local lastStation = nil
    local lastBereich = nil
    for _, e in ipairs(DispoList.CurrentItems) do
        if (e.stockLevel or 0) >= 1 then
            -- Stationsheader: Leerzeile + Header = 2 Zeilen
            if e.stationName ~= lastStation then
                lastStation = e.stationName
                lastBereich = nil
                if e.stationName ~= nil and e.stationName ~= "" then
                    totalLines = totalLines + 2  -- Leerzeile + Stationsheader
                end
            end
            -- Bereichsheader: 1 Zeile (Feld heisst 'bereich' nicht 'bereichName')
            local ber = e.bereich and e.bereich.name or ""
            if ber ~= lastBereich then
                lastBereich = ber
                totalLines = totalLines + 1
            end
            -- FillType-Zeile
            totalLines = totalLines + 1
        end
    end
    local hasDeltaMsg = DispoList.isInit and (
        (DispoList.deltaNewCount or 0) > 0
    )
    totalLines = totalLines + 4  -- Icon-Zeile + Frei-Erklaerung + 2 Titelzeilen
    if hasDeltaMsg then totalLines = totalLines + 1 end
    if box.viewExtraLine then totalLines = totalLines + 1 end
    box.screen.bounds[4] = math.max(1, totalLines)

    local curM = g_currentMission.environment.currentPeriod or 1

    -- Box-Hintergrund-Alpha (3 Stufen: normal, hell, transparent)
    local bgAlphas = {0.88, 0.45, 0.12}
    local bgAlpha  = bgAlphas[box.ownTable.bgAlphaIdx or 1]
    -- Global speichern damit Filter-Box denselben Wert nutzt
    DispoList._bgAlphaIdx = box.ownTable.bgAlphaIdx or 1
    if box.overlays.bg ~= nil then
        g_currentMission.hlUtils.setBackgroundColor(box.overlays.bg,
            {0, 0, 0, bgAlpha})
    end

    -- ── ZEILE 1: Icons ────────────────────────────────────────────────────────
    local iconLineY  = y + h - lineH * 0.6
    local bgLine     = box.overlays.bgLine
    -- Icons aus box.overlays.icons (loadDefaultIcons=true in generate() nötig)
    local overlayDefaultGroup  = box.overlays.icons and box.overlays.icons["defaultIcons"] and box.overlays.icons["defaultIcons"]["box"] or nil
    local overlayDefaultByName = box.overlays.icons and box.overlays.icons.byName and box.overlays.icons.byName["defaultIcons"] and box.overlays.icons.byName["defaultIcons"]["box"] or {}
    local inArea = args.inArea

    if bgLine ~= nil then
        g_currentMission.hlUtils.setOverlay(bgLine, x, iconLineY - lineH*0.55, w, lineH*0.9)
        g_currentMission.hlUtils.setBackgroundColor(bgLine, {0.03, 0.03, 0.03, 0.95})
        bgLine:render()
    end

    local iconPosY = iconLineY - iconH * 0.5

    -- onSettingClick Handler (einmalig registrieren)
    if box.onSettingClick == nil then
        box.ownTable.zoomActive = box.ownTable.zoomActive or false  -- Toggle-State für Zoom-Icon
        box.onSettingClick = function(a)
            if a == nil then return end
            if a.clickAreaTable == nil then return end
            local wc  = a.clickAreaTable.whereClick
            local btn = a.button
            -- dl_ware_ feuert bei isDown=false (mouseUp), alle anderen bei isDown=true
            if wc ~= "dl_ware_" and not a.isDown then return end

            if wc == "dl_lineDistance_" then
                -- Zeilenabstand: Links = mehr, Rechts = weniger
                local maxD = box.screen.pixelH * 8
                local cur  = box.screen.size.distance.textLine
                local step = box.screen.pixelH / 2
                if btn == Input.MOUSE_BUTTON_LEFT then
                    if cur + step <= maxD then
                        box.screen.size.distance.textLine = cur + step
                        box.ownTable.lineHeight = nil
                        box.needsUpdate = true
                    end
                elseif btn == Input.MOUSE_BUTTON_RIGHT then
                    if cur - step >= 0 then
                        box.screen.size.distance.textLine = cur - step
                        box.ownTable.lineHeight = nil
                        box.needsUpdate = true
                    end
                end

            elseif wc == "dl_zoomToggle_" then
                local zoom = box.screen.size.zoomOutIn.text
                if zoom ~= nil then
                    local step  = zoom[2] or 0.1
                    local cur   = zoom[1] or 0.012
                    local minS  = zoom[4] or 0.006
                    local maxS  = zoom[3] or 0.030
                    if btn == Input.MOUSE_BUTTON_LEFT then
                        local newS = math.min(cur + step, maxS)
                        box.screen.size.zoomOutIn.text[1] = newS
                        box.needsUpdate = true
                    elseif btn == Input.MOUSE_BUTTON_RIGHT then
                        local newS = math.max(cur - step, minS)
                        box.screen.size.zoomOutIn.text[1] = newS
                        box.needsUpdate = true
                    end
                end

            elseif wc == "dl_sortToggle_" then
                if btn == Input.MOUSE_BUTTON_LEFT then
                    DispoList.sortByValue = not DispoList.sortByValue
                    DispoList:refreshDispoTable()
                end
            elseif wc == "dl_search_" then
                if btn == Input.MOUSE_BUTTON_LEFT and not (box.isSetting and box.settingTyp == 1) then
                    DispoList.searchActive = not DispoList.searchActive
                    if not DispoList.searchActive then
                        DispoList.searchText = ""
                    end
                    DispoList.searchDirty = true
                end
            elseif wc == "dl_filter_" then
                if btn == Input.MOUSE_BUTTON_LEFT then
                    DispoList:toggleFilterMenu()
                end

            elseif wc == "dl_colSettings_" then
                if btn == Input.MOUSE_BUTTON_LEFT then
                    if DL_ColSettings ~= nil then
                        DL_ColSettings:toggle_guibox()
                    end
                end

            elseif wc == "dl_bgAlpha_" then
                if btn == Input.MOUSE_BUTTON_LEFT then
                    box.ownTable.bgAlphaIdx = ((box.ownTable.bgAlphaIdx or 1) % 3) + 1
                end

            elseif wc == "dl_zlFilter_" then
                if btn == Input.MOUSE_BUTTON_LEFT then
                    DispoList._zlFilterActive = not (DispoList._zlFilterActive or false)
                    DispoList:refreshDispoTable()
                    box.needsUpdate = true
                end

            elseif wc == "dl_refresh_" then
                -- L=Intervall hoeher, R=Intervall niedriger (wie Schrift/Zeilenabstand)
                local steps = {5000, 15000, 30000, 60000, 120000, 0}
                local cur = DispoList.refreshInterval or 5000
                local idx = 1
                for i, v in ipairs(steps) do
                    if v == cur then
                        idx = i
                        break
                    end
                end
                if btn == Input.MOUSE_BUTTON_LEFT then
                    idx = math.min(idx + 1, #steps)
                elseif btn == Input.MOUSE_BUTTON_RIGHT then
                    idx = math.max(idx - 1, 1)
                end
                DispoList.refreshInterval = steps[idx]
                DispoList.refreshSinceMs  = 0
                box.needsUpdate = true

            elseif wc == "dl_ware_" then
                if btn == Input.MOUSE_BUTTON_LEFT then
                    local ftName = a.clickAreaTable.ownTable and a.clickAreaTable.ownTable.ftName
                    if ftName ~= nil then
                        if DispoList.lagerViewFt == ftName then
                            DispoList.lagerViewFt = nil
                            DispoList.lagerCache[ftName] = nil
                        else
                            DispoList.lagerViewFt = ftName
                            DispoList.lagerCache[ftName] = DispoList.getLagerFuerFillType(ftName)
                        end
                        box.needsUpdate = true
                    end
                end
            end
        end
    end

    -- ── Icons zeichnen und Klick-Areas registrieren ───────────────────────────
    local function iconInArea(o)
        if o == nil then return false end
        if o.mouseInArea == nil then g_currentMission.hlUtils.setStateInArea(o) end
        return o.mouseInArea()
    end

    -- ── Alle Icons links, der Reihe nach ──────────────────────────────────────
    -- Hilfsfunktion: ein Icon zeichnen + ClickArea registrieren
    local function drawIcon(o, posX, colorKey, whereClick, infoTxt)
        if o == nil then return posX end
        g_currentMission.hlUtils.setOverlay(o, posX, iconPosY, iconW, iconH)
        g_currentMission.hlUtils.setStateInArea(o)
        local inIcon = iconInArea(o)
        local col = (type(colorKey) == "string")
            and g_currentMission.hlUtils.getColor(colorKey, true)
            or colorKey
        g_currentMission.hlUtils.setBackgroundColor(o, col)
        o:render()
        if inIcon and infoTxt and g_currentMission.hlHudSystem.infoDisplay.on then
            local ttSize = size * 0.85
            local ttW = getTextWidth(ttSize, utf8Substr(infoTxt .. "  ", 0)) * 1.1
            local ttH = getTextHeight(ttSize, utf8Substr(infoTxt, 0)) * 1.2
            g_currentMission.hlHudSystem:addTextDisplay({txt=infoTxt, maxLine=0, txtSize=ttSize,
                posX = x + (w - ttW) * 0.5,
                posY = iconLineY + lineH * 1.0})
        end
        if inArea and not g_currentMission.hlUtils:disableInArea() and whereClick then
            box:setClickArea({o.x, o.x+o.width, o.y, o.y+o.height,
                onClick=box.onSettingClick, whereClick=whereClick, typPos=args.typPos})
        end
        return posX + iconW + difW
    end

    -- Versionsanzeige: rechts in der Icon-Zeile (innerhalb der Box)
    local verStr = utf8Substr("DispoList " .. (DispoList.VERSION or "?"), 0)
    setTextAlignment(RenderText.ALIGN_RIGHT)
    setTextColor(0.45, 0.45, 0.45, 1)
    setTextBold(false)
    renderText(x + w - difW, iconLineY - size * 0.35, size * 0.7, verStr)
    setTextAlignment(RenderText.ALIGN_LEFT)

    -- Hilfsfunktion: eigenes PNG-Icon laden, zeichnen, Tooltip + Klick
    local function drawPng(key, filename, posX, activeColor, inactiveColor, whereClick, tooltip)
        if box.overlays[key] == nil then
            box.overlays[key] = Overlay.new(DispoList.modDir .. "images/" .. filename, 0, 0, iconW, iconH)
        end
        local o = box.overlays[key]
        if o == nil then return posX end
        g_currentMission.hlUtils.setOverlay(o, posX, iconPosY, iconW, iconH)
        g_currentMission.hlUtils.setStateInArea(o)
        local inIcon = iconInArea(o)
        local col = inIcon        and {0.95, 0.95, 0.95, 1.0}
                 or activeColor   or inactiveColor or {0.65, 0.65, 0.65, 1.0}
        g_currentMission.hlUtils.setBackgroundColor(o, col)
        o:render()
        if inIcon and tooltip and g_currentMission.hlHudSystem.infoDisplay.on then
            local ttSize = size * 0.85
            local ttW = getTextWidth(ttSize, utf8Substr(tooltip .. "  ", 0)) * 1.1
            local ttH = getTextHeight(ttSize, utf8Substr(tooltip, 0)) * 1.2
            g_currentMission.hlHudSystem:addTextDisplay({txt=tooltip, maxLine=0, txtSize=ttSize,
                posX = x + (w - ttW) * 0.5,
                posY = iconLineY + lineH * 1.0})
        end
        if whereClick and inArea and not g_currentMission.hlUtils:disableInArea() then
            box:setClickArea({o.x, o.x+o.width, o.y, o.y+o.height,
                onClick=box.onSettingClick, whereClick=whereClick, typPos=args.typPos})
        end
        return posX + iconW + difW
    end

    local ixPos = x + difW * 2
    if overlayDefaultGroup ~= nil then
        local zoomOn = box.ownTable.zoomActive or false

        -- 1. Filter
        local filterActive = DispoList.filterMenuOpen
        ixPos = drawPng("dl_png_filter", "icon_filter.dds", ixPos,
            filterActive and {0.1, 0.9, 0.1, 1.0} or nil,
            {0.65, 0.65, 0.65, 1.0},
            "dl_filter_", "Bereiche-Filter oeffnen/schliessen")

        -- 2. Sortierung
        local sortOn = DispoList.sortByValue
        ixPos = drawPng("dl_png_sort", "icon_sortierung.dds", ixPos,
            sortOn and {0.2, 0.8, 1.0, 1.0} or nil,
            {0.65, 0.65, 0.65, 1.0},
            "dl_sortToggle_",
            sortOn and "Sortierung: nach Erloesweert (klick fuer A-Z)"
                    or "Sortierung: A-Z (klick fuer Erloesweert)")

        -- 3. Suche
        local sActive = DispoList.searchActive
        ixPos = drawPng("dl_png_suche", "icon_suche.dds", ixPos,
            sActive and {0.2, 0.8, 1.0, 1.0} or nil,
            {0.65, 0.65, 0.65, 1.0},
            "dl_search_",
            sActive and "Suche schliessen  |  Achtung: Tasten steuern weiterhin das Fahrzeug!" or "Suche oeffnen  |  Achtung: Tasten steuern weiterhin das Fahrzeug - besser im Menue oder ausgestiegem benutzen!")

        -- Suchfeld rechts neben der Lupe
        if sActive then
            local cursor = DispoList.searchCursorVisible and "|" or " "
            local searchDisplay = DispoList.searchText .. cursor
            setTextColor(0.0, 1.0, 0.8, 1)
            setTextAlignment(RenderText.ALIGN_LEFT)
            setTextBold(false)
            renderText(ixPos, iconPosY, size, utf8Substr(searchDisplay, 0))
            ixPos = ixPos + getTextWidth(size, searchDisplay) + difW
        end

        -- 5. Zeilenabstand
        ixPos = drawPng("dl_png_zeilenabstand", "icon_zeilenabstand.dds", ixPos,
            nil, {0.65, 0.65, 0.65, 1.0},
            "dl_lineDistance_", "Zeilenabstand aendern (L=groesser / R=kleiner)")

        -- 6. Schriftgroesse
        ixPos = drawPng("dl_png_schrift", "icon_schrift.dds", ixPos,
            nil, {0.65, 0.65, 0.65, 1.0},
            "dl_zoomToggle_", "Schriftgroesse (L=groesser / R=kleiner)")

        -- 7. Einstellungen (Spalten)
        local gbOpen = DL_ColSettings ~= nil and DL_ColSettings.guiBox ~= nil and DL_ColSettings.guiBox.show
        ixPos = drawPng("dl_png_einstellungen", "icon_einstellungen.dds", ixPos,
            gbOpen and {0.2, 0.8, 1.0, 1.0} or nil,
            {0.65, 0.65, 0.65, 1.0},
            "dl_colSettings_", "Einstellungen: Spalten ein/ausschalten, Fabrikpuffer")

        -- Hintergrund-Transparenz Toggle (3 Stufen)
        local alphaIdx = box.ownTable.bgAlphaIdx or 1
        local alphaCol = alphaIdx == 1 and {0.65,0.65,0.65,1} or alphaIdx == 2 and {0.9,0.7,0.2,1} or {0.4,0.4,0.4,0.5}
        ixPos = drawPng("dl_png_bgalpha", "icon_sortierung.dds", ixPos,
            alphaIdx ~= 1 and alphaCol or nil,
            {0.65, 0.65, 0.65, 1.0},
            "dl_bgAlpha_", "Hintergrund: hell/dunkel/transparent umschalten (L-Klick)")

        -- CW only Toggle-Button (Stern-Icon)
        local zlActive = DispoList._zlFilterActive or false
        ixPos = drawPng("dl_png_zl_stern", "icon_zl_stern.dds", ixPos,
            zlActive and {0.2, 0.9, 0.2, 1.0} or nil,
            {0.65, 0.65, 0.65, 1.0},
            "dl_zlFilter_",
            DL_t("tooltip_cwonly"))

        -- Trenner |
        setTextColor(0.35, 0.35, 0.35, 1)
        local trenner = utf8Substr("|", 0)
        renderText(ixPos, iconPosY, size * 0.9, trenner)
        ixPos = ixPos + getTextWidth(size * 0.9, trenner) + difW

        -- Refresh-Icon (vorhanden) direkt vor dem Timer
        ixPos = drawPng("dl_png_refresh", "icon_refresh.dds", ixPos,
            nil, {0.65, 0.65, 0.65, 1.0},
            "dl_refresh_", "Refresh-Intervall: MouseL=hoeher / MouseR=niedriger (kuerzere Intervalle = mehr Performance-Last)")

        -- Refresh-Timer
        local sinceMs  = DispoList.refreshSinceMs or 0
        local interval = DispoList.refreshInterval or 5000
        local refreshStr
        if DispoList.sortByValue then
            refreshStr = utf8Substr(DL_t("status_pausiert"), 0)
            setTextColor(1.0, 0.6, 0.1, 1)
        elseif interval == 0 then
            refreshStr = utf8Substr(DL_t("status_manuell"), 0)
            setTextColor(0.6, 0.6, 0.6, 1)
        else
            local remainMs  = math.max(0, interval - sinceMs)
            local remainSec = math.ceil(remainMs / 1000)
            if remainSec < 60 then
                refreshStr = utf8Substr(remainSec .. "s", 0)
            else
                local m = math.floor(remainSec / 60)
                local s = remainSec - m * 60
                refreshStr = utf8Substr(m .. "m" .. string.format("%02d", s) .. "s", 0)
            end
            setTextColor(0.75, 0.75, 0.75, 1)
        end
        setTextBold(false)
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(ixPos, iconPosY + iconH * 0.22, size * 0.8, refreshStr)
    end





    -- ── ZEILE 2+3: Spaltenüberschriften (zweizeilig) ──────────────────────────
    local deltaMsg = nil
    if (DispoList.deltaNewCount or 0) > 0 then
        deltaMsg = "+" .. DispoList.deltaNewCount .. DL_t("hint_neue_waren")
    elseif DispoList._zlFilterEmpty then
        deltaMsg = DL_t("hint_zl_empty")
    elseif DispoList.CurrentItems == nil or #DispoList.CurrentItems == 0 then
        -- Warenliste komplett leer: Lagertyp-Hinweis nur wenn ein GEFUNDENER Typ ausgeschaltet ist,
        -- sonst ehrliches "kein Bestand" (kein irrefuehrender Lager-Tipp wenn eh alle an sind)
        local anyLagerOff = false
        if DispoList.foundLagertypen ~= nil and DispoList.activeLagertypen ~= nil then
            for typ, isFound in pairs(DispoList.foundLagertypen) do
                if isFound and not DispoList.activeLagertypen[typ] then
                    anyLagerOff = true
                    break
                end
            end
        end
        if anyLagerOff then
            deltaMsg = DL_t("hint_lager_check")
        else
            deltaMsg = DL_t("hint_kein_bestand")
        end
    end

    -- Y-Positionen: Icon-Zeile -> 1x -> Frei-Erklaerung -> 0.85x -> Delta (optional) -> 1x -> Spaltenkoepfe
    local freiInfoY = iconLineY - lineH * 1.0
    local deltaY = freiInfoY - lineH * 0.85
    local hdr1Y  = deltaMsg and (deltaY - lineH * 1.0) or deltaY
    local hdr2Y  = hdr1Y - lineH * 0.85

    if bgLine ~= nil then
        local bgH = deltaMsg and lineH * 4.2 or lineH * 3.2
        local bgY = hdr2Y - lineH * 0.55
        g_currentMission.hlUtils.setOverlay(bgLine, x, bgY, w, bgH)
        g_currentMission.hlUtils.setBackgroundColor(bgLine, {0.05, 0.05, 0.05, 0.95})
    end

    -- Delta-Meldungszeile
    if deltaMsg then
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextColor(1, 0.85, 0, 1)
        setTextBold(false)
        renderText(x + w * 0.5, deltaY, size * 0.85, utf8Substr(deltaMsg, 0))
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextColor(1, 1, 1, 1)
    end

    -- Zeile 2: Obere Ueberschriften — DL_t("spalte_ware") in ALDI-Groesse + Frei-Erklaerung angehaengt
    setTextColor(0.95, 0.85, 0.1, 1)
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_LEFT)
    renderText(x + difW + iconW + difW, hdr1Y, size * 1.25, utf8Substr(DL_t("spalte_ware"), 0))
    setTextBold(false)

    do
        local pufferH = math.floor((DispoList.reserveStunden or 24))
        local freiInfo = "Frei = Bestand abzueglich " .. pufferH .. "h Fabrikpuffer"
        setTextColor(0.25, 0.85, 0.25, 1)
        setTextBold(false)
        renderText(x + difW + iconW + difW, freiInfoY, size * 0.85, utf8Substr(freiInfo, 0))
        setTextColor(1, 1, 1, 1)
    end

    local vis = function(k) return DL_ColSettings == nil or DL_ColSettings:isVisible(k) end
    setTextColor(0.75, 0.75, 0.75, 1)
    setTextAlignment(RenderText.ALIGN_RIGHT)
    if vis("bestand")  then renderText(rBestand,  hdr1Y, size, utf8Substr(DL_t("spalte_bestand"), 0)) end
    if vis("frei")     then
        setTextColor(0.25, 0.85, 0.25, 1)
        renderText(rVerkauf, hdr1Y, size, utf8Substr(DL_t("spalte_frei"), 0))
        setTextColor(1, 1, 1, 1)
    end
    if vis("preis")    then renderText(rPreis,    hdr1Y, size, utf8Substr(DL_t("spalte_preis"), 0)) end
    if vis("maxPreis") then renderText(rMaxPreis, hdr1Y, size, utf8Substr("Max", 0)) end
    if vis("wert")     then renderText(rWert,     hdr1Y, size, utf8Substr(DL_t("spalte_wert"), 0)) end
    if vis("vkWert")   then
        setTextColor(0.25, 0.85, 0.25, 1)
        renderText(rVkWert, hdr1Y, size, utf8Substr(DL_t("spalte_frei_wert"), 0))
        setTextColor(0.75, 0.75, 0.75, 1)
    end
    if vis("max")      then renderText(rMax,      hdr1Y, size, utf8Substr("Max", 0)) end
    if vis("vkMax")    then
        setTextColor(0.25, 0.85, 0.25, 1)
        renderText(rVkMax, hdr1Y, size, utf8Substr(DL_t("spalte_frei_max"), 0))
        setTextColor(0.75, 0.75, 0.75, 1)
    end
    if vis("monat")    then renderText(rMonat,    hdr1Y, size, utf8Substr(DL_t("spalte_bester"), 0)) end

    -- Zeile 3: Untere Überschriften
    setTextColor(0.55, 0.55, 0.55, 1)
    setTextAlignment(RenderText.ALIGN_RIGHT)
    if vis("preis")    then renderText(rPreis,    hdr2Y, size * 0.85, utf8Substr("/1000l", 0)) end
    if vis("maxPreis") then renderText(rMaxPreis, hdr2Y, size * 0.85, utf8Substr("/1000l", 0)) end
    if vis("monat")    then renderText(rMonat,    hdr2Y, size * 0.85, utf8Substr(DL_t("spalte_monat"), 0)) end

    -- ── Datenspalten ──────────────────────────────────────────────────────────
    local nextPosY = hdr2Y - lineH * 0.7
    local scrollOffset = box.screen.bounds[1] or 1
    local lineIdx      = 0
    local curStation   = nil

    -- Kein-Zentrallager Hinweis (Multiplayer Client) — nur einmal bis User Box schliesst
    if not DispoList.zlHinweisGesehen
       and DispoList.foundZentrallager ~= nil and DispoList.foundZentrallager == 0
       and #DispoList.CurrentItems < 10 then
        setTextColor(1.0, 0.75, 0.0, 1)
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(x + difW, nextPosY, size * 0.9,
            utf8Substr("! Kein Zentrallager verfuegbar (Multiplayer)", 0))
        nextPosY = nextPosY - lineH
    end

    setTextAlignment(RenderText.ALIGN_LEFT)

    local drawLastStation = nil
    local drawLastBereich = nil

    for _, e in ipairs(DispoList.CurrentItems) do
        local stockLevel = e.stockLevel or 0
        if stockLevel >= 1 then
            local stName = e.stationName or ""
            local brName = e.bereich and e.bereich.name or ""

            -- Station-Header im Draw (nur wenn neue Station)
            if stName ~= drawLastStation then
                drawLastStation = stName
                drawLastBereich = nil
                if stName ~= "" then
                    -- Leerzeile vor Stationsheader für besseren Abstand
                    lineIdx = lineIdx + 1
                    if lineIdx >= scrollOffset and nextPosY >= y then
                        nextPosY = nextPosY - lineH * 0.5
                    end
                    lineIdx = lineIdx + 1
                    if lineIdx >= scrollOffset and nextPosY >= y then
                        -- Trennlinie über der Stationszeile
                        local bgLine = box.overlays.bgLine
                        if bgLine ~= nil then
                            g_currentMission.hlUtils.setOverlay(bgLine,
                                x + difW, nextPosY + lineH * 0.85, w - difW * 2, box.screen.pixelH)
                            g_currentMission.hlUtils.setBackgroundColor(bgLine,
                                {0.95, 0.75, 0.1, 0.6})
                            bgLine:render()
                        end
                        -- Stationsname fett gelb, größer
                        local bigSize = size * 1.15
                        setTextBold(true)
                        setTextColor(0.95, 0.75, 0.1, 1)
                        setTextAlignment(RenderText.ALIGN_LEFT)
                        renderText(x + difW, nextPosY, bigSize, utf8Substr(stName, 0))
                        -- Gesamtwert rechts neben Name, fett grün
                        local stVal = DispoList.stationValues and DispoList.stationValues[stName] or 0
                        if stVal > 0 then
                            local valTxt = utf8Substr(DL_t("filter_gesamtwert") .. " " .. fmtMon(stVal) .. " €", 0)
                            setTextBold(true)
                            setTextColor(0.1, 1.0, 0.1, 1)
                            setTextAlignment(RenderText.ALIGN_LEFT)
                            -- Position: nach Stationsname mit Abstand
                            local nameW = getTextWidth(bigSize, utf8Substr(stName, 0))
                            renderText(x + difW + nameW + difW * 3, nextPosY, bigSize, valTxt)
                        end
                        setTextBold(false)
                        nextPosY = nextPosY - lineH
                        if nextPosY < y then break end
                    end
                end
            end

            -- Bereich-Header im Draw (nur wenn neuer Bereich)
            if brName ~= drawLastBereich then
                drawLastBereich = brName
                if brName ~= "" then
                    lineIdx = lineIdx + 1
                    if lineIdx >= scrollOffset and nextPosY >= y then
                        setTextBold(false)
                        setTextColor(0.3, 0.85, 0.3, 1)
                        setTextAlignment(RenderText.ALIGN_LEFT)
                        renderText(x + difW * 3, nextPosY, size * 0.9, utf8Substr(DL_bereichLabel(brName), 0))
                        nextPosY = nextPosY - lineH
                        if nextPosY < y then break end
                    end
                end
            end

            lineIdx = lineIdx + 1
            if lineIdx >= scrollOffset and nextPosY >= y then
                do -- Waren-Eintrag
                    if e.iconOverlay ~= nil then
                        g_currentMission.hlUtils.setOverlay(e.iconOverlay, x + difW, nextPosY - iconH*0.1, iconW, iconH)
                        e.iconOverlay:render()
                    end

                    if (e.bestMonth or 0) == curM then
                        setTextColor(0.3, 0.65, 1.0, 1)
                    else
                        setTextColor(1, 1, 1, 1)
                    end
                    setTextAlignment(RenderText.ALIGN_LEFT)
                    renderText(colWareX, nextPosY, size, utf8Substr(e.title or "", 0))

                    local stockLvl = e.stockLevel or 0
                    local sellable = math.max(0, e.sellable or 0)
                    local price    = e.price    or 0
                    local maxPrice = e.maxPrice or 0
                    local vis = function(k) return DL_ColSettings == nil or DL_ColSettings:isVisible(k) end

                    setTextAlignment(RenderText.ALIGN_RIGHT)
                    if vis("bestand") then
                        setTextColor(0.70, 0.70, 0.70, 1)
                        renderText(rBestand, nextPosY, size, utf8Substr(fmtVol(stockLvl), 0))
                    end
                    if vis("frei") then
                        local hasSell = sellable > 0
                        setTextColor(hasSell and 0.25 or 0.85, hasSell and 0.85 or 0.25, 0.25, 1)
                        renderText(rVerkauf, nextPosY, size, utf8Substr(fmtVol(sellable), 0))
                    end
                    if vis("preis") then
                        setTextColor(0.85, 0.85, 0.85, 1)
                        renderText(rPreis, nextPosY, size,
                            utf8Substr(g_i18n:formatMoney(math.floor(price * 1000), 0, false) .. " €", 0))
                    end
                    if vis("maxPreis") then
                        setTextColor(1.0, 0.80, 0.0, 1)
                        renderText(rMaxPreis, nextPosY, size,
                            utf8Substr(g_i18n:formatMoney(math.floor(maxPrice * 1000), 0, false) .. " €", 0))
                    end
                    if vis("wert") then
                        setTextColor(0.70, 0.70, 0.70, 1)
                        renderText(rWert, nextPosY, size,
                            utf8Substr(fmtMon(stockLvl * price) .. " €", 0))
                    end
                    if vis("vkWert") then
                        local vkWert = sellable * price
                        setTextColor(vkWert > 0 and 0.25 or 0.85, vkWert > 0 and 0.85 or 0.25, 0.25, 1)
                        renderText(rVkWert, nextPosY, size,
                            utf8Substr(fmtMon(vkWert) .. " €", 0))
                    end
                    if vis("max") then
                        setTextColor(0.70, 0.70, 0.70, 1)
                        renderText(rMax, nextPosY, size,
                            utf8Substr(fmtMon(stockLvl * maxPrice) .. " €", 0))
                    end
                    if vis("vkMax") then
                        local vkMax = sellable * maxPrice
                        setTextColor(vkMax > 0 and 0.25 or 0.85, vkMax > 0 and 0.85 or 0.25, 0.25, 1)
                        renderText(rVkMax, nextPosY, size,
                            utf8Substr(fmtMon(vkMax) .. " €", 0))
                    end
                    if vis("monat") then
                        local bestM = e.bestMonth or 1
                        if bestM == curM then
                            setTextColor(0.0, 1.0, 1.0, 1); setTextBold(true)
                        else
                            setTextColor(0.65, 0.65, 0.65, 1); setTextBold(false)
                        end
                        renderText(rMonat, nextPosY, size, utf8Substr(g_i18n:formatPeriod(bestM, true), 0))
                        setTextBold(false)
                    end

                    -- Klick-Area für gesamte Warenzeile (Drill-Down toggle)
                    local ftName = e.ftName
                    if ftName ~= nil then
                        local isOpen = DispoList.lagerViewFt == ftName
                        if isOpen then
                            -- Markierung: kleines v vor dem Warennamen
                            setTextColor(0.2, 0.8, 1.0, 1)
                            setTextAlignment(RenderText.ALIGN_LEFT)
                            renderText(x + difW * 0.5, nextPosY, size * 0.8, utf8Substr("v", 0))
                        end
                        box:setClickArea({x, x + w, nextPosY - lineH * 0.1, nextPosY + lineH * 0.9,
                            onClick=box.onSettingClick, whereClick="dl_ware_",
                            ownTable={ftName=ftName}, typPos=args.typPos})
                    end

                    nextPosY = nextPosY - lineH

                    -- Drill-Down: Lager-Zeilen wenn diese Ware aufgeklappt
                    if ftName ~= nil and DispoList.lagerViewFt == ftName then
                        local lager = DispoList.lagerCache[ftName] or {}
                        if #lager == 0 then
                            lineIdx = lineIdx + 1
                            if lineIdx >= scrollOffset and nextPosY >= y then
                                setTextAlignment(RenderText.ALIGN_LEFT)
                                setTextColor(0.5, 0.5, 0.5, 1)
                                setTextBold(false)
                                renderText(colWareX + difW * 2, nextPosY, size,
                                    utf8Substr(DL_t("hint_kein_lager"), 0))
                                nextPosY = nextPosY - lineH
                                if nextPosY < y then break end
                            end
                        else
                            -- Dynamische Spaltenbreite: max. Namenlaenge bestimmen
                            local maxNameW = 0
                            for _, lag in ipairs(lager) do
                                local tw = getTextWidth(size, utf8Substr((lag.name or "?") .. "  ", 0))
                                if tw > maxNameW then maxNameW = tw end
                            end
                            local lagerNameX  = colWareX + difW * 2
                            local lagerMengeX = math.min(lagerNameX + maxNameW + difW, rightEdge)
                            for _, lag in ipairs(lager) do
                                lineIdx = lineIdx + 1
                                if lineIdx >= scrollOffset and nextPosY >= y then
                                    setTextAlignment(RenderText.ALIGN_LEFT)
                                    setTextColor(1, 1, 1, 1)
                                    setTextBold(false)
                                    renderText(lagerNameX, nextPosY, size,
                                        utf8Substr(lag.name or "?", 0))
                                    setTextAlignment(RenderText.ALIGN_RIGHT)
                                    setTextColor(0.70, 0.70, 0.70, 1)
                                    local capTxt
                                    if lag.capacity ~= nil and lag.capacity > 0 then
                                        capTxt = fmtVol(lag.level) .. " / " .. fmtVol(lag.capacity) .. " l"
                                    else
                                        capTxt = fmtVol(lag.level) .. " l"
                                    end
                                    renderText(math.min(lagerMengeX + getTextWidth(size, utf8Substr(capTxt .. " ", 0)), rightEdge),
                                        nextPosY, size, utf8Substr(capTxt, 0))
                                    nextPosY = nextPosY - lineH
                                    if nextPosY < y then break end
                                end
                            end
                        end
                    end
                end -- Waren-Eintrag
            end
        end
    end

    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
    setTextBold(false)
end
