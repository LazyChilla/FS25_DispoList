--
-- FS25 DispoList - Spaltenauswahl GuiBox
-- Öffnet sich wenn Zahnrad in Hauptbox aktiv + settingExtension Icon geklickt
--

DL_ColSettings = DL_ColSettings or {}
DL_ColSettings.guiBox = nil  -- GuiBox immer neu aufbauen beim Sourcen

-- Spalten-Definitionen: key, Label, default an
DL_ColSettings.COLS = {
    { key="bestand",  label="col_bestand",    default=false },
    { key="frei",     label="col_frei",       default=true },
    { key="preis",    label="col_preis",default=false },
    { key="maxPreis", label="col_maxpreis",  default=false },
    { key="wert",     label="col_wert",       default=false },
    { key="vkWert",   label="col_vkwert",    default=true },
    { key="max",      label="col_max",      default=false },
    { key="vkMax",    label="col_vkmax",     default=true },
    { key="monat",    label="col_monat", default=true },
}

-- Sichtbarkeits-State (Tabelle: key -> bool)
DL_ColSettings.visible = DL_ColSettings.visible or {}

function DL_ColSettings:init()
    -- Defaults setzen
    for _, col in ipairs(self.COLS) do
        if self.visible[col.key] == nil then
            self.visible[col.key] = col.default
        end
    end
end

function DL_ColSettings:isVisible(key)
    if self.visible[key] == nil then return true end
    return self.visible[key]
end

function DL_ColSettings:toggle(key)
    self.visible[key] = not (self.visible[key] ~= false)
end

-- GuiBox erstellen
function DL_ColSettings:createGuiBox()
    -- Nur zurückgeben wenn noch sichtbar, sonst neu erstellen
    if self.guiBox ~= nil and self.guiBox.show then return self.guiBox end
    if self.guiBox ~= nil and not self.guiBox.show then
        self.guiBox = nil  -- alte geschlossene Instanz verwerfen
    end

    local gb = g_currentMission.hlHudSystem.hlGuiBox.generate({
        name         = "DL_ColSettings_GuiBox",
        title        = "DispoList: Einstellungen",
        viewMaxLines = #self.COLS + 23,
        ownTable     = {},
    })

    -- getLine Funktion: lineCallSequence-basiert (korrekt, unabhängig von bounds)
    gb.getLine = function(args)
        local seq = args.lineCallSequence
        if seq == nil then return nil end

        -- Überschrift
        if seq == "dl_col_headline_" then
            return { typ="headline", text={[1]={text=DL_t("set_spalten_anzeigen"), color="columText1"}} }
        end

        -- Reserve Überschrift
        if seq == "dl_reserve_headline_" then
            return { typ="headline", text={[1]={text=DL_t("set_einstellungen"), color="columText1"}} }
        end

        -- Reserve: aktueller Wert
        if seq == "dl_reserve_info_" then
            local rs = DispoList.reserveStunden or 24
            return {
                typ  = "headline",
                text = { [1] = { text=DL_t("set_fabrik_puffer") .. rs .. "h", color="columText1" } },
            }
        end

        -- Reserve: Formel-Erklärung (grün = Bezug zu freier Menge)
        if seq == "dl_reserve_formula_" then
            return {
                typ  = "headline",
                text = { [1] = { text=DL_t("set_puffer_formel"), color={0.25, 0.85, 0.25, 1} } },
            }
        end

        -- Reserve Minus-Zeilen
        local minusStep = ({["dl_reserve_m1_"]=1, ["dl_reserve_m6_"]=6, ["dl_reserve_m24_"]=24})[seq]
        if minusStep ~= nil then
            return {
                oneClick = true,
                typ      = "boolean",
                text     = { [1] = { text="  - " .. minusStep .. "h", color="off" } },
                onClick  = function(clickArgs)
                    if clickArgs == nil or not clickArgs.isDown then return end
                    DispoList.reserveStunden = math.max(1, (DispoList.reserveStunden or 24) - minusStep)
                    -- Kein eager savePauseSetting() mehr -- zentral ueber ItemSystem.save-Hook
                    DispoList:refreshDispoTable()
                    local gb = DL_ColSettings.guiBox
                    if gb ~= nil then gb.needsUpdate = true end
                end,
            }
        end

        -- Reserve Plus-Zeilen
        local plusStep = ({["dl_reserve_p1_"]=1, ["dl_reserve_p6_"]=6, ["dl_reserve_p24_"]=24})[seq]
        if plusStep ~= nil then
            return {
                oneClick = true,
                typ      = "boolean",
                text     = { [1] = { text="  + " .. plusStep .. "h", color="activeGreen" } },
                onClick  = function(clickArgs)
                    if clickArgs == nil or not clickArgs.isDown then return end
                    DispoList.reserveStunden = math.min(168, (DispoList.reserveStunden or 24) + plusStep)
                    -- Kein eager savePauseSetting() mehr -- zentral ueber ItemSystem.save-Hook
                    DispoList:refreshDispoTable()
                    local gb = DL_ColSettings.guiBox
                    if gb ~= nil then gb.needsUpdate = true end
                end,
            }
        end

        -- Leerzeile als Trenner vor Lagertypen
        if seq == "dl_spacer_lager_" then
            return { typ="headline", text={[1]={text=" ", color="columText1"}} }
        end

        -- Lagertypen-Headline
        if seq == "dl_lager_headline_" then
            return { typ="headline", text={[1]={text=DL_t("set_lagertypen"), color="columText1"}} }
        end

        -- Lagertypen-Checkboxen
        local lagerTypen = {
            { key="ZENTRALLAGER",   label=DL_t("lt_zentrallager") },
            { key="SILO",           label=DL_t("lt_silo") },
            { key="SILO_EXTENSION", label=DL_t("lt_silo_ext") },
            { key="HUSBANDRY",      label=DL_t("lt_husbandry") },
            { key="MANURE",         label=DL_t("lt_manure") },
            { key="BEEHIVE",        label=DL_t("lt_beehive") },
            { key="BUNKER",         label=DL_t("lt_bunker") },
            { key="OBJEKTLAGER",    label=DL_t("lt_objektlager") },
            { key="BALE",           label=DL_t("lt_bale") },
            { key="PALLET",         label=DL_t("lt_pallet") },
            { key="PRODUCTION_OUT", label=DL_t("lt_production_out") },
        }
        for _, lt in ipairs(lagerTypen) do
            if seq == "dl_lager_" .. lt.key .. "_" then
                local found = DispoList.foundLagertypen and DispoList.foundLagertypen[lt.key]
                if not found then return nil end
                local isActive = DispoList.activeLagertypen and (DispoList.activeLagertypen[lt.key] ~= false)
                return {
                    oneClick = true,
                    typ      = "boolean",
                    text     = { [1] = { text=(isActive and "[v] " or "[ ] ") .. lt.label,
                                         color = isActive and "activeGreen" or "columText1" } },
                    onClick  = function(clickArgs)
                        if clickArgs == nil or not clickArgs.isDown then return end
                        local now = g_currentMission.time or 0
                        if DispoList.dlClickCooldown ~= nil and now - DispoList.dlClickCooldown < 400 then return end
                        DispoList.dlClickCooldown = now
                        DispoList.activeLagertypen[lt.key] = not (DispoList.activeLagertypen[lt.key] ~= false)
                        -- Kein eager savePauseSetting() mehr -- zentral ueber ItemSystem.save-Hook
                        DispoList:refreshDispoTable()
                        -- Kein needsUpdate — würde GuiBox-State zerstören und Hover-Bug auslösen
                        -- Stattdessen: nur die betroffene Zeile neu rendern lassen
                        DL_ColSettings.guiBox = nil  -- erzwingt Rebuild beim nächsten Öffnen
                    end,
                }
            end
        end

        -- ── Preset-Sektion ────────────────────────────────────────────────────
        if seq == "dl_preset_headline_" then
            return { typ="headline", text={[1]={text=DL_t("set_bereiche_preset"), color="columText1"}} }
        end

        if seq == "dl_preset_info_" then
            local status
            local ap = DL_Filter.activePreset or ""
            if ap == "ZL" then
                status = "Aktiv: Zentrallager-Preset"
            elseif ap == "GIANTS" then
                status = "Aktiv: Giants-Standard"
            elseif ap == "SELBST" or DL_Filter.userPersonalized then
                status = "Aktiv: Eigene Einstellung"
            else
                status = "Noch kein Preset gewaehlt"
            end
            return { typ="headline", text={[1]={text=status, color={0.6,0.85,1.0,1}}} }
        end

        -- Hilfsfunktion: Preset anwenden mit optionaler Überschreib-Warnung
        local function applyPreset(applyFn, presetKey)
            local function doApply()
                applyFn()
                DL_Filter.presetDialogShown = true
                DL_Filter.userPersonalized  = false
                DL_Filter.activePreset      = presetKey or ""
                -- Kein eager saveBereiche() mehr -- zentral ueber ItemSystem.save-Hook
                DL_ColSettings.guiBox = nil
                DispoList:refreshDispoTable()
            end
            if DL_Filter.userPersonalized and g_currentMission.hlHudSystem ~= nil then
                g_currentMission.hlHudSystem:yesNoDialog({
                    title    = "DispoList: Preset laden",
                    text     = "Eigene Einstellungen werden ueberschrieben. Fortfahren?",
                    callback = function(yes) if yes then doApply() end end,
                    ownTable = nil,
                })
            else
                doApply()
            end
        end

        if seq == "dl_preset_selbst_" then
            return {
                oneClick = true,
                typ      = "boolean",
                helpText = "Keine Aenderung — eigene Bereiche-Zuordnung behalten",
                text     = { [1] = { text=DL_t("set_selbst"), color="columText1" } },
                onClick  = function(clickArgs)
                    if clickArgs == nil or not clickArgs.isDown then return end
                    local now = g_currentMission.time or 0
                    if DispoList.dlClickCooldown ~= nil and now - DispoList.dlClickCooldown < 400 then return end
                    DispoList.dlClickCooldown = now
                    DL_Filter.presetDialogShown = true
                    DL_Filter.userPersonalized  = true
                    DL_Filter.activePreset      = "SELBST"
                    -- Kein eager saveBereiche() mehr -- zentral ueber ItemSystem.save-Hook
                    DL_ColSettings.guiBox = nil
                end,
            }
        end

        if seq == "dl_preset_zl_" then
            return {
                oneClick = true,
                typ      = "boolean",
                helpText = "Zentrallager-Preset: Getreide, Kuehlung, Lebensmittel, ObstGemuese...",
                text     = { [1] = { text=DL_t("set_zl_laden"), color="columText1" } },
                onClick  = function(clickArgs)
                    if clickArgs == nil or not clickArgs.isDown then return end
                    local now = g_currentMission.time or 0
                    if DispoList.dlClickCooldown ~= nil and now - DispoList.dlClickCooldown < 400 then return end
                    DispoList.dlClickCooldown = now
                    applyPreset(function()
                        DL_Filter:applyPreset(DispoList.BEREICHE_PRESET_ERWEITERT)
                        DL_Filter:autoAssignFromZentrallager()
                    end, "ZL")
                end,
            }
        end

        if seq == "dl_preset_giants_" then
            return {
                oneClick = true,
                typ      = "boolean",
                helpText = "Giants-Standard: Schuettgut, Fluessig, Tier, Produkte...",
                text     = { [1] = { text=DL_t("set_giants_laden"), color="columText1" } },
                onClick  = function(clickArgs)
                    if clickArgs == nil or not clickArgs.isDown then return end
                    local now = g_currentMission.time or 0
                    if DispoList.dlClickCooldown ~= nil and now - DispoList.dlClickCooldown < 400 then return end
                    DispoList.dlClickCooldown = now
                    applyPreset(function()
                        -- Erst BEREICHE auf Default zurücksetzen (löscht ZL-Bereiche wie Kühlung etc.)
                        if DispoList.BEREICHE_DEFAULT ~= nil then
                            DispoList.BEREICHE = {}
                            DL_Filter.bereichZuordnung = {}
                            for name, data in pairs(DispoList.BEREICHE_DEFAULT) do
                                DispoList.BEREICHE[name] = { order=data.order, fillTypes=data.fillTypes or {} }
                                DL_Filter.bereichZuordnung[name] = {}
                                for _, ftName in ipairs(data.fillTypes or {}) do
                                    DL_Filter.bereichZuordnung[name][ftName] = true
                                end
                            end
                            -- Kein eager saveBereiche()/saveBereichZuordnung() mehr -- zentral ueber ItemSystem.save-Hook
                        end
                        DL_Filter:deltaAssignFillTypes()
                    end, "GIANTS")
                end,
            }
        end

        -- Boolean-Zeile: seq = "dl_col_N_" -> N = Index in COLS
        local idx = tonumber(string.match(seq, "dl_col_(%d+)_"))
        if idx == nil then return nil end
        local col = DL_ColSettings.COLS[idx]
        if col == nil then return nil end

        local state = DL_ColSettings:isVisible(col.key)
        local stateColor = state and "on" or "off"
        return {
            oneClick = true,
            typ      = "boolean",
            helpText = (state and "AN" or "AUS") .. " - Klick zum Umschalten",
            text     = {
                [1] = { text=utf8Substr(DL_t(col.label), 0), color=stateColor },
                [2] = { text="", color=stateColor, state=state },
            },
            onClick  = function(clickArgs)
                if clickArgs == nil or not clickArgs.isDown then return end
                DL_ColSettings:toggle(col.key)
                -- Kein eager savePauseSetting() mehr -- zentral ueber ItemSystem.save-Hook
                -- Hauptbox zum Neuberechnen zwingen
                local mbox = g_currentMission.hlHudSystem.hlBox:getData("DL_Display_Box")
                if mbox ~= nil then
                    mbox.ownTable.lineHeight = nil
                    mbox.needsUpdate = true
                end
            end,
        }
    end

    -- Zeilen registrieren (Überschrift + eine Zeile pro Spalte)
    gb:addLine({ lineCallSequence="dl_col_headline_" })
    for i = 1, #self.COLS do
        gb:addLine({ lineCallSequence="dl_col_" .. i .. "_" })
    end
    gb:addLine({ lineCallSequence="dl_reserve_headline_" })
    gb:addLine({ lineCallSequence="dl_reserve_info_" })
    gb:addLine({ lineCallSequence="dl_reserve_formula_" })
    gb:addLine({ lineCallSequence="dl_reserve_m1_" })
    gb:addLine({ lineCallSequence="dl_reserve_m6_" })
    gb:addLine({ lineCallSequence="dl_reserve_m24_" })
    gb:addLine({ lineCallSequence="dl_reserve_p1_" })
    gb:addLine({ lineCallSequence="dl_reserve_p6_" })
    gb:addLine({ lineCallSequence="dl_reserve_p24_" })

    -- Preset-Sektion
    gb:addLine({ lineCallSequence="dl_preset_headline_" })
    gb:addLine({ lineCallSequence="dl_preset_info_" })
    gb:addLine({ lineCallSequence="dl_preset_selbst_" })
    if DispoList.foundZentrallager ~= nil and DispoList.foundZentrallager > 0 then
        gb:addLine({ lineCallSequence="dl_preset_zl_" })
    end
    gb:addLine({ lineCallSequence="dl_preset_giants_" })

    -- Lagertypen-Sektion: nur vorhandene Typen registrieren
    local lagerKeys = {"ZENTRALLAGER","SILO","SILO_EXTENSION","HUSBANDRY","MANURE","BEEHIVE","BUNKER","OBJEKTLAGER","BALE","PALLET","PRODUCTION_OUT"}
    local foundAny = false
    for _, key in ipairs(lagerKeys) do
        if DispoList.foundLagertypen and DispoList.foundLagertypen[key] then
            foundAny = true
            break
        end
    end
    if foundAny then
        gb:addLine({ lineCallSequence="dl_spacer_lager_" })
        gb:addLine({ lineCallSequence="dl_lager_headline_" })
        for _, key in ipairs(lagerKeys) do
            if DispoList.foundLagertypen and DispoList.foundLagertypen[key] then
                gb:addLine({ lineCallSequence="dl_lager_" .. key .. "_" })
            end
        end
    end

    -- onClick: reagiert auf alle Klicks inkl. closeIcon_
    gb.onClick = function(args)
        if args == nil then return end
        if args.clickAreaTable ~= nil and
           args.clickAreaTable.areaClick == "closeIcon_" then
            -- Lokale Referenz zurücksetzen wenn User X klickt
            DL_ColSettings.guiBox = nil
        end
    end

    self.guiBox = gb
    return gb
end

-- Toggle: GuiBox öffnen/schließen
function DL_ColSettings:toggle_guibox()
    -- Wenn GuiBox offen: schliessen ohne neu zu erstellen
    if self.guiBox ~= nil and self.guiBox.show then
        self.guiBox.show = false
        self.guiBox = nil
        return
    end
    -- Sonst: neu erstellen und öffnen
    self.guiBox = nil  -- alte Referenz löschen
    local gb = self:createGuiBox()
    if gb ~= nil then
        gb:setShow(true)
    end
end

-- Initialisieren
DL_ColSettings:init()
