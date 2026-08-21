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

-- Aufgeklappte Lager-Zeilen einer Ware/eines Materials zeichnen.
-- Gemeinsamer Helfer fuer Hauptliste (mit Scroll) und Baustellen-Ansicht (ohne Scroll),
-- damit Farben und Layout der Lager-Aufklappung nur an EINER Stelle gepflegt werden.
--   scrollOffset == nil -> Baustellen-Modus: jede Zeile wird gezeichnet (kein Scroll-Guard).
--   scrollOffset ~= nil -> Hauptlisten-Modus: Zeile nur zeichnen wenn sichtbar (lineIdx-Guard).
-- Rueckgabe: nextPosY, lineIdx, stop  (stop == true -> aufrufende Schleife soll break-en)
function DL_Display_DrawBox.renderLagerRows(ftName, nextPosY, y, lineH, size, difW, baseNameX, rightEdge, lineIdx, scrollOffset)
    local fmtVol = DL_Display_DrawBox.fmtVol
    local lager  = DispoList.lagerCache[ftName] or {}
    local scroll = (scrollOffset ~= nil)

    if #lager == 0 then
        lineIdx = lineIdx + 1
        if (not scroll) or (lineIdx >= scrollOffset and nextPosY >= y) then
            setTextAlignment(RenderText.ALIGN_LEFT)
            setTextColor(unpack(DL_Colors.grauMit)); setTextBold(false)
            renderText(baseNameX + difW * 2, nextPosY, size, utf8Substr(DL_t("hint_kein_lager"), 0))
            setTextColor(unpack(DL_Colors.white))
            nextPosY = nextPosY - lineH
            if nextPosY < y then return nextPosY, lineIdx, true end
        end
        return nextPosY, lineIdx, false
    end

    -- Dynamische Spaltenbreite: max. Namenlaenge bestimmen
    local maxNameW = 0
    for _, lag in ipairs(lager) do
        local tw = getTextWidth(size, utf8Substr((lag.name or "?") .. "  ", 0))
        if tw > maxNameW then maxNameW = tw end
    end
    local lagerNameX  = baseNameX + difW * 2
    local lagerMengeX = math.min(lagerNameX + maxNameW + difW, rightEdge)

    for _, lag in ipairs(lager) do
        lineIdx = lineIdx + 1
        if (not scroll) or (lineIdx >= scrollOffset and nextPosY >= y) then
            setTextAlignment(RenderText.ALIGN_LEFT)
            -- Lager-Zeilen im gleichen Blau wie das Aufklapp-"v" (bessere Sichtbarkeit)
            setTextColor(unpack(DL_Colors.lagerBlau)); setTextBold(false)
            renderText(lagerNameX, nextPosY, size, utf8Substr(lag.name or "?", 0))
            setTextAlignment(RenderText.ALIGN_RIGHT)
            setTextColor(unpack(DL_Colors.lagerBlau))
            local capTxt
            if lag.capacity ~= nil and lag.capacity > 0 then
                capTxt = fmtVol(lag.level) .. " / " .. fmtVol(lag.capacity) .. " l"
            else
                capTxt = fmtVol(lag.level) .. " l"
            end
            renderText(math.min(lagerMengeX + getTextWidth(size, utf8Substr(capTxt .. " ", 0)), rightEdge),
                nextPosY, size, utf8Substr(capTxt, 0))
            setTextColor(unpack(DL_Colors.white))
            nextPosY = nextPosY - lineH
            if nextPosY < y then return nextPosY, lineIdx, true end
        end
    end
    return nextPosY, lineIdx, false
end

function DL_Display_DrawBox.setBox(args)
    if args == nil or type(args) ~= "table" or args.typPos == nil or args.inArea == nil then return end
    local box = g_currentMission.hlHudSystem.box[args.typPos]
    if box == nil then return end

    if DispoList.DisplayItems == nil or #DispoList.DisplayItems == 0 then
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
    for _, e in ipairs(DispoList.DisplayItems) do
        if (e.stockLevel or 0) >= 1 then
            -- Stationsheader: Leerzeile + Header = 2 Zeilen
            if e.stationName ~= lastStation then
                lastStation = e.stationName
                lastBereich = nil
                if e.stationName ~= nil and e.stationName ~= "" then
                    totalLines = totalLines + 2  -- Leerzeile + Stationsheader
                    local stVal = DispoList.stationValues and DispoList.stationValues[e.stationName] or 0
                    if stVal > 0 then
                        totalLines = totalLines + 1  -- eigene Gesamtwert-Zeile unter dem Stationsnamen
                    end
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

    -- Baustellen-Ansicht: eigene Zeilenzahl fuer den Scroll-Bereich
    -- (Kran-Rows + Icon-Zeile + Titel + Spaltenkopf = +3)
    if DispoList.baustelleMode then
        local n = (DispoList.baustelleRows and #DispoList.baustelleRows) or 0
        if n < 1 then n = 1 end  -- sprechende Null-Zeile
        -- aufgeklapptes Material: dessen Lager-Zeilen mit in die Scrollhoehe zaehlen
        if DispoList.baustelleViewFt ~= nil then
            local lg = DispoList.lagerCache and DispoList.lagerCache[DispoList.baustelleViewFt]
            n = n + ((lg ~= nil and #lg > 0) and #lg or 1)
        end
        box.screen.bounds[4] = math.max(1, n + 3)
    end

    -- Kassetten-Shops-Ansicht: eigene Zeilenzahl (Rows + Icon-Zeile + Titel + Spaltenkopf)
    if DispoList.kassettenMode then
        local n = (DispoList.kassettenRows and #DispoList.kassettenRows) or 0
        if n < 1 then n = 1 end
        box.screen.bounds[4] = math.max(1, n + 3)
    end

    local curM = g_currentMission.environment.currentPeriod or 1

    -- Box-Hintergrund-Alpha (4 Stufen: normal, hell, transparent, dunkel)
    local bgAlphas = {0.88, 0.45, 0.12, 0.97}
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
        g_currentMission.hlUtils.setBackgroundColor(bgLine, DL_Colors.panelBg)
        bgLine:render()
    end

    local iconPosY = iconLineY - iconH * 0.5

    -- Layout-Buendel fuer den gemeinsamen Icon-Renderer (DispoList.drawHoverIcon)
    local iconGeo = {x=x, w=w, size=size, difW=difW, lineH=lineH,
                     iconW=iconW, iconH=iconH, iconPosY=iconPosY, iconLineY=iconLineY, inArea=inArea}

    -- onSettingClick Handler (einmalig registrieren)
    if box.onSettingClick == nil then
        box.ownTable.zoomActive = box.ownTable.zoomActive or false  -- Toggle-State für Zoom-Icon
        box.onSettingClick = function(a)
            if a == nil then return end
            if a.clickAreaTable == nil then return end
            local wc  = a.clickAreaTable.whereClick
            local btn = a.button
            -- dl_ware_ / dl_baumat_ feuern bei isDown=false (mouseUp), alle anderen bei isDown=true
            if wc ~= "dl_ware_" and wc ~= "dl_baumat_" and not a.isDown then return end

            -- Klick auf ein anderes Bedienelement bestaetigt die Suche (Fokus weg, Fahren frei).
            -- Nur echte, registrierte Klicks -- nicht Lupe/Suchfeld selbst.
            if DispoList.searchFocused and a.isDown
               and wc ~= "dl_search_" and wc ~= "dl_searchfield_main_" then
                DispoList.setSearchFocus(false)
            end

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
                    if DispoList.searchActive then
                        -- Nur EINE Lupe aktiv: Filter-Suche zu, damit Getippe eindeutig hier landet
                        if DispoList.resetSearch ~= nil then DispoList.resetSearch() end
                        DispoList.setSearchFocus(true)   -- Lupe auf: tippen + Fahren sperren
                    else
                        DispoList.searchText = ""
                        DispoList.setSearchFocus(false)  -- Lupe zu: Fahren frei
                    end
                    DispoList.searchDirty = true
                end
            elseif wc == "dl_searchfield_main_" then
                -- Klick aufs Suchfeld (nach Enter/Klick-weg): wieder tippen
                if btn == Input.MOUSE_BUTTON_LEFT and DispoList.searchActive then
                    DispoList.setSearchFocus(true)
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
                    box.ownTable.bgAlphaIdx = ((box.ownTable.bgAlphaIdx or 1) % 4) + 1
                end

            elseif wc == "dl_zlFilter_" then
                if btn == Input.MOUSE_BUTTON_LEFT then
                    DispoList._zlFilterActive = not (DispoList._zlFilterActive or false)
                    DispoList:refreshDispoTable()
                    box.needsUpdate = true
                end

            elseif wc == "dl_baustellen_toggle_" then
                if btn == Input.MOUSE_BUTTON_LEFT then
                    DispoList.ecEnabled = not (DispoList.ecEnabled == true)
                    DispoList:refreshDispoTable()
                    box.needsUpdate = true
                end

            elseif wc == "dl_baustelleMode_" then
                if btn == Input.MOUSE_BUTTON_LEFT then
                    DispoList.baustelleMode = not (DispoList.baustelleMode == true)
                    if DispoList.baustelleMode then DispoList.kassettenMode = false end  -- Modi schliessen sich aus
                    DispoList.baustelleViewFt = nil  -- Aufklappung beim Moduswechsel schliessen
                    box.screen.bounds[1] = 1  -- Scroll zuruecksetzen beim Moduswechsel
                    box.needsUpdate = true
                end

            elseif wc == "dl_kassettenMode_" then
                if btn == Input.MOUSE_BUTTON_LEFT then
                    DispoList.kassettenMode = not (DispoList.kassettenMode == true)
                    if DispoList.kassettenMode then DispoList.baustelleMode = false end  -- Modi schliessen sich aus
                    box.screen.bounds[1] = 1  -- Scroll zuruecksetzen beim Moduswechsel
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

            elseif wc == "dl_baumat_" then
                -- Baustellen-Ansicht: Material aufklappen -> zeigt Lager (wie Hauptliste)
                if btn == Input.MOUSE_BUTTON_LEFT then
                    local ftName = a.clickAreaTable.ownTable and a.clickAreaTable.ownTable.ftName
                    if ftName ~= nil then
                        if DispoList.baustelleViewFt == ftName then
                            DispoList.baustelleViewFt = nil
                            DispoList.lagerCache[ftName] = nil
                        else
                            DispoList.baustelleViewFt = ftName
                            DispoList.lagerCache[ftName] = DispoList.getLagerFuerFillType(ftName)
                        end
                        box.needsUpdate = true
                    end
                end
            end
        end
    end

    -- ── Icons zeichnen und Klick-Areas registrieren ───────────────────────────
    -- ── Alle Icons links, der Reihe nach ──────────────────────────────────────
    -- Versionsanzeige: rechts in der Icon-Zeile (innerhalb der Box)
    local verStr = utf8Substr("DispoList " .. (DispoList.VERSION or "?"), 0)
    setTextAlignment(RenderText.ALIGN_RIGHT)
    setTextColor(unpack(DL_Colors.grauDim))
    setTextBold(false)
    renderText(x + w - difW, iconLineY - size * 0.35, size * 0.7, verStr)
    setTextAlignment(RenderText.ALIGN_LEFT)

    -- Hilfsfunktion: eigenes PNG-Icon laden -> gemeinsamer Renderer (drawHoverIcon)
    local function drawPng(key, filename, posX, activeColor, inactiveColor, whereClick, tooltip)
        if box.overlays[key] == nil then
            box.overlays[key] = Overlay.new(DispoList.modDir .. "images/" .. filename, 0, 0, iconW, iconH)
        end
        local o = box.overlays[key]
        if o == nil then return posX end
        return DispoList.drawHoverIcon(box, args, iconGeo, o, posX, activeColor, inactiveColor, whereClick, tooltip)
    end

    local ixPos = x + difW * 2
    if overlayDefaultGroup ~= nil then
        local zoomOn = box.ownTable.zoomActive or false

        -- 1. Filter
        local filterActive = DispoList.filterMenuOpen
        ixPos = drawPng("dl_png_filter", "icon_filter.dds", ixPos,
            filterActive and DL_Colors.iconActiveGreen or nil,
            DL_Colors.iconIdle,
            "dl_filter_", DL_t("tooltip_bereichefilter"))

        -- 2. Sortierung
        local sortOn = DispoList.sortByValue
        ixPos = drawPng("dl_png_sort", "icon_sortierung.dds", ixPos,
            sortOn and DL_Colors.iconActive or nil,
            DL_Colors.iconIdle,
            "dl_sortToggle_",
            sortOn and DL_t("tooltip_sort_byvalue")
                    or DL_t("tooltip_sort_byname"))

        -- 3. Suche
        local sActive = DispoList.searchActive
        ixPos = drawPng("dl_png_suche", "icon_suche.dds", ixPos,
            sActive and DL_Colors.iconActive or nil,
            DL_Colors.iconIdle,
            "dl_search_",
            sActive and DL_t("tooltip_search_close") or DL_t("tooltip_search_open"))

        -- Suchfeld rechts neben der Lupe (gemeinsamer Renderer, siehe DispoList.renderSearchField)
        if sActive then
            ixPos = DispoList.renderSearchField(box, args.typPos, ixPos, iconPosY, iconH, size, difW,
                bgLine, inArea, DispoList.searchText, DispoList.searchCursorVisible, "dl_searchfield_main_")
        end

        -- 5. Zeilenabstand
        ixPos = drawPng("dl_png_zeilenabstand", "icon_zeilenabstand.dds", ixPos,
            nil, DL_Colors.iconIdle,
            "dl_lineDistance_", DL_t("tooltip_linedistance"))

        -- 6. Schriftgroesse
        ixPos = drawPng("dl_png_schrift", "icon_schrift.dds", ixPos,
            nil, DL_Colors.iconIdle,
            "dl_zoomToggle_", DL_t("tooltip_fontsize"))

        -- 7. Einstellungen (Spalten)
        local gbOpen = DL_ColSettings ~= nil and DL_ColSettings.guiBox ~= nil and DL_ColSettings.guiBox.show
        ixPos = drawPng("dl_png_einstellungen", "icon_einstellungen.dds", ixPos,
            gbOpen and DL_Colors.iconActive or nil,
            DL_Colors.iconIdle,
            "dl_colSettings_", DL_t("tooltip_settings"))

        -- Hintergrund-Transparenz Toggle (4 Stufen: normal, hell, transparent, dunkel)
        local alphaIdx = box.ownTable.bgAlphaIdx or 1
        local alphaCol = alphaIdx == 1 and DL_Colors.iconIdle
                      or alphaIdx == 2 and DL_Colors.gold
                      or alphaIdx == 3 and {0.4,0.4,0.4,0.5}
                      or DL_Colors.lagerBlau
        ixPos = drawPng("dl_png_bgalpha", "icon_sortierung.dds", ixPos,
            alphaIdx ~= 1 and alphaCol or nil,
            DL_Colors.iconIdle,
            "dl_bgAlpha_", DL_t("tooltip_bgalpha"))

        -- CW only Toggle-Button (Stern-Icon)
        local zlActive = DispoList._zlFilterActive or false
        ixPos = drawPng("dl_png_zl_stern", "icon_zl_stern.dds", ixPos,
            zlActive and DL_Colors.iconActiveGreen or nil,
            DL_Colors.iconIdle,
            "dl_zlFilter_",
            DL_t("tooltip_cwonly"))

        -- Baustellen-Ansicht Toggle (Kran-Icon) -- immer sichtbar, sprechende Null
        -- uebernimmt den Leerzustand (Entscheidung 20.07.)
        local bmActive = DispoList.baustelleMode == true
        ixPos = drawPng("dl_png_baustelle", "icon_baustelle.dds", ixPos,
            bmActive and DL_Colors.iconActiveGreen or nil,
            DL_Colors.iconIdle,
            "dl_baustelleMode_",
            DL_t("tooltip_baustellemode"))

        -- Kassetten-Shops-Ansicht Toggle (Geldkassette). Aktiv-Farbe = Baustellen-
        -- Orange (limitierte Annahme, kein echter Markt) statt Gruen.
        local kmActive = DispoList.kassettenMode == true
        ixPos = drawPng("dl_png_kassette", "icon_kassette.dds", ixPos,
            kmActive and DL_Colors.bauLimit or nil,
            DL_Colors.iconIdle,
            "dl_kassettenMode_",
            DL_t("tooltip_kassettenmode"))

        -- Trenner |
        setTextColor(unpack(DL_Colors.trenner))
        local trenner = utf8Substr("|", 0)
        renderText(ixPos, iconPosY, size * 0.9, trenner)
        ixPos = ixPos + getTextWidth(size * 0.9, trenner) + difW

        -- Refresh-Icon (vorhanden) direkt vor dem Timer
        ixPos = drawPng("dl_png_refresh", "icon_refresh.dds", ixPos,
            nil, DL_Colors.iconIdle,
            "dl_refresh_", DL_t("tooltip_refresh"))

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
            setTextColor(unpack(DL_Colors.grauHell))
        end
        setTextBold(false)
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(ixPos, iconPosY + iconH * 0.22, size * 0.8, refreshStr)
    end

    -- ══ BAUSTELLEN-ANSICHT (Kran-Toggle) ════════════════════════════════════
    -- Ersetzt die komplette Verkaufsliste durch eine reine Bedarfsliste:
    -- pro Baustelle ein Block, je Material eine Zeile "Name / braucht / im Lager".
    -- Kein Prozent, kein Stern, kein Drill-In (bewusst schlank, Entscheidung 20.07.).
    if DispoList.baustelleMode then
        local rows     = DispoList.baustelleRows or {}
        local numW     = getTextWidth(size, utf8Substr(g_i18n:formatVolume(9999999, 0), 0)) + gap
        local rLager   = x + w - difW * 1.5
        local rBraucht = rLager - numW - gap
        local nameX    = x + difW * 2.2

        -- Titelzeile
        local titY = iconLineY - lineH * 1.15
        setTextColor(unpack(DL_Colors.gold)); setTextBold(true)
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(x + difW, titY, size * 1.25, utf8Substr(DL_t("baustelle_titel"), 0))
        setTextBold(false)

        -- Spaltenkoepfe (braucht / im Lager)
        local hY = titY - lineH * 1.0
        setTextColor(unpack(DL_Colors.grauHell))
        setTextAlignment(RenderText.ALIGN_RIGHT)
        renderText(rBraucht, hY, size, utf8Substr(DL_t("spalte_braucht"), 0))
        renderText(rLager,   hY, size, utf8Substr(DL_t("spalte_imlager"), 0))
        setTextColor(unpack(DL_Colors.white))

        local nextPosY   = hY - lineH * 0.8
        local scrollOffB = box.screen.bounds[1] or 1
        local lineIdxB   = 0

        if #rows == 0 then
            setTextAlignment(RenderText.ALIGN_CENTER)
            setTextColor(unpack(DL_Colors.gold)); setTextBold(false)
            renderText(x + w * 0.5, nextPosY, size * 0.95, utf8Substr(DL_t("baustelle_leer"), 0))
            setTextAlignment(RenderText.ALIGN_LEFT); setTextColor(unpack(DL_Colors.white))
            return
        end

        for _, r in ipairs(rows) do
            lineIdxB = lineIdxB + 1
            if lineIdxB >= scrollOffB and nextPosY >= y then
                if r.kind == "proj" then
                    local bg = box.overlays.bgLine
                    if bg ~= nil then
                        g_currentMission.hlUtils.setOverlay(bg, x + difW, nextPosY + lineH * 0.85, w - difW * 2, box.screen.pixelH)
                        g_currentMission.hlUtils.setBackgroundColor(bg, {0.95, 0.85, 0.1, 0.6})
                        bg:render()
                    end
                    setTextBold(true); setTextColor(unpack(DL_Colors.gold))
                    setTextAlignment(RenderText.ALIGN_LEFT)
                    renderText(x + difW, nextPosY, size * 1.15, utf8Substr(r.name or "?", 0))
                    setTextBold(false); setTextColor(unpack(DL_Colors.white))
                    nextPosY = nextPosY - lineH
                    if nextPosY < y then break end
                else
                    local enough = (r.stock or 0) >= (r.needed or 0)
                    local isOpen = (r.ftName ~= nil and DispoList.baustelleViewFt == r.ftName)
                    -- Aufklapp-Markierung (kleines v) links vom Namen wenn offen
                    if isOpen then
                        setTextColor(unpack(DL_Colors.lagerBlau))
                        setTextAlignment(RenderText.ALIGN_LEFT)
                        renderText(x + difW * 0.7, nextPosY, size * 0.8, utf8Substr("v", 0))
                    end
                    setTextAlignment(RenderText.ALIGN_LEFT)
                    -- Warenname gruen sobald genug im Lager, sonst weiss (wie die Lager-Zahl)
                    if enough then setTextColor(unpack(DL_Colors.gruen)) else setTextColor(unpack(DL_Colors.white)) end
                    renderText(nameX, nextPosY, size, utf8Substr(r.name or "?", 0))
                    setTextAlignment(RenderText.ALIGN_RIGHT)
                    setTextColor(unpack(DL_Colors.gold))
                    renderText(rBraucht, nextPosY, size, utf8Substr(fmtVol(r.needed or 0), 0))
                    setTextColor(enough and 0.1 or 0.95, enough and 1.0 or 0.55, 0.1, 1)
                    renderText(rLager, nextPosY, size, utf8Substr(fmtVol(r.stock or 0), 0))
                    setTextColor(unpack(DL_Colors.white))
                    -- Klick-Area ueber die ganze Materialzeile -> Lager auf/zuklappen
                    if r.ftName ~= nil and inArea and not g_currentMission.hlUtils:disableInArea() then
                        box:setClickArea({x, x + w, nextPosY - lineH * 0.1, nextPosY + lineH * 0.9,
                            onClick=box.onSettingClick, whereClick="dl_baumat_",
                            ownTable={ftName=r.ftName}, typPos=args.typPos})
                    end
                    nextPosY = nextPosY - lineH
                    if nextPosY < y then break end

                    -- Drill-Down: Lager-Zeilen wenn dieses Material aufgeklappt (wie Hauptliste)
                    if isOpen then
                        local stop
                        nextPosY, lineIdxB, stop = DL_Display_DrawBox.renderLagerRows(
                            r.ftName, nextPosY, y, lineH, size, difW, nameX, rLager, lineIdxB, nil)
                        if stop then break end
                    end
                end
            end
        end
        setTextBold(false); setTextAlignment(RenderText.ALIGN_LEFT); setTextColor(unpack(DL_Colors.white))
        return
    end

    -- ══ KASSETTEN-SHOPS-ANSICHT (Geldkassette-Toggle) ═══════════════════════════
    -- Produktionsstellen mit CASH-Output: pro Shop ein Block mit Status, darunter
    -- die angenommenen Waren mit "passt noch rein" (freie Kapazitaet). Schlank wie
    -- die Baustellen-Ansicht.
    if DispoList.kassettenMode then
        local rows   = DispoList.kassettenRows or {}
        local numW   = getTextWidth(size, utf8Substr(fmtVol(9999999), 0)) + gap
        local rFrei  = x + w - difW * 1.5
        local rVerf  = rFrei - numW - gap
        local nameX  = x + difW * 2.2

        local titY = iconLineY - lineH * 1.15
        setTextColor(unpack(DL_Colors.bauLimit)); setTextBold(true)
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(x + difW, titY, size * 1.25, utf8Substr(DL_t("kassetten_titel"), 0))
        setTextBold(false)

        local hY = titY - lineH * 1.0
        setTextColor(unpack(DL_Colors.grauHell))
        setTextAlignment(RenderText.ALIGN_RIGHT)
        renderText(rVerf, hY, size, utf8Substr(DL_t("kassetten_kopf_verf"), 0))
        renderText(rFrei, hY, size, utf8Substr(DL_t("kassetten_kopf_frei"), 0))
        setTextColor(unpack(DL_Colors.white))

        local nextPosY = hY - lineH * 0.8
        local scrollK  = box.screen.bounds[1] or 1
        local lineIdxK = 0

        if #rows == 0 then
            setTextAlignment(RenderText.ALIGN_CENTER)
            setTextColor(unpack(DL_Colors.bauLimit)); setTextBold(false)
            renderText(x + w * 0.5, nextPosY, size * 0.95, utf8Substr(DL_t("kassetten_leer_hint"), 0))
            setTextAlignment(RenderText.ALIGN_LEFT); setTextColor(unpack(DL_Colors.white))
            return
        end

        local function statusTxtCol(st)
            if st == "leer" then return DL_t("kassetten_st_leer"), DL_Colors.rot end
            if st == "voll" then return DL_t("kassetten_st_voll"), DL_Colors.bauLimit end
            if st == "run"  then return DL_t("kassetten_st_run"),  DL_Colors.gruen end
            return DL_t("kassetten_st_idle"), DL_Colors.grauMit
        end

        for _, r in ipairs(rows) do
            lineIdxK = lineIdxK + 1
            if lineIdxK >= scrollK and nextPosY >= y then
                if r.kind == "shop" then
                    local bg = box.overlays.bgLine
                    if bg ~= nil then
                        g_currentMission.hlUtils.setOverlay(bg, x + difW, nextPosY + lineH * 0.85, w - difW * 2, box.screen.pixelH)
                        g_currentMission.hlUtils.setBackgroundColor(bg, {1.0, 0.55, 0.1, 0.55})
                        bg:render()
                    end
                    setTextBold(true); setTextColor(unpack(DL_Colors.bauLimit))
                    setTextAlignment(RenderText.ALIGN_LEFT)
                    renderText(x + difW, nextPosY, size * 1.15, utf8Substr(r.name or "?", 0))
                    -- Status rechts
                    local stTxt, stCol = statusTxtCol(r.status)
                    setTextAlignment(RenderText.ALIGN_RIGHT); setTextColor(unpack(stCol))
                    renderText(rFrei, nextPosY, size * 0.95, utf8Substr(stTxt, 0))
                    setTextBold(false); setTextColor(unpack(DL_Colors.white))
                    nextPosY = nextPosY - lineH
                    if nextPosY < y then break end
                else
                    -- Fuellstand-Ampel: leer (Bestand 0) = rot + oben (der "Eingang
                    -- leer"-Ausloeser), fast leer (<25%) = orange, voll (nichts zu
                    -- liefern) = grau, sonst weiss/gold. Zahl = zu liefern (bis voll).
                    local isEmpty = (r.level ~= nil and r.level <= 0)
                    local isLow   = (not isEmpty) and (r.frac ~= nil and r.frac < 0.25)
                    local isFull  = (r.free or 0) <= 0
                    local nameCol, numCol
                    if isEmpty then       nameCol = DL_Colors.rot;      numCol = DL_Colors.rot
                    elseif isLow then     nameCol = DL_Colors.bauLimit; numCol = DL_Colors.bauLimit
                    elseif isFull then    nameCol = DL_Colors.grauMit;  numCol = DL_Colors.grauMit
                    else                  nameCol = DL_Colors.white;    numCol = DL_Colors.gold end
                    setTextAlignment(RenderText.ALIGN_LEFT); setTextColor(unpack(nameCol))
                    renderText(nameX, nextPosY, size, utf8Substr(r.name or "?", 0))
                    setTextAlignment(RenderText.ALIGN_RIGHT)
                    -- frei (Bestand - Fabrikpuffer ohne die Kassetten-Shops selbst):
                    -- gruen wenn vorhanden, sonst grau -- es IST der Frei-Wert, darum
                    -- gruen wie in der Hauptliste.
                    setTextColor(unpack((r.avail or 0) > 0 and DL_Colors.gruen or DL_Colors.grauMit))
                    renderText(rVerf, nextPosY, size, utf8Substr(fmtVol(r.avail or 0), 0))
                    -- liefern (Tank-Platz) mit Fuellstand-Ampel
                    setTextColor(unpack(numCol))
                    local freeTxt = (r.free == math.huge) and "-" or fmtVol(r.free or 0)
                    renderText(rFrei, nextPosY, size, utf8Substr(freeTxt, 0))
                    setTextColor(unpack(DL_Colors.white))
                    nextPosY = nextPosY - lineH
                    if nextPosY < y then break end
                end
            end
        end
        setTextBold(false); setTextAlignment(RenderText.ALIGN_LEFT); setTextColor(unpack(DL_Colors.white))
        return
    end





    -- ── ZEILE 2+3: Spaltenüberschriften (zweizeilig) ──────────────────────────
    local deltaMsg = nil
    if (DispoList.deltaNewCount or 0) > 0 then
        deltaMsg = "+" .. DispoList.deltaNewCount .. DL_t("hint_neue_waren")
    elseif DispoList._zlFilterEmpty then
        deltaMsg = DL_t("hint_zl_empty")
    elseif DispoList.DisplayItems == nil or #DispoList.DisplayItems == 0 then
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
    -- Wenn EC installiert: zusaetzliche Label-Zeile "Fabrikpuffer / Baustelle" ueber der
    -- Frei-Erklaerung -- alles darunter rutscht automatisch eine Zeile weiter runter.
    local ecInstalled = g_currentMission ~= nil and g_currentMission.ecProjectManager ~= nil
    local ecExtraY    = ecInstalled and lineH or 0
    local baustellenLabelY = iconLineY - lineH * 1.0  -- nur gerendert wenn ecInstalled
    local freiInfoY = iconLineY - lineH * 1.0 - ecExtraY
    local deltaY = freiInfoY - lineH * 0.85
    local hdr1Y  = deltaMsg and (deltaY - lineH * 1.0) or deltaY
    local hdr2Y  = hdr1Y - lineH * 0.85

    if bgLine ~= nil then
        local bgH = (deltaMsg and lineH * 4.2 or lineH * 3.2) + ecExtraY
        local bgY = hdr2Y - lineH * 0.55
        g_currentMission.hlUtils.setOverlay(bgLine, x, bgY, w, bgH)
        g_currentMission.hlUtils.setBackgroundColor(bgLine, {0.05, 0.05, 0.05, 0.95})
    end

    -- Delta-Meldungszeile
    if deltaMsg then
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextColor(unpack(DL_Colors.gold))
        setTextBold(false)
        renderText(x + w * 0.5, deltaY, size * 0.85, utf8Substr(deltaMsg, 0))
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextColor(unpack(DL_Colors.white))
    end

    -- Zeile 2: Obere Ueberschriften — DL_t("spalte_ware") in ALDI-Groesse + Frei-Erklaerung angehaengt
    setTextColor(unpack(DL_Colors.gold))
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_LEFT)
    renderText(x + difW + iconW + difW, hdr1Y, size * 1.25, utf8Substr(DL_t("spalte_ware"), 0))
    setTextBold(false)

    do
        if ecInstalled then
            setTextColor(0.55, 0.55, 0.55, 1)
            setTextBold(false)
            renderText(x + difW + iconW + difW, baustellenLabelY, size * 0.7, utf8Substr(DL_t("label_fabrikpuffer_baustelle"), 0))
            setTextColor(unpack(DL_Colors.white))
        end

        local pufferH = math.floor((DispoList.reserveStunden or 24))
        local freiInfo = string.format(DL_t("freiinfo_base"), pufferH)
        if ecInstalled and DispoList.ecEnabled then
            freiInfo = freiInfo .. DL_t("freiinfo_ecsuffix")
        end
        setTextColor(unpack(DL_Colors.gruen))
        setTextBold(false)
        renderText(x + difW + iconW + difW, freiInfoY, size * 0.85, utf8Substr(freiInfo, 0))
        setTextColor(unpack(DL_Colors.white))

        -- Nur klickbar wenn EC installiert -- togglet DispoList.ecEnabled (1:1 Muster wie dl_zlFilter_)
        if ecInstalled and inArea and not g_currentMission.hlUtils:disableInArea() then
            box:setClickArea({x, x + w, freiInfoY - lineH * 0.1, freiInfoY + lineH * 0.9,
                onClick=box.onSettingClick, whereClick="dl_baustellen_toggle_", typPos=args.typPos})
        end
    end

    local vis = function(k) return DL_ColSettings == nil or DL_ColSettings:isVisible(k) end
    setTextColor(unpack(DL_Colors.grauHell))
    setTextAlignment(RenderText.ALIGN_RIGHT)
    if vis("bestand")  then renderText(rBestand,  hdr1Y, size, utf8Substr(DL_t("spalte_bestand"), 0)) end
    if vis("frei")     then
        setTextColor(unpack(DL_Colors.gruen))
        renderText(rVerkauf, hdr1Y, size, utf8Substr(DL_t("spalte_frei"), 0))
        setTextColor(unpack(DL_Colors.white))
    end
    if vis("preis")    then renderText(rPreis,    hdr1Y, size, utf8Substr(DL_t("spalte_preis"), 0)) end
    if vis("maxPreis") then renderText(rMaxPreis, hdr1Y, size, utf8Substr("Max", 0)) end
    if vis("wert")     then renderText(rWert,     hdr1Y, size, utf8Substr(DL_t("spalte_wert"), 0)) end
    if vis("vkWert")   then
        setTextColor(unpack(DL_Colors.gruen))
        renderText(rVkWert, hdr1Y, size, utf8Substr(DL_t("spalte_frei_wert"), 0))
        setTextColor(unpack(DL_Colors.grauHell))
    end
    if vis("max")      then renderText(rMax,      hdr1Y, size, utf8Substr("Max", 0)) end
    if vis("vkMax")    then
        setTextColor(unpack(DL_Colors.gruen))
        renderText(rVkMax, hdr1Y, size, utf8Substr(DL_t("spalte_frei_max"), 0))
        setTextColor(unpack(DL_Colors.grauHell))
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
       and #DispoList.DisplayItems < 10 then
        setTextColor(unpack(DL_Colors.gold))
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(x + difW, nextPosY, size * 0.9,
            utf8Substr("! Kein Zentrallager verfuegbar (Multiplayer)", 0))
        nextPosY = nextPosY - lineH
    end

    setTextAlignment(RenderText.ALIGN_LEFT)

    local drawLastStation = nil
    local drawLastBereich = nil

    for _, e in ipairs(DispoList.DisplayItems) do
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
                                {0.95, 0.85, 0.1, 0.6})
                            bgLine:render()
                        end
                        -- Stationsname fett, größer. Baustelle/Lager-Station (limitierte
                        -- Annahme, kein echter Markt) -> orange statt gold (Filter A+).
                        local bigSize = size * 1.15
                        local isLimited = DispoList.stationLimited ~= nil and DispoList.stationLimited[stName] == true
                        setTextBold(true)
                        setTextColor(unpack(isLimited and DL_Colors.bauLimit or DL_Colors.gold))
                        setTextAlignment(RenderText.ALIGN_LEFT)
                        renderText(x + difW, nextPosY, bigSize, utf8Substr(stName, 0))
                        setTextBold(false)
                        nextPosY = nextPosY - lineH
                        if nextPosY < y then break end

                        -- Gesamtwert auf eigener Zeile unter dem Stationsnamen, fett grün
                        -- (schmalere Box möglich, da nicht mehr neben dem Namen)
                        local stVal = DispoList.stationValues and DispoList.stationValues[stName] or 0
                        if stVal > 0 then
                            lineIdx = lineIdx + 1
                            if lineIdx >= scrollOffset and nextPosY >= y then
                                local valTxt = utf8Substr(DL_t("filter_gesamtwert") .. " " .. fmtMon(stVal) .. " €", 0)
                                setTextBold(true)
                                setTextColor(unpack(DL_Colors.gruen))
                                setTextAlignment(RenderText.ALIGN_LEFT)
                                renderText(x + difW, nextPosY, bigSize, valTxt)
                                setTextBold(false)
                                nextPosY = nextPosY - lineH
                                if nextPosY < y then break end
                            end
                        end
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
                        setTextColor(unpack(DL_Colors.gruen))
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
                        setTextColor(0.0, 1.0, 1.0, 1)
                    else
                        setTextColor(unpack(DL_Colors.white))
                    end
                    setTextAlignment(RenderText.ALIGN_LEFT)
                    renderText(colWareX, nextPosY, size, utf8Substr(e.title or "", 0))

                    local stockLvl = e.stockLevel or 0
                    local sellable = math.max(0, e.sellable or 0)
                    -- Mengen-Deckel (Filter A+): an einer Baustelle/Lager-Station laesst sich
                    -- nur bis zur freien Kapazitaet abladen -> Frei/Frei-Wert entsprechend
                    -- deckeln. Echte Maerkte liefern huge -> unveraendert.
                    local eFreeCap = e.freeCap or math.huge
                    if eFreeCap < sellable then sellable = eFreeCap end
                    local price    = e.price    or 0
                    local maxPrice = e.maxPrice or 0
                    local vis = function(k) return DL_ColSettings == nil or DL_ColSettings:isVisible(k) end

                    setTextAlignment(RenderText.ALIGN_RIGHT)
                    if vis("bestand") then
                        setTextColor(unpack(DL_Colors.grau))
                        renderText(rBestand, nextPosY, size, utf8Substr(fmtVol(stockLvl), 0))
                    end
                    if vis("frei") then
                        local hasSell = sellable > 0
                        setTextColor(unpack(hasSell and DL_Colors.gruen or DL_Colors.rot))
                        renderText(rVerkauf, nextPosY, size, utf8Substr(fmtVol(sellable), 0))
                    end
                    if vis("preis") then
                        setTextColor(0.85, 0.85, 0.85, 1)
                        renderText(rPreis, nextPosY, size,
                            utf8Substr(g_i18n:formatMoney(math.floor(price * 1000), 0, false) .. " €", 0))
                    end
                    if vis("maxPreis") then
                        setTextColor(unpack(DL_Colors.gold))
                        renderText(rMaxPreis, nextPosY, size,
                            utf8Substr(g_i18n:formatMoney(math.floor(maxPrice * 1000), 0, false) .. " €", 0))
                    end
                    if vis("wert") then
                        setTextColor(unpack(DL_Colors.grau))
                        renderText(rWert, nextPosY, size,
                            utf8Substr(fmtMon(stockLvl * price) .. " €", 0))
                    end
                    if vis("vkWert") then
                        local vkWert = sellable * price
                        setTextColor(unpack(vkWert > 0 and DL_Colors.gruen or DL_Colors.rot))
                        renderText(rVkWert, nextPosY, size,
                            utf8Substr(fmtMon(vkWert) .. " €", 0))
                    end
                    if vis("max") then
                        setTextColor(unpack(DL_Colors.grau))
                        renderText(rMax, nextPosY, size,
                            utf8Substr(fmtMon(stockLvl * maxPrice) .. " €", 0))
                    end
                    if vis("vkMax") then
                        local vkMax = sellable * maxPrice
                        setTextColor(unpack(vkMax > 0 and DL_Colors.gruen or DL_Colors.rot))
                        renderText(rVkMax, nextPosY, size,
                            utf8Substr(fmtMon(vkMax) .. " €", 0))
                    end
                    if vis("monat") then
                        local bestM = e.bestMonth or 1
                        if bestM == curM then
                            setTextColor(0.0, 1.0, 1.0, 1); setTextBold(true)
                        else
                            setTextColor(unpack(DL_Colors.grau65)); setTextBold(false)
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
                            setTextColor(unpack(DL_Colors.lagerBlau))
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
                        local stop
                        nextPosY, lineIdx, stop = DL_Display_DrawBox.renderLagerRows(
                            ftName, nextPosY, y, lineH, size, difW, colWareX, rightEdge, lineIdx, scrollOffset)
                        if stop then break end
                    end
                end -- Waren-Eintrag
            end
        end
    end

    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(unpack(DL_Colors.white))
    setTextBold(false)
end
