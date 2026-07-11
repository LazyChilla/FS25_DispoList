--
-- FS25 DispoList - Filter Manager
-- Verwaltet Blacklist (Station+FillType), lädt/speichert XML
--

-- Komplett neu initialisieren beim Sourcen (verhindert State-Überleben zwischen Sessions)
DL_Filter = {}
DL_Filter.blacklist          = {}
DL_Filter.xmlPath            = nil
DL_Filter.bereichZuordnung   = {}
DL_Filter.deaktivierteStationsBereiche = {}
DL_Filter.presetDialogShown  = false  -- persistent: Erststart-Dialog wurde bereits gezeigt
DL_Filter.userPersonalized   = false  -- persistent: Spieler hat manuell FillTypes verschoben
DL_Filter.activePreset       = ""     -- persistent: "ZL", "GIANTS", "SELBST", "" = noch nicht gewählt

-- Zentrale Prüfung: akzeptiert diese Station eine bestimmte Ware?
-- Heute nur echte Vanilla-Pruefung (station.acceptedFillTypes laut Placeable-XML).
-- Bewusst als EINE zentrale Stelle gebaut: wenn der geplante DL_TriggerEditor
-- kommt (Stationen sollen dann auch Waren annehmen koennen, die ihre XML gar
-- nicht kennt), reicht es diese eine Funktion um den Override-Check zu erweitern,
-- statt an jeder der vier Fundstellen im Code einzeln nachzuruesten.
function DL_Filter.isAcceptedByStation(station, ftIdx)
    if station == nil or ftIdx == nil or station.acceptedFillTypes == nil then return false end
    if station.acceptedFillTypes[ftIdx] == true then return true end
    -- TODO (DL_TriggerEditor, noch nicht gebaut): hier zusaetzlich pruefen ob
    -- der Spieler diese Station manuell um diese Ware erweitert hat.
    return false
end

-- FS25 FillType-Kategorien (für Kategorie-Buttons im Menü)
-- Kategorie-Buttons = unsere eigenen BEREICHE
DL_Filter.KATEGORIEN = {
    { key="Getreide",     label="Getreide"     },
    { key="Flüssig",      label="Flüssig"      },
    { key="Kühlung",      label="Kühlung"      },
    { key="Lebensmittel", label="Lebensmittel" },
    { key="Obst & Gemüse",label="Obst/Gemüse"  },
    { key="Werkstoffe",   label="Werkstoffe"   },
    { key="Schuettgut",   label="Schüttgut"    },
    { key="Ballen",       label="Ballen"       },
    { key="Milch & Tier", label="Milch/Tier"   },
    { key="Sonstiges",    label="Sonstiges"    },
}

-- Mappt FillType-Kategorie-Index auf unseren Kategorie-Key
DL_Filter.CATEGORY_MAP = {}

-- Initialisierung: FillType-Kategorien aus dem Spiel laden
function DL_Filter:init()
    -- XML-Pfad im Savegame-Ordner
    local saveDir = g_currentMission.missionInfo.savegameDirectory
    if saveDir == nil then
        -- Neues Savegame: Verzeichnis noch nicht erstellt, aus savegameIndex ableiten
        local idx = g_currentMission.missionInfo.savegameIndex
        if idx ~= nil then
            saveDir = getUserProfileAppPath() .. "savegame" .. tostring(idx)
        end
    end
    if saveDir ~= nil then
        self.xmlPath = saveDir .. "/dispoList_filter.xml"
        Logging.info("[DispoList] init(): savegameDirectory=%s -> xmlPath=%s", tostring(saveDir), tostring(self.xmlPath))
    else
        Logging.info("[DispoList] init(): WARNUNG saveDir und savegameIndex sind nil!")
    end

    -- Bereiche-Definition aus XML laden (überschreibt Order, erlaubt neue Bereiche)
    self:loadBereiche()

    -- CATEGORY_MAP aus unseren eigenen BEREICHEN aufbauen
    for _, ft in pairs(g_fillTypeManager.fillTypes) do
        if ft ~= nil and ft.name ~= nil then
            self.CATEGORY_MAP[ft.name] = "Sonstiges"
        end
    end
    if DispoList ~= nil and DispoList.BEREICHE ~= nil then
        for bereichName, bereichData in pairs(DispoList.BEREICHE) do
            for _, ftName in ipairs(bereichData.fillTypes) do
                self.CATEGORY_MAP[ftName] = bereichName
            end
        end
    end
    local count = 0; for _ in pairs(self.CATEGORY_MAP) do count = count + 1 end

    self:loadFromXml()
    self:loadBereichZuordnung()

    -- Migration für Bestands-Savegames (vor presetDialogShown/userPersonalized eingeführt):
    -- Existieren bereits FillType-Zuordnungen, aber das Personalisierungs-Flag fehlt noch,
    -- werten wir das als "Spieler hat schon eigene Daten" -> Flag setzen, Dialog überspringen.
    if not self.userPersonalized then
        local hatZuordnung = false
        for _, fts in pairs(self.bereichZuordnung) do
            for _, active in pairs(fts) do
                if active then hatZuordnung = true; break end
            end
            if hatZuordnung then break end
        end
        if hatZuordnung then
            self.userPersonalized  = true
            self.presetDialogShown = true  -- Bestandsspieler nie mit dem neuen Dialog überraschen
            -- Kein eager saveBereiche() mehr hier -- wird beim naechsten ItemSystem.save
            -- (offizieller Spielstand-Speicherpunkt) automatisch mitgeschrieben.
        end
    end

    -- Delta-Zuordnung für Bestandsspieler (neue Karten-FillTypes nachsortieren) läuft sofort.
    -- Gate ist presetDialogShown, NICHT isFirstRun: isFirstRun wird nur beim allerersten
    -- init()-Aufruf gesetzt (XML existiert ab da), wäre also ab dem 2. Spielstart unzuverlässig.
    -- Bei echtem Erststart (presetDialogShown==false) läuft die komplette Erstzuordnung
    -- stattdessen erst beim ersten HUD-Öffnen über DispoList:checkPresetDialog() (dispoList.lua).
    if self.presetDialogShown then
        self:deltaAssignFillTypes()
    end
    -- Fehlende bereichZuordnung-Einträge für alle aktiven Bereiche anlegen
    for name, _ in pairs(DispoList.BEREICHE) do
        if self.bereichZuordnung[name] == nil then
            self.bereichZuordnung[name] = {}
        end
    end
    self:loadPauseSetting()
end

-- Anzahl aktiver Filter
function DL_Filter:countBlacklist()
    local n = 0
    for _, fts in pairs(self.blacklist) do
        for _ in pairs(fts) do n = n + 1 end
    end
    return n
end

-- Prüft ob eine Station+FillType-Kombination gefiltert ist
function DL_Filter:isFiltered(stationName, fillTypeName)
    local st = self.blacklist[stationName]
    if st == nil then return false end
    return st[fillTypeName] == true
end

-- Eintrag zur Blacklist hinzufügen
function DL_Filter:addFilter(stationName, fillTypeName)
    if self.blacklist[stationName] == nil then
        self.blacklist[stationName] = {}
    end
    self.blacklist[stationName][fillTypeName] = true
    -- Kein eager saveToXml() mehr -- zentral ueber ItemSystem.save-Hook (siehe dispoList.lua)
end

-- Eintrag aus Blacklist entfernen
function DL_Filter:removeFilter(stationName, fillTypeName)
    if self.blacklist[stationName] ~= nil then
        self.blacklist[stationName][fillTypeName] = nil
        -- Station komplett entfernen wenn leer
        local empty = true
        for _ in pairs(self.blacklist[stationName]) do empty = false; break end
        if empty then self.blacklist[stationName] = nil end
    end
    -- Kein eager saveToXml() mehr -- zentral ueber ItemSystem.save-Hook
end

-- Alle Filter einer Station entfernen
function DL_Filter:removeAllForStation(stationName)
    self.blacklist[stationName] = nil
    -- Kein eager saveToXml() mehr -- zentral ueber ItemSystem.save-Hook
end

-- Alle Filter komplett löschen
function DL_Filter:clearAll()
    self.blacklist = {}
    -- Kein eager saveToXml() mehr -- zentral ueber ItemSystem.save-Hook
end

-- Kategorie-Status für eine Station ermitteln (für Dreizustand-Button)
-- Gibt zurück: "ALL_ON", "ALL_OFF", "MIXED"
function DL_Filter:getCategoryState(stationName, categoryKey, stationFillTypes)
    local total = 0
    local off   = 0
    for _, ftName in ipairs(stationFillTypes) do
        if self.CATEGORY_MAP[ftName] == categoryKey then
            total = total + 1
            if self:isFiltered(stationName, ftName) then
                off = off + 1
            end
        end
    end
    if total == 0   then return "EMPTY" end
    if off == 0     then return "ALL_ON" end
    if off == total then return "ALL_OFF" end
    return "MIXED"
end

-- Ganze Kategorie für eine Station umschalten
function DL_Filter:toggleCategory(stationName, categoryKey, stationFillTypes, forceState)
    -- forceState: "ON" = alle aktivieren, "OFF" = alle deaktivieren, nil = toggle
    local state = forceState
    if state == nil then
        local current = self:getCategoryState(stationName, categoryKey, stationFillTypes)
        state = (current == "ALL_OFF") and "ON" or "OFF"
    end
    for _, ftName in ipairs(stationFillTypes) do
        if self.CATEGORY_MAP[ftName] == categoryKey then
            if state == "OFF" then
                self:addFilter(stationName, ftName)
            else
                self:removeFilter(stationName, ftName)
            end
        end
    end
    -- Kein eager saveToXml() mehr -- zentral ueber ItemSystem.save-Hook
end

-- XML laden
function DL_Filter:loadFromXml()
    self.blacklist = {}
    if self.xmlPath == nil then return end
    local exists = fileExists(self.xmlPath)
    Logging.info("[DispoList] loadFromXml(): fileExists(%s)=%s", tostring(self.xmlPath), tostring(exists))
    if not exists then return end

    local xml = loadXMLFile("DL_Filter", self.xmlPath)
    if xml == nil then return end

    local i = 0
    while true do
        local base = string.format("dispoListFilter.filter(%d)", i)
        if not hasXMLProperty(xml, base) then break end
        local station  = getXMLString(xml, base .. "#station")
        local fillType = getXMLString(xml, base .. "#fillType")
        if station ~= nil and fillType ~= nil then
            if self.blacklist[station] == nil then self.blacklist[station] = {} end
            self.blacklist[station][fillType] = true
        end
        i = i + 1
    end
    delete(xml)
end

-- XML speichern
function DL_Filter:saveToXml()
    if self.xmlPath == nil then return end
    local xml = createXMLFile("DL_Filter", self.xmlPath, "dispoListFilter")
    if xml == nil then return end

    local i = 0
    for station, fts in pairs(self.blacklist) do
        for fillType, active in pairs(fts) do
            if active then
                local base = string.format("dispoListFilter.filter(%d)", i)
                setXMLString(xml, base .. "#station",  station)
                setXMLString(xml, base .. "#fillType", fillType)
                i = i + 1
            end
        end
    end
    saveXMLFile(xml)
    delete(xml)
end

-- ─── Bereich-Zuordnung (Stufe 1) ─────────────────────────────────────────────
-- bereichZuordnung[bereichName][ftName] = true

function DL_Filter:toggleBereichZuordnung(bereich, ftName, currentlyZugeordnet)
    if self.bereichZuordnung == nil then self.bereichZuordnung = {} end
    if currentlyZugeordnet then
        -- Entfernen
        if self.bereichZuordnung[bereich] ~= nil then
            self.bereichZuordnung[bereich][ftName] = nil
        end
    else
        -- Hinzufügen — zuerst aus anderen Bereichen entfernen
        for ber, fts in pairs(self.bereichZuordnung) do
            fts[ftName] = nil
        end
        if self.bereichZuordnung[bereich] == nil then
            self.bereichZuordnung[bereich] = {}
        end
        self.bereichZuordnung[bereich][ftName] = true
    end
    -- Manuelle Verschiebung durch den Spieler -> ab jetzt nie mehr automatisch überschreiben
    if not self.userPersonalized then
        self.userPersonalized = true
    end
    -- Kein eager saveBereiche()/saveBereichZuordnung() mehr -- zentral ueber ItemSystem.save-Hook
end

-- ── Bereiche-Definition: Name + Order aus XML laden/speichern ────────────────
-- XML: dispoList_bereiche_def.xml im Savegame-Ordner
-- Format: <bereiche> <bereich name="Getreide" order="1"/> ... </bereiche>

function DL_Filter:saveBereiche()
    if self.xmlPath == nil then return end
    local defPath = self.xmlPath:gsub("dispoList_filter.xml", "dispoList_bereiche_def.xml")
    local xml = createXMLFile("DL_BereicheDef", defPath, "bereiche")
    if xml == nil then return end
    -- Erst-Flag: markiert dass User-Setup bereits durchgeführt wurde
    setXMLBool(xml, "bereiche#initialSetupDone", true)
    -- Erststart-Dialog: wurde er schon einmal gezeigt? (persistent, verhindert Wieder-Anzeige bei jedem Spielstart)
    setXMLBool(xml, "bereiche#presetDialogShown", self.presetDialogShown == true)
    -- Personalisierung: hat der Spieler manuell FillTypes verschoben? Schützt vor Preset-Überschreiben
    setXMLBool(xml, "bereiche#userPersonalized", self.userPersonalized == true)
    -- Aktives Preset: "ZL", "GIANTS", "SELBST", "" = noch nicht gewählt
    setXMLString(xml, "bereiche#activePreset", self.activePreset or "")
    local bereiche = {}
    for name, data in pairs(DispoList.BEREICHE) do
        table.insert(bereiche, {name=name, order=data.order or 99})
    end
    table.sort(bereiche, function(a,b) return a.order < b.order end)
    for i, ber in ipairs(bereiche) do
        local base = string.format("bereiche.bereich(%d)", i-1)
        setXMLString(xml, base .. "#name",  ber.name)
        setXMLString(xml, base .. "#order", tostring(ber.order))
    end
    -- Gelöschte hardcodierte Bereiche speichern
    local di = 0
    for name, _ in pairs(DispoList.BEREICHE_DELETED or {}) do
        local base = string.format("bereiche.deleted(%d)", di)
        setXMLString(xml, base .. "#name", name)
        di = di + 1
    end
    saveXMLFile(xml)
    delete(xml)
end

function DL_Filter:loadBereiche()
    -- Schritt 1: BEREICHE immer aus BEREICHE_DEFAULT aufbauen
    DispoList.BEREICHE = {}
    if DispoList.BEREICHE_DEFAULT == nil then
        print("## DL_Filter: FEHLER BEREICHE_DEFAULT ist nil!")
        return false
    end
    for name, data in pairs(DispoList.BEREICHE_DEFAULT) do
        DispoList.BEREICHE[name] = {
            order     = data.order,
            fillTypes = {},  -- FillTypes kommen aus Giants-Zuordnung, nicht aus Default
        }
    end

    if self.xmlPath == nil then return false end
    local defPath = self.xmlPath:gsub("dispoList_filter.xml", "dispoList_bereiche_def.xml")
    local defExists = fileExists(defPath)
    Logging.info("[DispoList] loadBereiche(): fileExists(%s)=%s", tostring(defPath), tostring(defExists))

    if not defExists then
        -- Datei nicht gefunden — entweder echter Erststart oder OneDrive-Sync-Problem.
        -- Kein eager saveBereiche() mehr hier: wir schreiben NICHTS beim Laden mehr,
        -- nur noch einmalig zentral beim naechsten ItemSystem.save (offizieller
        -- Speicherpunkt). Das verhindert, dass wir bei einem falschen "nicht gefunden"
        -- (Sync-Timing) sofort mit leeren Defaults ueberschreiben.
        local bzPath   = self.xmlPath:gsub("dispoList_filter.xml", "dispoList_bereiche.xml")
        local settPath = self.xmlPath:gsub("dispoList_filter.xml", "dispoList_settings.xml")
        -- Auch dispoList_filter.xml selbst als Nachweis akzeptieren
        local hatDlXml = fileExists(bzPath) or fileExists(settPath) or fileExists(self.xmlPath)
        if not hatDlXml then
            DL_Filter.isFirstRun = true
            Logging.info("[DispoList] loadBereiche(): keine andere DL-XML vorhanden -> echter Erststart")
        else
            Logging.info("[DispoList] loadBereiche(): !! Bereiche-Def fehlt aber andere DL-XMLs vorhanden (OneDrive-Sync/tempsavegame?) -- kein Reset !!")
        end
        return false
    end

    local xml = loadXMLFile("DL_BereicheDef", defPath)
    if xml == nil then return false end

    -- initialSetupDone Flag — nur noch für Kompatibilität mit alten Savegames
    local setupDone = getXMLBool(xml, "bereiche#initialSetupDone") == true
    -- Neue persistente Flags lesen (fehlen sie in der XML, liefert getXMLBool nil -> false)
    self.presetDialogShown = getXMLBool(xml, "bereiche#presetDialogShown") == true
    self.userPersonalized  = getXMLBool(xml, "bereiche#userPersonalized") == true
    self.activePreset      = getXMLString(xml, "bereiche#activePreset") or ""
    if not setupDone then
        local hasBereiche = hasXMLProperty(xml, "bereiche.bereich(0)")
        delete(xml)
        -- Kein eager saveBereiche() mehr -- naechster ItemSystem.save schreibt korrekt
        if not hasBereiche then
        end
        return true
    end

    -- Schritt 2: Blacklist laden — gelöschte Bereiche aus BEREICHE entfernen
    DispoList.BEREICHE_DELETED = {}
    local di = 0
    while true do
        local base = string.format("bereiche.deleted(%d)", di)
        if not hasXMLProperty(xml, base) then break end
        local name = getXMLString(xml, base .. "#name")
        if name ~= nil and name ~= "Sonstiges" then
            DispoList.BEREICHE_DELETED[name] = true
            DispoList.BEREICHE[name] = nil
        end
        di = di + 1
    end

    -- Schritt 3: Order-Werte und neue Bereiche aus XML laden
    local i = 0
    while true do
        local base = string.format("bereiche.bereich(%d)", i)
        if not hasXMLProperty(xml, base) then break end
        local name     = getXMLString(xml, base .. "#name")
        local orderStr = getXMLString(xml, base .. "#order")
        local order    = (orderStr ~= nil and tonumber(orderStr)) or (i+1)
        if name ~= nil and name ~= "" and not DispoList.BEREICHE_DELETED[name] then
            if DispoList.BEREICHE[name] ~= nil then
                -- Order aus XML übernehmen
                DispoList.BEREICHE[name].order = order
            else
                -- Neu erstellter Bereich (nicht in DEFAULT) — leerer Bereich
                DispoList.BEREICHE[name] = {order=order, fillTypes={}}
            end
        end
        i = i + 1
    end

    delete(xml)
    return true
end

-- Preset anwenden: Bereiche + Zuordnung aus Preset-Tabelle übernehmen
function DL_Filter:applyPreset(preset)
    if preset == nil then return end
    -- Bereiche aus Preset aufbauen
    DispoList.BEREICHE = {}
    for name, data in pairs(preset) do
        DispoList.BEREICHE[name] = {
            order     = data.order,
            fillTypes = data.fillTypes or {},
        }
    end
    -- Zuordnung aus Preset übernehmen
    self.bereichZuordnung = {}
    for name, data in pairs(preset) do
        self.bereichZuordnung[name] = {}
        for _, ftName in ipairs(data.fillTypes or {}) do
            self.bereichZuordnung[name][ftName] = true
        end
    end
    -- Kein eager saveBereiche()/saveBereichZuordnung() mehr -- zentral ueber ItemSystem.save-Hook
    -- Danach Delta für neue Karten-FillTypes
    self:deltaAssignFillTypes()
end

-- Zentrallager-basierte Auto-Zuordnung (FedAction Pattern: Zentrallager_X.xml)
function DL_Filter:autoAssignFromZentrallager()
    if g_currentMission == nil then return end
    local myFarmId = g_currentMission:getFarmId()
    local added = 0

    -- FedAction Dateiname → Bereichsname Mapping
    local FILENAME_TO_BEREICH = {
        Getreide     = "Schuettgut",   -- Getreide ist Giants BULK = Schuettgut
        Fluessig     = "Fluessig",
        Kalt         = "Kuehlung",
        Lebensmittel = "Lebensmittel",
        Obst         = "ObstGemuese",
        Werkstoffe   = "Werkstoffe",
    }

    -- Bereits zugeordnete FillTypes (User-Daten heilig)
    local alreadyAssigned = {}
    for _, zuordnung in pairs(self.bereichZuordnung) do
        for ftName, active in pairs(zuordnung) do
            if active then alreadyAssigned[ftName] = true end
        end
    end

    for _, placeable in ipairs(g_currentMission.placeableSystem.placeables) do
        if placeable.ownerFarmId == myFarmId then
            local zlSpec = nil
            for key, val in pairs(placeable) do
                if type(key) == "string" and type(val) == "table" then
                    if key:find("extendedProductionPoint") or key:find("ExtendedProductionPoint") then
                        zlSpec = val; break
                    end
                end
            end
            if zlSpec ~= nil and zlSpec.productionPoint ~= nil then
                local pp = zlSpec.productionPoint
                if pp.storage ~= nil and pp.storage.fillLevels ~= nil then
                    -- FedAction Pattern prüfen
                    local cfg = tostring(placeable.configFileName or "")
                    local zlKey = cfg:match("Zentrallager_(%w+)%.xml")
                    if zlKey ~= nil then
                        local bereichName = FILENAME_TO_BEREICH[zlKey] or zlKey
                        -- Bereich anlegen falls nicht vorhanden
                        if DispoList.BEREICHE[bereichName] == nil then
                            local maxOrder = 0
                            for _, b in pairs(DispoList.BEREICHE) do
                                if b.order > maxOrder then maxOrder = b.order end
                            end
                            DispoList.BEREICHE[bereichName] = { order = maxOrder + 1, fillTypes = {} }
                            self.bereichZuordnung[bereichName] = self.bereichZuordnung[bereichName] or {}
                        end
                        -- FillTypes des Storages zuordnen
                        for idx, _ in pairs(pp.storage.fillLevels) do
                            local ft = g_fillTypeManager:getFillTypeByIndex(idx)
                            if ft ~= nil and ft.name ~= nil and not alreadyAssigned[ft.name] then
                                self.bereichZuordnung[bereichName] = self.bereichZuordnung[bereichName] or {}
                                self.bereichZuordnung[bereichName][ft.name] = true
                                alreadyAssigned[ft.name] = true
                                added = added + 1
                            end
                        end
                    end
                end
            end
        end
    end

    if added > 0 then
        -- Kein eager save mehr -- zentral ueber ItemSystem.save-Hook
        DispoList.deltaNewCount = added
    end
end

-- Delta-Zuordnung: nur NEUE Karten-FillTypes ergänzen, User-Daten bleiben heilig
-- Läuft bei jedem Spielstart — erkennt neue FillTypes durch Mods/DLCs automatisch
function DL_Filter:deltaAssignFillTypes()
    self.bereichZuordnung = self.bereichZuordnung or {}

    -- Giants-Physik-Kategorien → Bereiche Mapping (nur physikalische Typen, keine SELLINGSTATION)
    local CAT_TO_BEREICH = {
        BULK                = "Schuettgut",
        LIQUID              = "Fluessig",
        PIECE               = "Stueckgut",
        ANIMAL              = "Tier",
        HORSE               = "Tier",
        FISH                = "Tier",
        PRODUCT             = "Produkte",
        SELLINGSTATION_WOOD = "Holz",
    }

    -- Alle Bereiche initialisieren
    for name, _ in pairs(DispoList.BEREICHE) do
        if self.bereichZuordnung[name] == nil then
            self.bereichZuordnung[name] = {}
        end
    end

    -- Bereits zugeordnete FillTypes sammeln (User-Daten)
    local alreadyAssigned = {}
    for _, zuordnung in pairs(self.bereichZuordnung) do
        for ftName, active in pairs(zuordnung) do
            if active then alreadyAssigned[ftName] = true end
        end
    end

    -- Nur FillTypes die tatsächlich auf der Karte vorkommen (Verkaufsstationen)
    local mapFillTypes = {}
    if g_currentMission and g_currentMission.storageSystem then
        for _, station in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
            if station:isa(SellingStation) and not station.hideFromPricesMenu then
                if station.ownerFarmId ~= g_currentMission:getFarmId() then
                    for ftIdx, accepted in pairs(station.acceptedFillTypes) do
                        if DL_Filter.isAcceptedByStation(station, ftIdx) then
                            local ft = g_fillTypeManager:getFillTypeByIndex(ftIdx)
                            if ft ~= nil and ft.name ~= nil then
                                mapFillTypes[ft.name] = ftIdx
                            end
                        end
                    end
                end
            end
        end
    end

    -- Delta: neue Karten-FillTypes via Giants-Kategorie zuordnen
    local added = 0
    for ftName, ftIdx in pairs(mapFillTypes) do
        if not alreadyAssigned[ftName] then
            local bereichName = nil
            if g_fillTypeManager.categoryNameToFillTypes ~= nil then
                for catName, indices in pairs(g_fillTypeManager.categoryNameToFillTypes) do
                    if indices[ftIdx] and CAT_TO_BEREICH[catName] then
                        bereichName = CAT_TO_BEREICH[catName]
                        break
                    end
                end
            end
            if bereichName ~= nil and DispoList.BEREICHE[bereichName] ~= nil then
                self.bereichZuordnung[bereichName][ftName] = true
                added = added + 1
            end
        end
    end

    -- Neue Giants-FillTypes die NICHT auf der Karte vorkommen (kein Verkaufsort)
    local notOnMap = 0
    if g_fillTypeManager ~= nil and g_fillTypeManager.categoryNameToFillTypes ~= nil then
        for catName, indices in pairs(g_fillTypeManager.categoryNameToFillTypes) do
            if CAT_TO_BEREICH[catName] then
                for ftIdx, _ in pairs(indices) do
                    local ft = g_fillTypeManager.fillTypes[ftIdx]
                    if ft ~= nil and ft.name ~= nil then
                        if not alreadyAssigned[ft.name] and not mapFillTypes[ft.name] then
                            notOnMap = notOnMap + 1
                        end
                    end
                end
            end
        end
    end

    if added > 0 then
        -- Kein eager save mehr -- zentral ueber ItemSystem.save-Hook
        DispoList.deltaNewCount = added
        DispoList.deltaNotOnMap = 0
    elseif notOnMap > 0 then
        DispoList.deltaNewCount = 0
        DispoList.deltaNotOnMap = notOnMap
    else
        DispoList.deltaNewCount = 0
        DispoList.deltaNotOnMap = 0
    end
end

function DL_Filter:saveBereichZuordnung()
    if self.xmlPath == nil then return end
    local bzPath = self.xmlPath:gsub("dispoList_filter.xml", "dispoList_bereiche.xml")
    local xml = createXMLFile("DL_Bereiche", bzPath, "dispoListBereiche")
    if xml == nil then return end
    local i = 0
    if self.bereichZuordnung ~= nil then
        for bereich, fts in pairs(self.bereichZuordnung) do
            for ftName, active in pairs(fts) do
                if active then
                    local base = string.format("dispoListBereiche.zuordnung(%d)", i)
                    setXMLString(xml, base .. "#bereich", bereich)
                    setXMLString(xml, base .. "#fillType", ftName)
                    i = i + 1
                end
            end
        end
    end
    saveXMLFile(xml)
    delete(xml)
end

function DL_Filter:loadBereichZuordnung()
    self.bereichZuordnung = {}
    self.deaktivierteStationsBereiche = {}  -- {stName: {bereichName: true}}
    if self.xmlPath == nil then return end
    local bzPath = self.xmlPath:gsub("dispoList_filter.xml", "dispoList_bereiche.xml")
    local exists = fileExists(bzPath)
    Logging.info("[DispoList] loadBereichZuordnung(): fileExists(%s)=%s", tostring(bzPath), tostring(exists))
    if not exists then return end
    local xml = loadXMLFile("DL_Bereiche", bzPath)
    if xml == nil then return end
    local i = 0
    while true do
        local base = string.format("dispoListBereiche.zuordnung(%d)", i)
        if not hasXMLProperty(xml, base) then break end
        local bereich  = getXMLString(xml, base .. "#bereich")
        local fillType = getXMLString(xml, base .. "#fillType")
        if bereich ~= nil and fillType ~= nil then
            if self.bereichZuordnung[bereich] == nil then
                self.bereichZuordnung[bereich] = {}
            end
            self.bereichZuordnung[bereich][fillType] = true
        end
        i = i + 1
    end
    delete(xml)
end

-- ─── Pause-Einstellung speichern/laden ───────────────────────────────────────
function DL_Filter:savePauseSetting()
    if self.xmlPath == nil then return end
    local settPath = self.xmlPath:gsub("dispoList_filter.xml", "dispoList_settings.xml")
    local xml = createXMLFile("DL_Settings", settPath, "dispoListSettings")
    if xml == nil then return end
    setXMLBool(xml,   "dispoListSettings.filterPause#enabled",  DispoList.filterPauseEnabled == true)
    setXMLString(xml, "dispoListSettings.reserveStunden#value",   tostring(DispoList.reserveStunden or 24))
    setXMLString(xml, "dispoListSettings.refreshInterval#value",  tostring(DispoList.refreshInterval or 5000))
    -- Lagertypen-Einstellungen
    if DispoList.activeLagertypen ~= nil then
        for key, val in pairs(DispoList.activeLagertypen) do
            setXMLBool(xml, "dispoListSettings.lagertypen." .. key .. "#active", val ~= false)
        end
    end
    -- ZL-Gebaeude-Auswahl fuer Stern/CW-Filter speichern (Namen als Attribut,
    -- nicht als Tag-Name -- Gebaeudenamen koennen Leerzeichen/Umlaute haben)
    if DispoList.activeZlGebaeude ~= nil then
        local zi = 0
        for name, val in pairs(DispoList.activeZlGebaeude) do
            local base = string.format("dispoListSettings.zlGebaeude.geb(%d)", zi)
            setXMLString(xml, base .. "#name",   name)
            setXMLBool(xml,   base .. "#active", val ~= false)
            zi = zi + 1
        end
    end
    -- Spalten-Sichtbarkeit speichern
    if DL_ColSettings ~= nil then
        local i = 0
        for key, visible in pairs(DL_ColSettings.visible) do
            local base = string.format("dispoListSettings.columns.col(%d)", i)
            setXMLString(xml, base .. "#key",     key)
            setXMLBool(xml,   base .. "#visible",  visible == true)
            i = i + 1
        end
    end
    saveXMLFile(xml)
    delete(xml)
end

function DL_Filter:loadPauseSetting()
    DispoList.filterPauseEnabled = false
    DispoList.reserveStunden     = 24
    if self.xmlPath == nil then return end
    local settPath = self.xmlPath:gsub("dispoList_filter.xml", "dispoList_settings.xml")
    local exists = fileExists(settPath)
    Logging.info("[DispoList] loadPauseSetting(): fileExists(%s)=%s", tostring(settPath), tostring(exists))
    if not exists then return end
    local xml = loadXMLFile("DL_Settings", settPath)
    if xml == nil then return end
    DispoList.filterPauseEnabled = getXMLBool(xml, "dispoListSettings.filterPause#enabled") == true
    local rsStr = getXMLString(xml, "dispoListSettings.reserveStunden#value")
    if rsStr ~= nil then
        DispoList.reserveStunden = math.max(1, math.min(168, tonumber(rsStr) or 24))
    end
    -- Lagertypen-Einstellungen laden
    local lagerKeys = {"ZENTRALLAGER","SILO","SILO_EXTENSION","HUSBANDRY","MANURE","BEEHIVE","BALE","PALLET","PRODUCTION_OUT"}
    for _, key in ipairs(lagerKeys) do
        local xmlKey = "dispoListSettings.lagertypen." .. key .. "#active"
        if hasXMLProperty(xml, xmlKey) then
            DispoList.activeLagertypen[key] = getXMLBool(xml, xmlKey)
        end
    end
    -- ZL-Gebaeude-Auswahl laden
    do
        local zi = 0
        while true do
            local base = string.format("dispoListSettings.zlGebaeude.geb(%d)", zi)
            if not hasXMLProperty(xml, base) then break end
            local name   = getXMLString(xml, base .. "#name")
            local active = getXMLBool(xml,   base .. "#active")
            if name ~= nil then
                DispoList.activeZlGebaeude[name] = (active ~= false)
            end
            zi = zi + 1
        end
    end

    local riStr = getXMLString(xml, "dispoListSettings.refreshInterval#value")
    if riStr ~= nil then
        local ri = tonumber(riStr) or 5000
        -- Nur gültige Werte: 0=manuell, 5000, 15000, 30000, 60000, 120000
        local valid = {[0]=true,[5000]=true,[15000]=true,[30000]=true,[60000]=true,[120000]=true}
        DispoList.refreshInterval = valid[ri] and ri or 5000
    end
    -- Spalten-Sichtbarkeit laden
    if DL_ColSettings ~= nil then
        local i = 0
        while true do
            local base = string.format("dispoListSettings.columns.col(%d)", i)
            if not hasXMLProperty(xml, base) then break end
            local key     = getXMLString(xml, base .. "#key")
            local visible = getXMLBool(xml,   base .. "#visible")
            if key ~= nil then
                DL_ColSettings.visible[key] = (visible == true)
            end
            i = i + 1
        end
    end
    delete(xml)
end
