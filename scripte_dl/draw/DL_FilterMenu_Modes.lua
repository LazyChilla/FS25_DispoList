--
-- FS25 DispoList - Filter-Box Draw: Modus-Ansichten (aus DL_FilterMenu_Draw.lua ausgelagert)
-- Bereich-Definition / Stations-Filter / Zusatzabnahme. Methoden am globalen
-- DL_FilterMenu_Draw-Table (in DL_FilterMenu_Draw.lua erzeugt, das VOR dieser
-- Datei ge-source()t wird). Aufruf zur Laufzeit aus setBox -> Definitionsort egal.
--

function DL_FilterMenu_Draw.drawBereichMode(x, y, w, h, col2X, colW, listStart, listTop, size, lineH, difW, bgLine, scrollOffset, fOvGroup, fOvByName)
    -- Linke Spalte: "+ Neuer Bereich" ganz oben, dann alphabetisch, Unverkaeuflich/Sonstiges immer unten
    local bereiche = {}
    for _, b in ipairs(DL_FilterMenu_Draw.getSortedBereichNames()) do
        bereiche[#bereiche + 1] = {name = b.name, order = b.order}
    end
    -- Unverkaeuflich und Sonstiges immer ans Ende
    for _, special in ipairs({"Unverkaeuflich", "Sonstiges"}) do
        if DispoList.BEREICHE[special] ~= nil then
            table.insert(bereiche, {name=special, order=99})
        end
    end
    table.insert(bereiche, {name="Sonstiges", order=99})

    local scrollL = DispoList.filterLeftScroll or 1
    local lineIdx = 0
    local posY    = listStart

    -- Erste Zeile: "+ Neuer Bereich" Button
    lineIdx = lineIdx + 1
    if lineIdx >= scrollL and posY >= y + lineH then
        local isNeuHov = not g_currentMission.hlUtils.dragDrop.on
            and g_currentMission.hlUtils.isMouseCursor
            and g_currentMission.hlUtils.mouseIsInArea(nil, nil,
                x+difW*0.3, x+colW-difW*0.3, posY-lineH*0.4, posY+lineH*0.6)
        if bgLine ~= nil then
            g_currentMission.hlUtils.setOverlay(bgLine, x+difW*0.3, posY-lineH*0.4, colW-difW*0.6, lineH)
            g_currentMission.hlUtils.setBackgroundColor(bgLine,
                isNeuHov and {0.05,0.35,0.05,1} or {0.03,0.15,0.03,0.85})
        end
        setTextColor(unpack(DL_Colors.gruenHead))
        setTextBold(true)
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(x + difW, posY, size * 0.95, utf8Substr(DL_t("btn_neuer_bereich"), 0))
        setTextBold(false)
        table.insert(DispoList.filterLeftAreas, {
            key = "__neu__",
            x1=x+difW*0.3, y1=posY-lineH*0.4, x2=x+colW-difW*0.3, y2=posY+lineH*0.6
        })
        posY = posY - lineH
    end

    for _, ber in ipairs(bereiche) do
        lineIdx = lineIdx + 1
        if lineIdx >= scrollL and posY >= y + lineH then
            local isSel = (DispoList.filterSelBereich == ber.name)
            -- Zähle zugeordnete FillTypes für diesen Bereich
            local count = 0
            if DL_Filter.bereichZuordnung ~= nil and DL_Filter.bereichZuordnung[ber.name] ~= nil then
                for _ in pairs(DL_Filter.bereichZuordnung[ber.name]) do count = count + 1 end
            end
            -- Click-Select Highlight: selektierter FillType wartet auf Ziel
            local isDropTarget = DispoList.dlSelectedFt ~= nil
            local areaX1, areaY1 = x+difW*0.3, posY-lineH*0.4
            local areaX2, areaY2 = x+colW-difW*0.3, posY+lineH*0.6
            local isHovered = isDropTarget
                and not g_currentMission.hlUtils.dragDrop.on
                and g_currentMission.hlUtils.isMouseCursor
                and g_currentMission.hlUtils.mouseIsInArea(nil, nil, areaX1, areaX2, areaY1, areaY2)
            if bgLine ~= nil then
                g_currentMission.hlUtils.setOverlay(bgLine, x+difW*0.3, posY-lineH*0.4, colW-difW*0.6, lineH)
                local bgCol = isHovered    and {0.0,0.40,0.85,1}
                           or isDropTarget and {0.05,0.30,0.05,0.95}
                           or isSel        and DL_Colors.rowSel
                           or                  DL_Colors.rowBg
                g_currentMission.hlUtils.setBackgroundColor(bgLine, bgCol)
            end
            local label = DL_bereichLabel(ber.name)
            local tc = isHovered    and {0.0, 0.75, 1.0, 1}
                    or isDropTarget and {0.0, 1.0, 0.2, 1}
                    or isSel        and DL_Colors.gold
                    or                  {0.8, 0.8,  0.8, 1}
            setTextColor(table.unpack(tc))
            setTextBold(isSel)
            setTextAlignment(RenderText.ALIGN_LEFT)
            renderText(x + difW, posY, size * 1.0, utf8Substr(label, 0))
            setTextBold(false)
            table.insert(DispoList.filterLeftAreas, {
                key=ber.name,
                x1=x+difW*0.3, y1=posY-lineH*0.4, x2=x+colW-difW*0.3, y2=posY+lineH*0.6
            })
            posY = posY - lineH
        end
    end

    -- Rechte Spalte: FillType-Pool für gewählten Bereich
    if DispoList.filterSelBereich == nil then
        setTextColor(unpack(DL_Colors.grauDim))
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(col2X + difW, listTop - lineH * 1.8, size * 0.85, utf8Substr(DL_t("filter_bereich_hint"), 0))
        return 0
    end

    local pool = DL_FilterMenu_Draw.getPoolForBereich(DispoList.filterSelBereich)
    local posYR   = listStart
    local lineIdxR = 0

    -- Mehrspalten-Layout: Spaltenbreite nach längstem Titel (gecacht bei Bereich-Wechsel)
    local rightW = w - colW
    if DL_FilterMenu_Draw._poolColW == nil or DL_FilterMenu_Draw._poolColWBereich ~= DispoList.filterSelBereich then
        local maxW = 0
        for _, item in ipairs(pool) do
            local tw = getTextWidth(size * 0.85, utf8Substr(item.title .. "  ", 0))
            if tw > maxW then maxW = tw end
        end
        local dotSize = lineH * 0.55 + difW * 2
        DL_FilterMenu_Draw._poolColW = math.max(dotSize + maxW, lineH * 6)
        DL_FilterMenu_Draw._poolColWBereich = DispoList.filterSelBereich
    end
    local ftColW      = DL_FilterMenu_Draw._poolColW
    local numCols     = math.max(1, math.floor(rightW / ftColW))
    local colWft      = rightW / numCols
    local rowsPerCol  = math.ceil(#pool / numCols)
    -- Seitengrösse = eine "Seite" = rowsPerCol Zeilen (alle Spalten zusammen)
    -- scrollOffset ist Zeilennummer (1-basiert), wir überspringen (scrollOffset-1) Zeilen
    local skipRows    = math.max(0, (scrollOffset or 1) - 1)
    posYR = listStart  -- Startposition (oben)

    for ftIdx, item in ipairs(pool) do
        local colSlot = math.floor((ftIdx - 1) / rowsPerCol)
        local rowSlot = (ftIdx - 1) % rowsPerCol
        local ftX     = col2X + colSlot * colWft
        -- rowSlot relativ zu skipRows: erste sichtbare Zeile ist skipRows
        local visRow  = rowSlot - skipRows
        local ftY     = posYR - visRow * lineH

        lineIdxR = lineIdxR + (rowSlot == 0 and 1 or 0)

        if visRow >= 0 and ftY >= y + lineH then
            local zugeordnet = DL_Filter.bereichZuordnung ~= nil
                and DL_Filter.bereichZuordnung[DispoList.filterSelBereich] ~= nil
                and DL_Filter.bereichZuordnung[DispoList.filterSelBereich][item.ftName] == true
            setTextAlignment(RenderText.ALIGN_LEFT)
            local isSelected = DispoList.dlSelectedFt == item.ftName
            -- Status-Punkt (bgRound)
            local dotSize = lineH * 0.55
            local dotState = isSelected and "sel" or zugeordnet and "on" or "off"
            local dotW = DL_FilterMenu_Draw.drawCheckIcon(fOvGroup, fOvByName, dotState,
                ftX + difW, ftY, dotSize, difW, nil, nil, bgLine)
            if isSelected then
                setTextColor(0.0, 0.6, 1.0, 1)
            elseif zugeordnet then
                setTextColor(unpack(DL_Colors.gruenHead))
            else
                setTextColor(unpack(DL_Colors.grau65))
            end
            renderText(ftX + difW + dotW, ftY, size * 0.85, utf8Substr(item.title, 0))
            table.insert(DispoList.filterRightAreas, {
                typ="bereich_zuordnung",
                bereich=DispoList.filterSelBereich,
                ftName=item.ftName,
                title=item.title,
                zugeordnet=zugeordnet,
                x1=ftX+difW*0.3, y1=ftY-lineH*0.4, x2=ftX+colWft-difW*0.3, y2=ftY+lineH*0.6
            })
        end
    end
    -- posYR nach allen Zeilen verschieben für Scroll-Berechnung
    posYR = posYR - rowsPerCol * lineH
    return rowsPerCol * numCols  -- Scroll-Kapazität
end

-- ── MODUS 2: Station-Filter ───────────────────────────────────────────────────
function DL_FilterMenu_Draw.drawStationMode(x, y, w, h, col2X, colW, listStart, listTop, size, lineH, difW, bgLine, scrollOffset, fOvGroup, fOvByName)
    if DispoList.filterAllStations == nil then
        DispoList.filterAllStations = DL_FilterMenu_Draw.buildStationList()
    end

    local scrollL = DispoList.filterLeftScroll or 1
    local lineIdx = 0
    local posY    = listStart

    for _, st in ipairs(DispoList.filterAllStations) do
        lineIdx = lineIdx + 1
        if lineIdx >= scrollL and posY >= y + lineH then
            local isSel = (DispoList.filterSelStation == st.name)
            if bgLine ~= nil then
                g_currentMission.hlUtils.setOverlay(bgLine, x+difW*0.3, posY-lineH*0.4, colW-difW*0.6, lineH)
                g_currentMission.hlUtils.setBackgroundColor(bgLine,
                    isSel and DL_Colors.rowSel or DL_Colors.rowBg)
            end
            setTextColor(isSel and 1.0 or 0.8, isSel and 0.85 or 0.8, isSel and 0.0 or 0.8, 1)
            setTextBold(isSel)
            setTextAlignment(RenderText.ALIGN_LEFT)
            renderText(x + difW, posY, size * 1.0, utf8Substr(st.name, 0))
            setTextBold(false)
            table.insert(DispoList.filterLeftAreas, {
                station=st.name,
                x1=x+difW*0.3, y1=posY-lineH*0.4, x2=x+colW-difW*0.3, y2=posY+lineH*0.6
            })
            posY = posY - lineH
        end
    end

    if DispoList.filterSelStation == nil then
        setTextColor(unpack(DL_Colors.grauDim))
        renderText(col2X + difW, listTop - lineH * 1.8, size * 0.85, utf8Substr(DL_t("filter_station_hint"), 0))
        return 0
    end

    -- Rechte Spalte: Bereiche als Gruppen, darunter FillTypes aus Bereich-Definition
    -- Nur FillTypes zeigen die diese Station akzeptiert
    local stationFT = {}
    local stationFTSet = {}
    for _, station in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
        if station:isa(SellingStation) and not station.hideFromPricesMenu then
            if station:getName() == DispoList.filterSelStation then
                for ftIdx, accepted in pairs(station.acceptedFillTypes) do
                    if DL_Filter.isAcceptedByStation(station, ftIdx) then
                        local ft = g_fillTypeManager:getFillTypeByIndex(ftIdx)
                        if ft ~= nil then stationFTSet[ft.name] = ft.title or ft.name end
                    end
                end
            end
        end
    end

    -- Bereiche als Gruppen aufbauen (alphabetisch gecacht, Sonstiges unten, Unverkaeuflich nie anzeigen)
    local bereiche = {}
    for _, b in ipairs(DL_FilterMenu_Draw.getSortedBereichNames()) do
        bereiche[#bereiche + 1] = {name = b.name, order = b.order}
    end
    -- Nur Sonstiges ans Ende (Unverkaeuflich wird im Stations-Modus nie angezeigt)
    if DispoList.BEREICHE["Sonstiges"] ~= nil then
        table.insert(bereiche, {name="Sonstiges", order=99})
    end

    -- Nenner je Bereich (alle handelbaren Karten-Waren) fuer "N/M"
    local mapCounts = DL_FilterMenu_Draw.getMapFTCountsByBereich()

    -- Stations-Gesamtzahl (kauft / handelbar gesamt) rechts im Kopf
    do
        local totBuy = 0
        for _ in pairs(stationFTSet) do totBuy = totBuy + 1 end
        setTextAlignment(RenderText.ALIGN_RIGHT)
        setTextColor(unpack(DL_Colors.gold))
        renderText(x + w - difW, listTop, size * 0.9,
            utf8Substr(totBuy .. "/" .. #DL_FilterMenu_Draw.getAllMapFillTypes() .. " " .. DL_t("fs_angenommen"), 0))
        setTextAlignment(RenderText.ALIGN_LEFT)
    end

    local totalLines = 0
    local posYR    = listStart
    local lineIdxR = 0

    for _, ber in ipairs(bereiche) do
        -- FillTypes dieses Bereichs die diese Station kauft
        local berFTs = {}
        local zuordnung = DL_Filter.bereichZuordnung ~= nil and DL_Filter.bereichZuordnung[ber.name] or nil

        -- Sonstiges: alle die keinem Bereich zugeordnet
        if ber.name == "Sonstiges" then
            local alleZugeordnet = {}
            if DL_Filter.bereichZuordnung ~= nil then
                for _, fts in pairs(DL_Filter.bereichZuordnung) do
                    for ftName, _ in pairs(fts) do alleZugeordnet[ftName] = true end
                end
            end
            local allFT2 = DL_FilterMenu_Draw.getAllMapFillTypes()
            for _, item in ipairs(allFT2) do
                if not alleZugeordnet[item.ftName] and stationFTSet[item.ftName] ~= nil then
                    table.insert(berFTs, {ftName=item.ftName, title=item.title})
                end
            end
        else
            if zuordnung ~= nil then
                for ftName, _ in pairs(zuordnung) do
                    if stationFTSet[ftName] ~= nil then
                        local ft = g_fillTypeManager:getFillTypeByName(ftName)
                        local title = stationFTSet[ftName]
                               or (ft ~= nil and (ft.title or ft.name))
                               or ftName
                        table.insert(berFTs, {ftName=ftName, title=title})
                    end
                end
            end
        end

        if #berFTs > 0 then
            table.sort(berFTs, function(a, b)
                if ber.name ~= "Sonstiges" and DL_Filter.bereichZuordnung ~= nil then
                    local z = DL_Filter.bereichZuordnung[ber.name]
                    local aIn = z ~= nil and z[a.ftName] == true
                    local bIn = z ~= nil and z[b.ftName] == true
                    if aIn ~= bIn then return aIn end
                end
                return string.lower(a.title) < string.lower(b.title)
            end)
            local isExpandedBer  = DispoList.filterExpandedBereich == ber.name
            local numColsEst     = math.max(1, math.floor((w - colW) / (lineH * 6)))
            local rowsEst        = isExpandedBer and math.ceil(#berFTs / numColsEst) or 0
            totalLines = totalLines + 1 + rowsEst

            -- Bereichs-Header (klickbar - ganzen Bereich an/aus)
            lineIdxR = lineIdxR + 1
            if lineIdxR >= scrollOffset and posYR >= y + lineH then
                -- Zustand: alle an, alle aus, gemischt?
                local allOff = true
                local allOn  = true
                for _, item in ipairs(berFTs) do
                    if DL_Filter:isFiltered(DispoList.filterSelStation, item.ftName) then
                        allOn = false
                    else
                        allOff = false
                    end
                end
                -- Farbe je nach Zustand
                local berColor = allOff and {0.5, 0.5, 0.5, 1} or
                                 allOn  and {0.0, 1.0, 0.2, 1} or
                                            DL_Colors.gold  -- gemischt = gelb
                local isExpanded = DispoList.filterExpandedBereich == ber.name
                if bgLine ~= nil then
                    g_currentMission.hlUtils.setOverlay(bgLine, col2X+difW*0.3, posYR-lineH*0.4, w-colW-difW*0.6, lineH)
                    local bgCol = isExpanded and {0.05, 0.25, 0.05, 0.95}
                               or allOff     and {0.15, 0.05, 0.05, 0.9}
                               or                {0.05, 0.18, 0.05, 0.9}
                    g_currentMission.hlUtils.setBackgroundColor(bgLine, bgCol)
                    bgLine:render()
                end
                setTextColor(table.unpack(berColor))
                setTextBold(true)
                setTextAlignment(RenderText.ALIGN_LEFT)
                local berState = allOff and "off" or allOn and "on" or "mixed"
                local headerIconSize = lineH * 0.7
                local headerIconW = DL_FilterMenu_Draw.drawCheckIcon(fOvGroup, fOvByName, berState,
                    col2X + difW, posYR, headerIconSize, difW, nil, nil, bgLine)
                -- ClickArea für Bereich-Toggle (nur das Icon, klein)
                table.insert(DispoList.filterRightAreas, {
                    typ      = "bereich_toggle",
                    station  = DispoList.filterSelStation,
                    bereich  = ber.name,
                    berFTs   = berFTs,
                    allOff   = allOff,
                    x1=col2X+difW*0.3, y1=posYR-lineH*0.4, x2=col2X+difW+headerIconW, y2=posYR+lineH*0.6
                })
                -- Bereichsname + Anzahl + Aufklapp-Indikator (Icon)
                local expandIconSize = lineH * 0.6
                local expandIconW = DL_FilterMenu_Draw.drawExpandIcon(fOvGroup, fOvByName, isExpanded,
                    col2X + difW + headerIconW, posYR, expandIconSize, difW)
                local berLabel = DL_bereichLabel(ber.name) .. "  (" .. #berFTs .. "/" .. (mapCounts[ber.name] or #berFTs) .. ")"
                renderText(col2X + difW + headerIconW + expandIconW, posYR, size * 1.05, utf8Substr(berLabel, 0))
                setTextBold(false)
                -- ClickArea für Aufklappen (Rest der Zeile rechts vom Icon)
                table.insert(DispoList.filterRightAreas, {
                    typ      = "bereich_expand",
                    bereich  = ber.name,
                    x1=col2X+difW+headerIconW, y1=posYR-lineH*0.4, x2=x+w-difW*0.3, y2=posYR+lineH*0.6
                })
                posYR = posYR - lineH
            end

            -- FillTypes (nur anzeigen, wenn dieser Bereich aufgeklappt ist)
            if DispoList.filterExpandedBereich == ber.name then
                local rightW  = w - colW
                local ftColW  = rightW  -- Fallback: eine Spalte
                if #berFTs > 0 then
                    local maxW = 0
                    for _, item in ipairs(berFTs) do
                        local tw = getTextWidth(size * 0.85, utf8Substr(item.title .. "  ", 0))
                        if tw > maxW then maxW = tw end
                    end
                    local iconW = lineH * 0.7 + difW * 2
                    ftColW = math.max(iconW + maxW, lineH * 6)
                end
                local numCols   = math.max(1, math.floor(rightW / ftColW))
                local colWft    = rightW / numCols
                -- Spaltenweise füllen: erst Spalte 0 komplett, dann Spalte 1 usw.
                local rowsPerCol = math.ceil(#berFTs / numCols)
                local skipRows   = math.max(0, (scrollOffset or 1) - lineIdxR)

                for ftIdx, item in ipairs(berFTs) do
                    local colSlot = math.floor((ftIdx - 1) / rowsPerCol)
                    local rowSlot = (ftIdx - 1) % rowsPerCol
                    local ftX     = col2X + colSlot * colWft
                    local visRow  = rowSlot - skipRows
                    local ftY     = posYR - visRow * lineH
                    if visRow >= 0 and ftY >= y + lineH then
                        local isFiltered = DL_Filter:isFiltered(DispoList.filterSelStation, item.ftName)
                        setTextAlignment(RenderText.ALIGN_LEFT)
                        local ftIconSize = lineH * 0.55
                        local ftState    = isFiltered and "off" or "on"
                        local ftIconW    = DL_FilterMenu_Draw.drawCheckIcon(fOvGroup, fOvByName, ftState,
                            ftX + difW, ftY, ftIconSize, difW, nil, nil, bgLine)
                        if isFiltered then
                            setTextColor(unpack(DL_Colors.grauMit))
                        else
                            setTextColor(unpack(DL_Colors.gruenHead))
                        end
                        renderText(ftX + difW + ftIconW, ftY, size * 0.85, utf8Substr(item.title, 0))
                        table.insert(DispoList.filterRightAreas, {
                            typ="station_filter",
                            station=DispoList.filterSelStation,
                            ftName=item.ftName,
                            filtered=isFiltered,
                            x1=ftX+difW*0.3, y1=ftY-lineH*0.4, x2=ftX+colWft-difW*0.3, y2=ftY+lineH*0.6
                        })
                    end
                end
                -- posYR um die Anzahl tatsächlicher Zeilen (= rowsPerCol) nach unten schieben
                posYR = posYR - rowsPerCol * lineH
            end
        end
    end
    return totalLines
end

-- ── MODUS: Freischalten (Verkaufsstationen Zusatzwaren annehmen lassen) ──────
-- Links: Stationsliste (wie Station-Modus). Rechts: flache Liste ALLER handelbaren
-- Waren der Karte je gewaehlter Station: "# ab Werk" (grau, fix), "v freigeschaltet"
-- (gruen, + Preis-Faktor), "- freischaltbar" (klick). Motor: DL_SellpointUnlock.
function DL_FilterMenu_Draw.drawFreischaltMode(x, y, w, h, col2X, colW, listStart, listTop, size, lineH, difW, bgLine, scrollOffset, fOvGroup, fOvByName)
    if DispoList.filterAllStations == nil then
        DispoList.filterAllStations = DL_FilterMenu_Draw.buildStationList()
    end

    -- Linke Spalte: Stationsliste
    local scrollL = DispoList.filterLeftScroll or 1
    local lineIdx = 0
    local posY    = listStart
    for _, st in ipairs(DispoList.filterAllStations) do
        lineIdx = lineIdx + 1
        if lineIdx >= scrollL and posY >= y + lineH then
            local isSel = (DispoList.filterSelStation == st.name)
            if bgLine ~= nil then
                g_currentMission.hlUtils.setOverlay(bgLine, x+difW*0.3, posY-lineH*0.4, colW-difW*0.6, lineH)
                g_currentMission.hlUtils.setBackgroundColor(bgLine,
                    isSel and DL_Colors.rowSel or DL_Colors.rowBg)
            end
            setTextColor(isSel and 1.0 or 0.8, isSel and 0.85 or 0.8, isSel and 0.0 or 0.8, 1)
            setTextBold(isSel)
            setTextAlignment(RenderText.ALIGN_LEFT)
            renderText(x + difW, posY, size * 1.0, utf8Substr(st.name, 0))
            setTextBold(false)
            table.insert(DispoList.filterLeftAreas, {
                station=st.name,
                x1=x+difW*0.3, y1=posY-lineH*0.4, x2=x+colW-difW*0.3, y2=posY+lineH*0.6
            })
            posY = posY - lineH
        end
    end

    if DispoList.filterSelStation == nil then
        setTextColor(unpack(DL_Colors.grauDim))
        -- UNTER die Legende + Hilfezeile setzen (listStart liegt schon darunter),
        -- sonst kollidiert der Platzhalter mit der fs_hint_erzwingen-Zeile.
        renderText(col2X + difW, listStart - lineH * 0.8, size * 0.85, utf8Substr(DL_t("fs_hint_wahl"), 0))
        return 0
    end

    -- Station-Objekt suchen
    local stationObj = nil
    for _, station in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
        if station:isa(SellingStation) and station:getName() == DispoList.filterSelStation then
            stationObj = station
            break
        end
    end
    if stationObj == nil then return 0 end

    -- Aktuelle Deals dieser Station (ftUpper -> priceScale)
    local dealSet = {}
    if DL_SellpointUnlock ~= nil then
        for _, d in ipairs(DL_SellpointUnlock.deals or {}) do
            if d.station == DispoList.filterSelStation then dealSet[d.fillType] = d.priceScale or 1 end
        end
    end

    -- Native-Snapshot EINMALIG einfrieren (akzeptiert MINUS aktuelle Deals) --
    -- so bleibt "ab Werk" stabil, auch wenn man einen Deal wieder entfernt.
    DispoList.suNative = DispoList.suNative or {}
    if DispoList.suNative[DispoList.filterSelStation] == nil then
        local snap = {}
        -- Native-Wahrheit: hat SU einen VOR-Deal-Snapshot dieser Station (weil sie
        -- Deals hatte), diesen nehmen -> "ab Werk" bleibt korrekt, auch bei
        -- reinforced-native Waren nach Neustart. Sonst = acceptedFillTypes minus Deals.
        local suSnap = (DL_SellpointUnlock ~= nil and DL_SellpointUnlock.nativeSnap)
            and DL_SellpointUnlock.nativeSnap[stationObj] or nil
        if suSnap ~= nil and suSnap.acc ~= nil then
            for ftIdx in pairs(suSnap.acc) do
                local ft = g_fillTypeManager:getFillTypeByIndex(ftIdx)
                if ft ~= nil and ft.name ~= nil then snap[string.upper(ft.name)] = true end
            end
        elseif stationObj.acceptedFillTypes ~= nil then
            for ftIdx, acc in pairs(stationObj.acceptedFillTypes) do
                if acc == true then
                    local ft = g_fillTypeManager:getFillTypeByIndex(ftIdx)
                    local nm = ft ~= nil and ft.name ~= nil and string.upper(ft.name) or nil
                    if nm ~= nil and dealSet[nm] == nil then snap[nm] = true end
                end
            end
        end
        DispoList.suNative[DispoList.filterSelStation] = snap
    end
    local nativeSet = DispoList.suNative[DispoList.filterSelStation]

    -- Rechts: Waren nach Bereichen gruppiert (Akkordeon wie Stations-Modus),
    -- eingeklappt = uebersichtlich. Ein Bereich offen zur Zeit.
    local bereiche = {}
    for _, b in ipairs(DL_FilterMenu_Draw.getSortedBereichNames()) do
        bereiche[#bereiche + 1] = {name = b.name, order = b.order}
    end
    if DispoList.BEREICHE["Sonstiges"] ~= nil then table.insert(bereiche, {name="Sonstiges", order=99}) end

    local allFT = DL_FilterMenu_Draw.getAllMapFillTypes()
    local assigned = {}
    if DL_Filter.bereichZuordnung ~= nil then
        for _, fts in pairs(DL_Filter.bereichZuordnung) do
            for ftName, _ in pairs(fts) do assigned[ftName] = true end
        end
    end

    -- Stations-Gesamtzahl (akzeptiert nativ+Deals / handelbar gesamt) rechts im Kopf
    do
        local totAcc = 0
        for _, item in ipairs(allFT) do
            local u = string.upper(item.ftName)
            if nativeSet[u] == true or dealSet[u] ~= nil then totAcc = totAcc + 1 end
        end
        setTextAlignment(RenderText.ALIGN_RIGHT)
        setTextColor(unpack(DL_Colors.gold))
        renderText(x + w - difW, listTop, size * 0.9,
            utf8Substr(totAcc .. "/" .. #allFT .. " " .. DL_t("fs_angenommen"), 0))
        setTextAlignment(RenderText.ALIGN_LEFT)
    end

    local markerColW = getTextWidth(size * 1.1, "#") + difW * 1.4   -- Marker + Abstand
    local stepW      = getTextWidth(size, "  [-] 0.00 [+] ")

    local totalLines = 0
    local posYR    = listStart
    local lineIdxR = 0

    for _, ber in ipairs(bereiche) do
        -- Waren dieses Bereichs aus der handelbaren Karten-Warenliste
        local berFTs = {}
        if ber.name == "Sonstiges" then
            for _, item in ipairs(allFT) do
                if not assigned[item.ftName] then table.insert(berFTs, item) end
            end
        else
            local z = DL_Filter.bereichZuordnung ~= nil and DL_Filter.bereichZuordnung[ber.name] or nil
            if z ~= nil then
                for _, item in ipairs(allFT) do
                    if z[item.ftName] == true then table.insert(berFTs, item) end
                end
            end
        end

        -- Sortierung: "ab Werk" zuoberst, dann Zusatzabnahmen, dann restliche
        -- (jeweils alphabetisch) -- Rang aus nativeSet/dealSet der gewaehlten Station.
        table.sort(berFTs, function(a, b)
            local ra = (nativeSet[string.upper(a.ftName)] and 0) or (dealSet[string.upper(a.ftName)] and 1) or 2
            local rb = (nativeSet[string.upper(b.ftName)] and 0) or (dealSet[string.upper(b.ftName)] and 1) or 2
            if ra ~= rb then return ra < rb end
            return string.lower(a.title) < string.lower(b.title)
        end)

        if #berFTs > 0 then
            local isExpanded = DispoList.filterExpandedBereich == ber.name
            totalLines = totalLines + 1 + (isExpanded and #berFTs or 0)

            -- Bereich-Kopf (klickbar = auf/zu)
            lineIdxR = lineIdxR + 1
            if lineIdxR >= scrollOffset and posYR >= y + lineH then
                local nDeal, nAcc = 0, 0
                for _, item in ipairs(berFTs) do
                    local u = string.upper(item.ftName)
                    if dealSet[u] ~= nil then nDeal = nDeal + 1 end
                    if nativeSet[u] == true or dealSet[u] ~= nil then nAcc = nAcc + 1 end
                end
                if bgLine ~= nil then
                    g_currentMission.hlUtils.setOverlay(bgLine, col2X+difW*0.3, posYR-lineH*0.4, (w-colW)-difW*0.6, lineH)
                    g_currentMission.hlUtils.setBackgroundColor(bgLine,
                        isExpanded and {0.05,0.25,0.05,0.95} or {0.06,0.10,0.06,0.85})
                    bgLine:render()
                end
                local eIconW = DL_FilterMenu_Draw.drawExpandIcon(fOvGroup, fOvByName, isExpanded, col2X+difW, posYR, lineH*0.6, difW)
                setTextColor(unpack(DL_Colors.gold)); setTextBold(true); setTextAlignment(RenderText.ALIGN_LEFT)
                local label = DL_bereichLabel(ber.name) .. "  (" .. nAcc .. "/" .. #berFTs .. ")"
                renderText(col2X + difW + eIconW, posYR, size * 1.05, utf8Substr(label, 0))
                if nDeal > 0 then
                    local baseW = getTextWidth(size * 1.05, label .. "   ")
                    setTextColor(unpack(DL_Colors.gruen))
                    renderText(col2X + difW + eIconW + baseW, posYR, size * 1.0, utf8Substr("v " .. nDeal, 0))
                end
                setTextBold(false)
                table.insert(DispoList.filterRightAreas, {
                    typ="bereich_expand", bereich=ber.name,
                    x1=col2X+difW*0.3, y1=posYR-lineH*0.4, x2=x+w-difW*0.3, y2=posYR+lineH*0.6
                })
                posYR = posYR - lineH
            end

            -- Waren (nur wenn aufgeklappt)
            if isExpanded then
                -- Faktor-Spalte dynamisch aus laengstem Warennamen dieses Bereichs
                local maxTitleW = 0
                for _, item in ipairs(berFTs) do
                    local tw = getTextWidth(size * 0.95, utf8Substr(item.title, 0))
                    if tw > maxTitleW then maxTitleW = tw end
                end
                local markerX = col2X + difW * 1.6
                local nameX   = markerX + markerColW
                local stepX   = math.min(nameX + maxTitleW + difW * 2, x + w - difW - stepW)

                for _, item in ipairs(berFTs) do
                    lineIdxR = lineIdxR + 1
                    if lineIdxR >= scrollOffset and posYR >= y + lineH then
                        local ftUpper  = string.upper(item.ftName)
                        local isDeal   = dealSet[ftUpper] ~= nil
                        local isNative = nativeSet[ftUpper] == true
                        if bgLine ~= nil and isDeal then
                            g_currentMission.hlUtils.setOverlay(bgLine, col2X+difW*0.6, posYR-lineH*0.4, (w-colW)-difW*1.2, lineH)
                            g_currentMission.hlUtils.setBackgroundColor(bgLine, {0.05,0.18,0.05,0.85})
                            bgLine:render()
                        end
                        local marker, mcol, tcol
                        if isNative and isDeal then
                            -- ab Werk + erzwungen (in ALLEN Trigger-Formen, z.B. Palette)
                            marker = "#"; mcol = DL_Colors.gruen; tcol = DL_Colors.gruen
                        elseif isNative then
                            marker = "#"; mcol = {0.45,0.45,0.45,1}; tcol = {0.5,0.5,0.5,1}
                        elseif isDeal then
                            marker = "v"; mcol = {0.1,1.0,0.1,1};   tcol = {0.1,1.0,0.1,1}
                        else
                            marker = "-"; mcol = {0.6,0.6,0.6,1};    tcol = {0.85,0.85,0.85,1}
                        end
                        setTextAlignment(RenderText.ALIGN_LEFT)
                        setTextBold(true); setTextColor(table.unpack(mcol))
                        renderText(markerX, posYR, size * 1.1, utf8Substr(marker, 0))
                        setTextBold(false); setTextColor(table.unpack(tcol))
                        renderText(nameX, posYR, size * 0.95, utf8Substr(item.title, 0))
                        -- Alle Waren klickbar: auch "# ab Werk" -> in allen Trigger-Formen
                        -- freischalten (z.B. Palette). Entfernen setzt sauber auf nativ zurueck.
                        table.insert(DispoList.filterRightAreas, {
                            typ="su_toggle", station=DispoList.filterSelStation, ftName=item.ftName,
                            x1=markerX-difW*0.3, y1=posYR-lineH*0.4,
                            x2=(isDeal and (stepX - difW) or (x+w-difW*0.3)), y2=posYR+lineH*0.6
                        })
                        if isDeal then
                            local scale  = dealSet[ftUpper]
                            setTextColor(unpack(DL_Colors.gold)); setTextBold(true)
                            renderText(stepX, posYR, size, utf8Substr("[-]", 0))
                            local minusW = getTextWidth(size, "[-] ")
                            local vcol = scale > 1 and {0.1,1.0,0.1,1} or (scale < 1 and {1.0,0.6,0.1,1} or {0.85,0.85,0.85,1})
                            setTextBold(false); setTextColor(table.unpack(vcol))
                            local vStr = string.format("%.2f", scale)
                            renderText(stepX + minusW, posYR, size, utf8Substr(vStr, 0))
                            local valW = getTextWidth(size, vStr .. " ")
                            setTextColor(unpack(DL_Colors.gold)); setTextBold(true)
                            renderText(stepX + minusW + valW, posYR, size, utf8Substr("[+]", 0))
                            setTextBold(false)
                            table.insert(DispoList.filterRightAreas, {
                                typ="su_scale", station=DispoList.filterSelStation, ftName=item.ftName, dir=-1,
                                x1=stepX-difW*0.3, y1=posYR-lineH*0.4, x2=stepX+minusW, y2=posYR+lineH*0.6
                            })
                            table.insert(DispoList.filterRightAreas, {
                                typ="su_scale", station=DispoList.filterSelStation, ftName=item.ftName, dir=1,
                                x1=stepX+minusW+valW-difW*0.3, y1=posYR-lineH*0.4,
                                x2=stepX+minusW+valW+getTextWidth(size,"[+] "), y2=posYR+lineH*0.6
                            })
                        end
                        posYR = posYR - lineH
                    end
                end
            end
        end
    end
    return totalLines
end
