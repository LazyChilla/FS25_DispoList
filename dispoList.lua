--
-- FS25 - DispoList v2.0
-- Dispositionsliste: Zentrallager-Bestand + meistbietende Verkaufsstation
-- Basiert auf HappyLooser HUD System
--

DispoList = {}
DispoList.Debug = false
DispoList.isInit = false

-- ─── Farb-Theme (Single Source of Truth) ────────────────────────────────────
-- Geteilte, semantisch EINDEUTIGE Icon-Farben: einmal definiert (statt 16x das
-- gleiche Grau reingetippt) und einmal alloziert (statt pro Frame im Draw neu).
-- BEWUSST nur die geteilten Icon-Zustandsfarben. Spalten-/Marker-/Zustandsfarben
-- bleiben lokal: gleiche RGB heisst NICHT gleiche Bedeutung (z.B. Gruen fuer
-- "genug Bestand" ist NICHT dasselbe Konzept wie "Filter aktiv") -> kein
-- Falsch-DRY, das voneinander unabhaengige Dinge aneinanderkoppelt.
DL_Colors = {
    iconIdle        = {0.65, 0.65, 0.65, 1.0},  -- Icon inaktiv (Standard-Grau)
    iconHover       = {0.95, 0.95, 0.95, 1.0},  -- Icon unter dem Mauszeiger
    iconActive      = {0.2,  0.8,  1.0,  1.0},  -- Toggle aktiv (blau: Sortierung/Suche/Settings)
    iconActiveGreen = {0.1,  1.0,  0.1,  1.0},  -- Toggle aktiv (gruen: Filter/ZL/Baumaterial)
    -- Draw-Loop-Hintergruende (pro Frame gezeichnet -> als Konstante, nicht neu allozieren)
    panelBg         = {0.03, 0.03, 0.03, 0.95}, -- Icon-Zeilen-Hintergrund (fast schwarz)
    rowSel          = {0.08, 0.30, 0.08, 0.95}, -- ausgewaehlte Listenzeile (gruen)
    rowBg           = {0.04, 0.08, 0.04, 0.70}, -- normale Listenzeile (dunkel)
    -- Textfarben (wiederkehrend, via setTextColor(unpack(...)) genutzt). Werte 1:1
    -- erhalten -- benennen, nicht plaetten: die Grau-Abstufung ist Absicht (Hierarchie).
    white           = {1.0,  1.0,  1.0,  1.0},  -- Standardtext / Reset
    gruen           = {0.1,  1.0,  0.1,  1.0},  -- positiv: genug Bestand / aktiv / Marker
    gruenHead       = {0.0,  1.0,  0.2,  1.0},  -- Ueberschriften/Labels im Filter-Panel
    rot             = {1.0,  0.1,  0.1,  1.0},  -- EIN Rot (Fehler / aus / loeschen / Wert=0)
    grauHell        = {0.75, 0.75, 0.75, 1.0},  -- Text hell
    grau            = {0.7,  0.7,  0.7,  1.0},  -- Text normal (gedaempft)
    grau65          = {0.65, 0.65, 0.65, 1.0},  -- Text neutral
    grauMit         = {0.5,  0.5,  0.5,  1.0},  -- Text sekundaer / Hinweis
    grauDim         = {0.45, 0.45, 0.45, 1.0},  -- Text sehr gedaempft (Version/Fussnote)
    trenner         = {0.35, 0.35, 0.35, 1.0},  -- Trenner "|" / dezente Linien
    gold            = {0.95, 0.85, 0.1,  1.0},  -- Preis/Wert (gold)
    lagerBlau       = {0.0,  0.85, 1.0,  1.0},  -- Lager-Aufklappen / "v"-Marker (blau)
    bauLimit        = {1.0,  0.55, 0.1,  1.0},  -- Baustelle/Lager-Station (limitierte Annahme, kein echter Markt) - orange
}

DispoList.timePast       = 0
DispoList.refreshInterval  = 5000 -- ms: 5000/15000/30000/60000/120000/0=manuell (Default: 5 Sekunden)
DispoList.refreshSinceMs   = 0     -- ms seit letztem Refresh (für Countdown-Anzeige)
DispoList.CurrentItems = {}
DispoList.DisplayItems = {}
DispoList.modDir = g_currentModDirectory
DispoList.searchActive = false
DispoList.searchText   = ""
DispoList.searchDirty  = false
DispoList.searchCursorTimer = 0
DispoList.searchCursorVisible = true
-- FilterBox Suche (separate Variablen)
DispoList.filterSearchActive  = false
DispoList.filterSearchText    = ""
DispoList.searchFocused       = false   -- Suchfeld hat Fokus: faengt Tasten ab + Input-Kontext gesetzt
DispoList.searchContextPushed = false   -- Input-Kontext "DISPOLIST_SEARCH" aktuell aktiv?
DispoList.searchDebug         = false   -- Fokus-/Kontext-Diagnose ins log.txt (nur zum Debuggen auf true)
DispoList.filterSearchCursorTimer   = 0
DispoList.filterSearchCursorVisible = true

DispoList.dlBackspaceCooldown    = nil    -- Cooldown für Backspace-Repeat
DispoList.filterResetConfirm     = false  -- Default-Reset Bestätigung
DispoList.sortByValue        = false  -- false=A-Z, true=Wert absteigend
DispoList.deltaNewCount      = 0     -- Anzahl neu zugeordneter FillTypes (Delta-Zuordnung)
DispoList.deltaNotOnMap      = 0     -- Anzahl neuer FillTypes ohne Verkaufsstelle auf der Karte
DispoList.zlHinweisGesehen   = false -- Zentrallager-Hinweis wurde gesehen, nicht mehr anzeigen
DispoList._lastFoundZentrallager = nil  -- letzter bekannter ZL-Zaehler fuer Delta-Erkennung
DispoList.filterSnapshot     = nil    -- Snapshot für Rückgängig
DispoList.filterResetConfirm = false  -- Sicherheitsabfrage aktiv
DispoList.filterResetDone    = false  -- true nach dem Löschen
DispoList.contextMenu        = nil    -- Kontextmenü {ftName, title, posX, posY, bereiche}
DispoList.dlSelectedFt        = nil    -- selektierter FillType für Click-Select
DispoList.dlSelectedFtTitle   = nil    -- lesbarer Titel des selektierten FillType
DispoList.dlSelectedFtBereich = nil    -- Bereich des selektierten FillType
DispoList.dlClickCooldown     = nil    -- Zeitstempel letzter Klick (gegen Mehrfach-Auslösung)
DispoList.lagerViewFt         = nil    -- aufgeklappter FillType für Lager-Drill-Down (ftName oder nil)
DispoList.lagerCache          = {}     -- gecachte Lager-Daten pro FillType {[ftName]={name,level,capacity}}
DispoList.baustelleMode       = false  -- Baustellen-Ansicht (Kran-Toggle) an/aus
DispoList.baustelleRows       = {}     -- gecachte Baustellen-Zeilen (pro Refresh gebaut): {kind="proj"|"mat", ...}
DispoList.baustelleViewFt     = nil    -- in Baustellen-Ansicht aufgeklapptes Material (Lager-Drilldown), nil = zu
DispoList.kassettenMode       = false  -- Kassetten-Shops-Ansicht (Geldkassette-Toggle) an/aus
DispoList.kassettenRows       = {}     -- gecachte Kassetten-Shop-Zeilen (pro Refresh): {kind="shop"|"ware", ...}
DispoList.kassettenLeer       = {}     -- Shops mit leerem Eingang (fuer Ticker)
DispoList.kassettenTickerIds  = {}     -- {[Shopname]=msgId} laufende Ticker-Meldungen
DispoList.reserveStunden      = 24     -- Zeitreserve für Fabrik-Puffer in Stunden
DispoList.ecEnabled           = true   -- Baustellen-Bedarf (EverythingConstructable) abziehen? Default AN
DispoList.lastEcProjectCount  = 0      -- Anzahl offener Baustellen (letzter Scan, fuer Settings-Anzeige)

-- ─── Bereich-Zuordnung ───────────────────────────────────────────────────────
-- ─── Bereiche Default (Vorlage für Erststart) ───────────────────────────────
-- Wird NICHT direkt verwendet — loadBereiche() baut BEREICHE daraus auf
DispoList.BEREICHE_DEFAULT = {
    -- Nur Struktur (Namen + Reihenfolge) — FillType-Zuordnung erfolgt beim Erststart via Giants-Physik-Kategorien
    ["Schuettgut"]     = { order=1 },
    ["Fluessig"]       = { order=2 },
    ["Tier"]           = { order=3 },
    ["Stueckgut"]      = { order=4 },
    ["Produkte"]       = { order=5 },
    ["Holz"]           = { order=6 },
    ["Unverkaeuflich"] = { order=99 },  -- geschützt, nicht in Hauptliste
}

DispoList._zlFilterActive = false  -- Toggle: nur ZL-Bereiche anzeigen

-- Erweitertes Preset: NF Marsch / Karten mit Zentrallager (aus v97x)
DispoList.BEREICHE_PRESET_ERWEITERT = {
    ["Fluessig"]       = { order=2,  fillTypes={"ADVOCAAT","APPLEJUICE","BARLEYBEER","BARLEYBEER_BOTTLE","CANOLA_OIL","CARROTJUICE","CHERRYJUICE","FRUITBRANDY","GRAINALCOHOL","GRAPEJUICE","HEMP_OIL","LAVENDER_OIL","LINSEED_OIL","MAIZE_OIL","MALTBEER","MILLETBEER","MOLASSES","OATMILK","OLIVE_OIL","PEARJUICE","PLUMJUICE","POPPY_OIL","PUMPKIN_SEEDSOIL","RASPBERRYLIMES","REDWINE","RICE_OIL","SILAGE_ADDITIVE","SOYBEAN_OIL","SOYMILK","STRAWBERRYLIMES","SUNFLOWER_OIL","TOMATOJUICE","VINEGAR","VODKA","WHEATBEER","WHEATBEER_BOTTLE","WHEY","WHISKEY"} },
    ["Kuehlung"]       = { order=3,  fillTypes={"BEEFMEAT","BUFFALOMILK_BOTTLED","BUFFALOMOZZARELLA","BUTTER","CAKE","CHEESE","CHICKENMEAT","COD","CODFILLET","CREAM","CRABS","CRABSALAD","CREAMEDSPINACH","CROQUETTES","EEL","FISHANDCHIPS","FRENCHFRIES","FRESHCHEESE","GOATCHEESE","GOATMILK","GOATMILK_BOTTLED","HAM","HERRING","HERRINGTOMATENSAUCE","HUMMER","ICECREAM","ICECRUSHED","LAMB","MILK_BOTTLED","MOZZARELLA","PIZZA","PLAICE","PLAICEFILLET","POPSICLE","PORKMEAT","POTATOPANCAKE","POTATOSALAD","QUARK","READYMEAL","SALMON","SAUSAGE","SMOKED_EEL","SMOKED_SALMON","SMOKED_TROUT","SPINACH_BAGS","TORTELLONI","TROUT","YOGURT"} },
    ["Lebensmittel"]   = { order=4,  fillTypes={"APPLESAUCE","BAKERY_PRODUCT","BARLEYMALT","BEANSOUP","BLACKBERRYJAM","BRAN","BREAD","BUCKWHEATFLOUR","BUN","CABBAGESOUP","CEREAL","CHERRYJAM","CHILICONCARNE","EGG","FERMENTEDNAPACABBAGE","FLOUR","FRIEDONION","HONEY","KETCHUP","MAYONAISSE","MILLETMALT","MILLETPORRIDGE","MIRABELLESJAM","MUSHROOMSOUP","MUSTARDGLASS","NOODLES","NOODLESOUP","OATMEAL","ONIONSALT","ONIONSOUP","PEACHJAM","PEASOUP","PLUMJAM","POPCORN","POTATOCHIPS","PUMPKINSOUP","PUMPKIN_SEEDS","RASPBERRYJAM","RICEFLOUR","RICEROLLS","RICE_BAGS","RICE_BOXES","ROCKCANDIS","RYEFLOUR","SEASALT","SOUPCANSBEETROOT","SOUPCANSCARROTS","SOUPCANSMIXED","SOUPCANSPARSNIP","SOUPCANSPOTATO","SOYSCHNITZEL","SPAGHETTI","SPELTFLOUR","STRAWBERRYJAM","SUGAR","SUGARCUBES","TOMATOSAUCE","TOMATOSOUP","WHEATMALT","YEAST"} },
    ["ObstGemuese"]    = { order=5,  fillTypes={"APPLE","BLACKBERRY","CANNED_PEAS","CARROTBAG","CAULIFLOWER","CHERRY","CHILLI","CURRANTS","ENOKI","GARLIC","GRAPE","JARRED_GREENBEAN","LETTUCE","MIRABELLES","MUSHROOMS","NAPACABBAGE","OLIVE","ONIONBAG","OYSTER","PEACH","PEAR","PLUM","PRESERVEDBEETROOT","PRESERVEDCARROTS","PRESERVEDPARSNIP","PUMPKIN","RAISINS","RASPBERRY","REDCABBAGE","REDONION","SPRING_ONION","STRAWBERRY","TOMATO","VEGATABLECORN","WASHEDPOTATOES"} },
    ["Schuettgut"]     = { order=1,  fillTypes={"BARLEY","BEETROOT","BUCKWHEAT","CANOLA","CARROT","COTTON","FIELDGRASS","GREENBEAN","HEMP","LENTILS","LINSEED","MAIZE","MUSTARD","OAT","ONION","PARSNIP","PEA","PEAS","POPPY","POTATO","REDBEET","RICE","RICELONGGRAIN","RYE","SAND","SORGHUM","SOYBEAN","SPELT","SPINACH","STONE","SUGARBEET","SUGARCANE","SUNFLOWER","TOBACCO","TRITICALE","WHEAT","WOODCHIPS"} },
    ["Werkstoffe"]     = { order=6,  fillTypes={"BALE_NET","BALE_TWINE","BARKMULCH","BARREL","BATHTUB","BEEHIVE","BIRDFOOD","BOARDS","BOTTLE","BUCKET","CARTONROLL","CATFOOD","CEMENT","CEMENTBRICKS","CHARCOAL","CLOTHES","CURB","DOGFOOD","DOWN","EMPTYPALLET","EMPTYPALLET_OLD","FABRIC","FISHMEAL","FISHFOOD","FLOWERPOT","FURNITURE","GLASS","GLASSPANES","HAYPELLETS","INSULATION","LEATHER","OLDGLASS","OSBPALLET","PAPERROLL","PAVINGSTONE","PAVINGSTONE_RED","PLANKS","PLYWOOD","POT","PREFABWALL","ROOFPLATES","ROPE","SHOES","SIDE_PRODUCT","STRAWHAT","STRAWPELLETS","TOILETPAPER","TURF","WASTE_PAPER","WINDOW","WOOD","WOODBEAM","WOODENBOX","WOODPELLETS","WOODSHOES","WOOL"} },
    ["Ballen"]         = { order=8,  fillTypes={"GRASS_BALE","GRASS_WINDROW_BALE","HAY","HAY_BALE","HEMP_BALE","SILAGE_BALE","STRAW_BALE","ROUNDBALE","SQUAREBALE","COTTON"} },
    ["MilchTier"]      = { order=9,  fillTypes={"BUFFALOMILK","CHICKEN","COW","GOAT","HORSE","MILK","PIG","RABBIT","SHEEP","WOOL_ANIMAL"} },
    ["Futtermittel"]   = { order=10, fillTypes={"CHAFF","DRYGRASS","FORAGE","FORAGE_MIXING","GRASS","GRASS_WINDROW","PIGFOOD","SILAGE","STRAW","STRAW_WINDROW"} },
    ["Betriebsstoffe"] = { order=11, fillTypes={"DEF","DIESEL","FERTILIZER","HERBICIDE","LIME","LIQUIDFERTILIZER","SEEDS"} },
    ["Duenger"]        = { order=12, fillTypes={"DIGESTATE","LIQUIDMANURE","MANURE","SLURRY"} },
    ["Forstwirtschaft"]= { order=13, fillTypes={"TREESAPLINGS","WOODCHIPS"} },
    ["Unverkaeuflich"] = { order=99, fillTypes={} },
}

-- BEREICHE: wird zur Laufzeit von loadBereiche() aufgebaut — NICHT hardcoded
DispoList.BEREICHE         = {}
DispoList.BEREICHE_DELETED = {}  -- Blacklist: gelöschte Bereiche
DispoList.VERSION          = "v1.4.0.0"-- Build-Version (in Icon-Zeile angezeigt)


-- Bereichsnamen-Uebersetzung fuer die ANZEIGE.
-- Der gespeicherte Name (Schluessel) bleibt unveraendert; nur die Anzeige wird
-- uebersetzt. Eigene Bereiche (nicht in der Tabelle) werden unveraendert gezeigt.
local DL_BEREICH_L10N = {
    Schuettgut="ber_schuettgut", Fluessig="ber_fluessig", Tier="ber_tier",
    Stueckgut="ber_stueckgut", Produkte="ber_produkte", Holz="ber_holz",
    Kuehlung="ber_kuehlung", Lebensmittel="ber_lebensmittel", ObstGemuese="ber_obstgemuese",
    Werkstoffe="ber_werkstoffe", Ballen="ber_ballen", MilchTier="ber_milchtier",
    Futtermittel="ber_futtermittel", Betriebsstoffe="ber_betriebsstoffe", Duenger="ber_duenger",
    Forstwirtschaft="ber_forstwirtschaft", Unverkaeuflich="ber_unverkaeuflich",
}
function DL_bereichLabel(name)
    if name == nil then return "" end
    local key = DL_BEREICH_L10N[name]
    if key ~= nil then return DL_t(key) end
    return name
end

-- ─── Lagertypen-Konfiguration ────────────────────────────────────────────────
-- Welche Lagertypen auf der Karte gefunden wurden (wird beim Start gescannt)
DispoList.foundLagertypen = {}
-- Welche Lagertypen der User aktiviert hat (gespeichert in settings.xml)
DispoList.activeLagertypen = {
    ZENTRALLAGER    = true,
    SILO            = true,
    SILO_EXTENSION  = true,
    HUSBANDRY       = true,
    MANURE          = true,
    BEEHIVE         = true,
    BUNKER          = true,   -- Fahrsilos (Grassilage, Stroh, Heu...)
    OBJEKTLAGER     = true,   -- Objektlager (Ballen/Paletten in Lagerhallen)
    BALE            = true,
    PALLET          = true,
    PRODUCTION_OUT  = true,   -- Fabrik-Ausgangslager (NEU)
}
-- Welche ZL-Gebaeude auf der Karte gefunden wurden (wird beim Scan befuellt)
DispoList.foundZlGebaeude = {}
-- Welche ZL-Gebaeude beim Stern/CW-Filter zaehlen sollen (Name -> true/false,
-- gespeichert in settings.xml). Fehlt ein Eintrag: Default AN.
DispoList.activeZlGebaeude = {}
DispoList.FILLTYPE_TO_BEREICH = {}
function DispoList.buildFillTypeToBereich()
    DispoList.FILLTYPE_TO_BEREICH = {}
    for bereichName, bereichData in pairs(DispoList.BEREICHE) do
        for _, ft in ipairs(bereichData.fillTypes) do
            DispoList.FILLTYPE_TO_BEREICH[ft] = {name=bereichName, order=bereichData.order}
        end
    end
end
-- buildFillTypeToBereich wird nach loadBereiche() aufgerufen (in loadMap)

function DispoList.getBereich(fillTypeName)
    if fillTypeName == nil then return {name="Sonstiges", order=99} end
    -- Manuelle Zuordnung aus DL_Filter hat Vorrang
    if DL_Filter ~= nil and DL_Filter.bereichZuordnung ~= nil then
        for bereichName, fts in pairs(DL_Filter.bereichZuordnung) do
            if fts[fillTypeName] == true then
                -- Bereich-Order aus BEREICHE holen
                local order = 99
                if DispoList.BEREICHE[bereichName] ~= nil then
                    order = DispoList.BEREICHE[bereichName].order or 99
                end
                return {name=bereichName, order=order}
            end
        end
    end
    -- Default-Zuordnung
    local b = DispoList.FILLTYPE_TO_BEREICH[string.upper(fillTypeName)]
    return b or {name="Sonstiges", order=99}
end

-- ─── Produktionsbedarf ───────────────────────────────────────────────────────
-- skipCashOutput=true ueberspringt die Kassetten-Shops (Output CASH): deren
-- eigener Verbrauch darf NICHT von "verfuegbar" abgezogen werden, sonst frisst
-- ein Hofladen sich selbst weg (er ist ja selbst Fabrik + Lieferziel).
function DispoList:getProductionDemandPerHour(skipCashOutput)
    local demand = {}
    if g_currentMission == nil then return demand end
    local myFarmId   = g_currentMission:getFarmId()
    local timeFactor = 1 / g_currentMission.environment.daysPerPeriod
    local chainMgr   = g_currentMission.productionChainManager
    if chainMgr == nil then return demand end

    local cashIdx = skipCashOutput and g_fillTypeManager:getFillTypeIndexByName("CASH") or nil

    local prodPoints = chainMgr:getProductionPointsForFarmId(myFarmId)
    if prodPoints ~= nil then
        for _, pp in pairs(prodPoints) do
            local isCashShop = false
            if cashIdx ~= nil then
                for _, prod in pairs(pp.productions or {}) do
                    for _, o in pairs(prod.outputs or {}) do
                        if o.type == cashIdx then isCashShop = true end
                    end
                end
            end
            if not isCashShop then
                local multi = 1
                if pp.sharedThroughputCapacity and #pp.activeProductions ~= 0 then
                    multi = 1 / #pp.activeProductions
                end
                for _, prod in pairs(pp.activeProductions) do
                    for _, input in pairs(prod.inputs) do
                        local ft  = input.type
                        local lph = prod.cyclesPerHour * input.amount * multi * timeFactor
                        demand[ft] = (demand[ft] or 0) + lph
                    end
                end
            end
        end
    end
    return demand
end

-- ─── Baustellen-Bedarf (EverythingConstructable) ────────────────────────────
-- Robuster Erkennungsweg (analog PrecisionFarming-Fix, Vorfall 06.07.):
-- g_currentMission.ecProjectManager direkt pruefen statt g_modIsLoaded[modName],
-- da der tatsaechliche Mod-Ordnername (z.B. bei editierten Varianten) vom
-- Giants-Standardnamen abweichen kann. ecProjectManager haengt unabhaengig
-- davon immer an derselben Stelle, sobald der Mod (egal wie benannt) laedt.
function DispoList:getConstructionDemand()
    local demand = {}
    DispoList.lastEcProjectCount = 0
    if not DispoList.ecEnabled then return demand end
    if g_currentMission == nil or g_currentMission.ecProjectManager == nil then return demand end

    local myFarmId = g_currentMission:getFarmId()
    local ok, projects = pcall(function()
        return g_currentMission.ecProjectManager:getProjectsForFarm(myFarmId)
    end)
    if not ok then
        print("[DispoList] Fehler bei getConstructionDemand(): " .. tostring(projects))
        return demand
    end

    local projectCount = 0
    for _, project in ipairs(projects or {}) do
        projectCount = projectCount + 1
        for _, mat in ipairs(project.materials or {}) do
            local open = (mat.amount or 0) - (mat.delivered or 0)
            if open > 0 and mat.fillTypeIndex ~= nil then
                demand[mat.fillTypeIndex] = (demand[mat.fillTypeIndex] or 0) + open
            end
        end
    end
    DispoList.lastEcProjectCount = projectCount
    return demand
end

-- ─── Baustellen-Ansicht: flache Zeilenliste pro Baustelle ────────────────────
-- Liefert eine flache Liste fuer die HUD-Baustellen-Ansicht (Kran-Toggle):
--   {kind="proj", name=<Baustellenname>}  -- Block-Ueberschrift
--   {kind="mat",  name=<Warenname>, needed=<offener Bedarf>, stock=<Gesamtbestand>}
-- Bewusst UNABHAENGIG von DispoList.ecEnabled (das ist nur der Reserve-Abzug in
-- der Verkaufsansicht) -- die Baustellen-Ansicht zeigt den Bedarf immer, sobald
-- EverythingConstructable laeuft. Projektname via project:getStoreItemName()
-- (verifiziert aus FarmAssistant/ConstructionScanner.lua). Stock je FillType aus
-- allStockLevels (Gesamtbestand, wird beim Refresh sowieso gebaut).
function DispoList:buildBaustelleRows(allStockLevels)
    local rows = {}
    if g_currentMission == nil or g_currentMission.ecProjectManager == nil then return rows end

    local myFarmId = g_currentMission:getFarmId()
    local ok, projects = pcall(function()
        return g_currentMission.ecProjectManager:getProjectsForFarm(myFarmId)
    end)
    if not ok then
        print("[DispoList] Fehler bei buildBaustelleRows(): " .. tostring(projects))
        return rows
    end

    for _, project in ipairs(projects or {}) do
        local matRows = {}
        for _, mat in ipairs(project.materials or {}) do
            local needed = (mat.amount or 0) - (mat.delivered or 0)
            if needed > 0 and mat.fillTypeIndex ~= nil then
                local ft    = g_fillTypeManager:getFillTypeByIndex(mat.fillTypeIndex)
                local nm    = (ft ~= nil and ft.title) or mat.fillTypeName or "?"
                local ftNm  = (ft ~= nil and ft.name) or mat.fillTypeName  -- interner Name fuer Lager-Aufklappen
                local stock = (allStockLevels ~= nil and allStockLevels[mat.fillTypeIndex]) or 0
                table.insert(matRows, {kind = "mat", name = nm, ftName = ftNm, needed = needed, stock = stock})
            end
        end
        -- Nach Deckungsgrad (Lager/Bedarf) absteigend sortieren: gut gedeckte Waren
        -- oben, am staerksten fehlende unten. needed ist hier immer > 0 (oben gefiltert).
        table.sort(matRows, function(a, b)
            return ((a.stock or 0) / (a.needed or 1)) > ((b.stock or 0) / (b.needed or 1))
        end)
        if #matRows > 0 then
            -- Projektname: zuerst EC's getStoreItemName(); liefert die aber "Unknown"
            -- (Store-Eintrag nicht aufloesbar), Fallback = Dateiname-Basename aus
            -- project.storeItemXml (verifiziert: FarmAssistant v2.28, ingame bestaetigt).
            local pname = nil
            local okN, nameRes = pcall(function() return project:getStoreItemName() end)
            if okN and type(nameRes) == "string" and nameRes ~= "" and nameRes ~= "Unknown" then
                pname = nameRes
            end
            if pname == nil then
                local okX, xmlPath = pcall(function() return project.storeItemXml end)
                if okX and type(xmlPath) == "string" and xmlPath ~= "" then
                    local norm = xmlPath:gsub("\\", "/")
                    local base = norm:match("([^/]+)%.xml$") or norm:match("([^/]+)$")
                    if base ~= nil and base ~= "" then
                        pname = base:sub(1, 1):upper() .. base:sub(2)
                    end
                end
            end
            if pname == nil then pname = "?" end
            table.insert(rows, {kind = "proj", name = pname})
            for _, r in ipairs(matRows) do table.insert(rows, r) end
        end
    end
    return rows
end

-- ─── Kassetten-Shops: Produktionsstellen mit CASH-Output ─────────────────────
-- Liefert eine flache Zeilenliste fuer die Kassetten-Ansicht (Icon-Toggle):
--   {kind="shop", name=<Shopname>, status="leer"|"voll"|"run"|"idle"}
--   {kind="ware", name=<Warenname>, ftName=<intern>, free=<freie Kapazitaet>}
-- Erkennung: eigene ProductionPoints, deren Produktions-Output CASH enthaelt
-- (verifiziert 10.08. per dlspProd: Eisdiele/Fischbude/Imbiss/Hofmarkt = OUT CASH).
-- Merkt zusaetzlich die leer-gelaufenen Shops in DispoList.kassettenLeer (Ticker).
function DispoList:buildKassettenRows(allStockLevels)
    local rows = {}
    DispoList.kassettenLeer = {}
    if g_currentMission == nil or g_currentMission.productionChainManager == nil then return rows end
    local cashIdx = g_fillTypeManager:getFillTypeIndexByName("CASH")
    if cashIdx == nil then return rows end
    local myFarmId = g_currentMission:getFarmId()

    -- Infrastruktur-Inputs (auto-versorgt, KEIN Liefergut per Anhaenger): nie listen.
    -- Manche Shops nehmen sie am Eingang technisch doch an (getIsFillTypeSupported=true),
    -- darum reicht der generische Filter nicht -> harter Namens-Ausschluss. Interne
    -- ft.name verifiziert per dlspProd an der Eisdiele (Log 20.08.2026).
    local KASSETTEN_SKIP = { MAINTENANCE = true, ELECTRICCHARGE = true }

    local PS = ProductionPoint ~= nil and ProductionPoint.PROD_STATUS or nil
    local S_MISS = PS ~= nil and PS.MISSING_INPUTS  or 2
    local S_FULL = PS ~= nil and PS.NO_OUTPUT_SPACE or 3
    local S_RUN  = PS ~= nil and PS.RUNNING         or 1

    local ok, pps = pcall(function()
        return g_currentMission.productionChainManager:getProductionPointsForFarmId(myFarmId)
    end)
    if not ok or pps == nil then
        print("[DispoList] buildKassettenRows(): " .. tostring(pps))
        return rows
    end

    for _, pp in pairs(pps) do
        -- Produziert dieser Punkt CASH? Nur dann ist er ein Kassetten-Shop.
        -- WICHTIG: pp.activeProductions (nur EINGESCHALTETE Rezepte) statt pp.productions
        -- (ALLE Rezepte). So tauchen Zutaten abgeschalteter Rezepte nicht als rotes
        -- "liefern" auf. Gleiche Quelle wie getProductionDemandPerHour (Konsistenz).
        -- Nebeneffekt: Shop mit ALLEN Cash-Rezepten aus -> faellt aus der Liste (idle).
        local isCash, inputIdx, worst = false, {}, nil
        for _, prod in pairs(pp.activeProductions or {}) do
            local producesCash = false
            for _, o in pairs(prod.outputs or {}) do
                if o.type == cashIdx then producesCash = true; isCash = true end
            end
            if producesCash then
                for _, i in pairs(prod.inputs or {}) do
                    if i.type ~= nil then inputIdx[i.type] = true end
                end
                -- schlimmsten Status merken: leer > voll > laeuft
                local st = prod.status
                if st == S_MISS then worst = S_MISS
                elseif st == S_FULL and worst ~= S_MISS then worst = S_FULL
                elseif st == S_RUN and worst == nil then worst = S_RUN end
            end
        end
        if isCash then
            local shopName = (pp.getName ~= nil) and tostring(pp:getName()) or "?"
            local status = "idle"
            if worst == S_MISS then status = "leer"
            elseif worst == S_FULL then status = "voll"
            elseif worst == S_RUN then status = "run" end
            if status == "leer" then table.insert(DispoList.kassettenLeer, shopName) end

            -- Annahmewaren mit Fuellstand einsammeln. free = zu liefern (bis voll),
            -- level = aktueller Bestand (Kapazitaet - free), frac = Fuellgrad 0..1.
            local wares = {}
            for idx in pairs(inputIdx) do
                local ft = g_fillTypeManager:getFillTypeByIndex(idx)
                -- Zwei Filter kombiniert: (1) generisch — nur Waren, die der Shop-Eingang
                -- ueberhaupt ANNIMMT (getIsFillTypeSupported); (2) harter Ausschluss der
                -- Infrastruktur-Inputs (MAINTENANCE/ELECTRICCHARGE), die manche Shops am
                -- Eingang zwar annehmen, die aber kein echtes Liefergut sind.
                local deliverable = false
                if ft ~= nil and pp.unloadingStation ~= nil then
                    local okS, sup = pcall(pp.unloadingStation.getIsFillTypeSupported, pp.unloadingStation, idx)
                    if okS then deliverable = (sup == true)
                    else print("## DL KASSETTE getIsFillTypeSupported ERROR: " .. tostring(sup)) end
                end
                if ft ~= nil and deliverable and not KASSETTEN_SKIP[ft.name] then
                    local free, cap = math.huge, nil
                    if pp.unloadingStation ~= nil then
                        local okF, f = pcall(pp.unloadingStation.getFreeCapacity, pp.unloadingStation, idx, myFarmId)
                        if okF and f ~= nil then free = f end
                        local okC, c = pcall(pp.unloadingStation.getCapacity, pp.unloadingStation, idx, myFarmId)
                        if okC and c ~= nil and c > 0 then cap = c end
                    end
                    local level = (cap ~= nil and free ~= math.huge) and math.max(0, cap - free) or nil
                    local frac  = (cap ~= nil and level ~= nil) and (level / cap) or 1
                    -- verfuegbar = was du davon im aktuellen Filter (ZL/Lager) hast
                    local avail = (allStockLevels ~= nil and allStockLevels[idx]) or 0
                    local ber = DispoList.getBereich(ft.name)
                    table.insert(wares, {name = ft.title or ft.name, ftName = ft.name,
                                         free = free, level = level, frac = frac, avail = avail,
                                         berOrder = (ber ~= nil and ber.order) or 99})
                end
            end
            -- nach Bereich gruppieren (Order), innerhalb leerste zuerst, dann A-Z
            table.sort(wares, function(a, b)
                if (a.berOrder or 99) ~= (b.berOrder or 99) then return (a.berOrder or 99) < (b.berOrder or 99) end
                if (a.frac or 1) ~= (b.frac or 1) then return (a.frac or 1) < (b.frac or 1) end
                return string.lower(a.name or "") < string.lower(b.name or "")
            end)

            table.insert(rows, {kind = "shop", name = shopName, status = status})
            for _, wr in ipairs(wares) do table.insert(rows, wr) end
        end
    end
    return rows
end

-- HL-Text-Ticker mit den leer-gelaufenen Kassetten-Shops synchronisieren.
-- Nur bei LEER (Eingang leer -> Shop steht still). Weiche Abhaengigkeit + pcall
-- (Prinzip 5): kein Ticker vorhanden -> still nichts tun. Laufende Meldungen
-- werden per Id gehalten und beim Aufloesen wieder entfernt (kein Neu-Spam).
function DispoList:syncKassettenTicker()
    DispoList.kassettenTickerIds = DispoList.kassettenTickerIds or {}
    local ids     = DispoList.kassettenTickerIds
    local mission = g_currentMission
    local ticker  = mission ~= nil and mission.hlHudSystem ~= nil and mission.hlHudSystem.textTicker or nil
    if ticker == nil then return end
    local nowLeer = {}
    for _, nm in ipairs(DispoList.kassettenLeer or {}) do nowLeer[nm] = true end
    -- nicht mehr leer -> Meldung entfernen
    for nm, id in pairs(ids) do
        if not nowLeer[nm] then
            pcall(function() ticker:removeMsgById(id) end)
            ids[nm] = nil
        end
    end
    -- neu leer -> Meldung hinzufuegen
    for nm in pairs(nowLeer) do
        if ids[nm] == nil then
            local txt = string.format(DL_t("kassetten_leer_ticker"), nm)
            local okA, id = pcall(function()
                return ticker:addMsg({ text = txt, color = DL_Colors.bauLimit, separator = false })
            end)
            if okA and id ~= nil then ids[nm] = id end
        end
    end
end

-- ─── Daten sammeln ───────────────────────────────────────────────────────────
-- ─── Lagertypen Scanner (einmalig beim Start) ────────────────────────────────
function DispoList:scanLagertypen()
    if g_currentMission == nil then return end
    local myFarmId = g_currentMission:getFarmId()
    local found = {}

    for _, placeable in ipairs(g_currentMission.placeableSystem.placeables) do
        local mine = placeable.ownerFarmId == myFarmId or placeable.ownerFarmId == 0

        -- Zentrallager
        if mine then
            for key, val in pairs(placeable) do
                if type(key) == "string" and type(val) == "table" then
                    if key:find("extendedProductionPoint") or key:find("ExtendedProductionPoint") then
                        found.ZENTRALLAGER = true
                        break
                    end
                end
            end
        end

        if mine then
            if placeable.spec_silo ~= nil then found.SILO = true end
            if placeable.spec_siloExtension ~= nil then found.SILO_EXTENSION = true end
            if placeable.spec_husbandry ~= nil then found.HUSBANDRY = true end
            if placeable.spec_manureHeap ~= nil then found.MANURE = true end
            if placeable.spec_beehivePalletSpawner ~= nil then found.BEEHIVE = true end
            if placeable.spec_bunkerSilo ~= nil then found.BUNKER = true end
            if placeable.spec_objectStorage ~= nil then found.OBJEKTLAGER = true end
        end
    end

    -- Ballen
    if g_currentMission.itemSystem ~= nil and g_currentMission.itemSystem.items ~= nil then
        for _, item in pairs(g_currentMission.itemSystem.items) do
            local bale = (type(item) == "table" and item.item) and item.item or item
            if bale ~= nil and bale.isa ~= nil and bale:isa(Bale) then
                found.BALE = true; break
            end
        end
    end

    -- Paletten
    if g_currentMission.vehicleSystem ~= nil then
        for _, v in ipairs(g_currentMission.vehicleSystem.vehicles) do
            if v.isPallet and (v.ownerFarmId == myFarmId or v.ownerFarmId == 0) then
                found.PALLET = true; break
            end
        end
    end

    -- Fabrik-Output
    if g_currentMission.productionChainManager ~= nil then
        for _, prod in ipairs(g_currentMission.productionChainManager.productionPoints) do
            if prod:getOwnerFarmId() == myFarmId then
                if prod.storage ~= nil and #(prod.outputFillTypeIdsArray or {}) > 0 then
                    found.PRODUCTION_OUT = true; break
                end
            end
        end
    end

    DispoList.foundLagertypen = found

    -- Aktivierte Typen auf vorhandene beschränken
    for typ, _ in pairs(DispoList.activeLagertypen) do
        if not found[typ] then
            DispoList.activeLagertypen[typ] = false
        end
    end

    local foundList = {}
    for k, _ in pairs(found) do table.insert(foundList, k) end
end

-- BEWUSSTES Sicherheitsnetz (kein Bug-Versteck): scanLagertypen iteriert ALLE
-- Placeables/Specs einer beliebigen Karte samt Fremdmods. Ein einziges exotisches
-- Placeable darf nicht die ganze Lagertyp-Erkennung killen. Fehler wird GELOGGT
-- (kein stilles Schlucken) und mit "alle Typen aktiv" sinnvoll aufgefangen.
local _origScan = DispoList.scanLagertypen
DispoList.scanLagertypen = function(self)
    local ok, err = pcall(_origScan, self)
    if not ok then
        print("## DispoList WARNING: scanLagertypen Fehler: " .. tostring(err))
        -- Fallback: alle Typen aktiv
        DispoList.foundLagertypen = {
            ZENTRALLAGER=true, SILO=true, SILO_EXTENSION=true,
            HUSBANDRY=true, MANURE=true, BEEHIVE=true,
            BUNKER=true, OBJEKTLAGER=true,
            BALE=true, PALLET=true, PRODUCTION_OUT=true
        }
    end
end

function DispoList:refreshDispoTable()
    -- BEWUSSTES Sicherheitsnetz um den Voll-Scan: _refreshDispoTableInner liest
    -- viele Fremd-/Karten-Daten (Storage-fillLevels, getName, Spec-Erkennung), die
    -- auf unbekannten Karten/Modsets abweichen koennen. Fehler wird GELOGGT und die
    -- Anzeige leer zurueckgesetzt, statt dass das HUD komplett bricht. _refreshRunning
    -- verhindert zusaetzlich Reentrancy. (Kein stilles Verschlucken eigener Bugs.)
    if DispoList._refreshRunning then return end
    DispoList._refreshRunning = true
    local ok, err = pcall(function() DispoList:_refreshDispoTableInner() end)
    DispoList._refreshRunning = false
    if not ok then
        print("## DispoList ERROR refreshDispoTable: " .. tostring(err))
        DispoList.CurrentItems = {}
        DispoList.DisplayItems = {}
    end
end
function DispoList:_refreshDispoTableInner()
    DispoList.refreshSinceMs = 0
    if g_currentMission == nil then return end
    local myFarmId        = g_currentMission:getFarmId()
    local priceMultiplier = EconomyManager.getPriceMultiplier()
    local stockLevels     = {}
    local allStockLevels  = {}  -- Gesamtbestand UNABHAENGIG von Lagertyp-Einstellungen (fuer Export/g_farmCore)
    local zlStockLevels    = {}  -- Nur der ZL-Anteil pro FillType (fuer Stern/CW-Filter)

    local act = DispoList.activeLagertypen or {}
    local activeZlGeb = DispoList.activeZlGebaeude or {}
    local zlStorages = {}  -- ZL-Storages nicht doppelt zählen
    local countedProdStorages = {}  -- Fabrik-Output nicht doppelt zählen
    local foundZentrallager = 0
    DispoList.foundZlGebaeude = {}  -- welche ZL-Gebaeude gibt's ueberhaupt (fuer Settings-Liste)

    -- ── Zentrallager ─────────────────────────────────────────────────────────
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
                if pp.storage ~= nil and pp.storage.fillLevels ~= nil and not zlStorages[pp.storage] then
                    zlStorages[pp.storage] = true
                    foundZentrallager = foundZentrallager + 1
                    local gebName = placeable:getName() or "?"
                    DispoList.foundZlGebaeude[gebName] = true
                    local gebActive = (activeZlGeb[gebName] ~= false)  -- Default AN, neue Gebaeude nicht ueberraschend ausblenden
                    for idx, lvl in pairs(pp.storage.fillLevels) do
                        if lvl > 0 then
                            allStockLevels[idx] = (allStockLevels[idx] or 0) + lvl
                            if act.ZENTRALLAGER then
                                stockLevels[idx]   = (stockLevels[idx] or 0) + lvl
                                if gebActive then
                                    zlStockLevels[idx] = (zlStockLevels[idx] or 0) + lvl
                                end
                            end
                        end
                    end
                    -- Fabrik-Output des ZL wird hier erfasst (verhindert Doppelzählung)
                    if pp.outputFillTypeIdsArray ~= nil then
                        countedProdStorages[pp.storage] = true
                    end
                end
            end
        end
    end

    -- ── Fabrik-Output (normale Fabriken, nicht ZL) ────────────────────────────
    if g_currentMission.productionChainManager ~= nil then
        for _, prod in ipairs(g_currentMission.productionChainManager.productionPoints) do
            if prod:getOwnerFarmId() == myFarmId then
                local st = prod.storage
                if st ~= nil and not zlStorages[st] and not countedProdStorages[st] then
                    countedProdStorages[st] = true
                    if prod.outputFillTypeIdsArray ~= nil then
                        for _, ftIdx in ipairs(prod.outputFillTypeIdsArray) do
                            local ok, lvl = pcall(function() return prod.storage:getFillLevel(ftIdx) end)
                            if not ok then print("## DL PRODOUT ERROR (getFillLevel): " .. tostring(lvl)) end
                            if ok and lvl ~= nil and lvl > 0 then
                                allStockLevels[ftIdx] = (allStockLevels[ftIdx] or 0) + math.floor(lvl)
                                if act.PRODUCTION_OUT then
                                    stockLevels[ftIdx] = (stockLevels[ftIdx] or 0) + math.floor(lvl)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    DispoList.foundZentrallager = foundZentrallager
    local ftCount = 0; for _ in pairs(stockLevels) do ftCount = ftCount + 1 end

    -- ZL-Delta: neues Zentrallager gebaut? → autoAssignFromZentrallager triggern
    if DL_Filter ~= nil and DispoList._lastFoundZentrallager ~= foundZentrallager then
        if DispoList._lastFoundZentrallager ~= nil then
            -- Echte Änderung mid-game
            DL_Filter:autoAssignFromZentrallager()
        end
        DispoList._lastFoundZentrallager = foundZentrallager
    end

    -- ── Rohwaren: Silos, Tierhaltung, Ballen, Paletten ───────────────────────
    -- Alle Bestände addieren (ZL-Storages werden übersprungen via zlStorages-Set)
    local function addRohware(idx, lvl, active)
        if idx ~= nil and lvl ~= nil and lvl > 0 then
            allStockLevels[idx] = (allStockLevels[idx] or 0) + lvl
            if active then
                stockLevels[idx] = (stockLevels[idx] or 0) + lvl
            end
        end
    end

    local countedRwStorages = {}

    for _, placeable in ipairs(g_currentMission.placeableSystem.placeables) do
        local mine = placeable.ownerFarmId == myFarmId or placeable.ownerFarmId == 0

        -- Silos (spec_silo)
        if placeable.spec_silo ~= nil and mine then
            for _, st in ipairs(placeable.spec_silo.storages or {}) do
                if not zlStorages[st] and not countedRwStorages[st] then
                    countedRwStorages[st] = true
                    if st.fillLevels ~= nil then
                        for idx, lvl in pairs(st.fillLevels) do addRohware(idx, lvl, act.SILO) end
                    end
                end
            end
        end

        -- SiloExtension
        if placeable.spec_siloExtension ~= nil and mine then
            local st = placeable.spec_siloExtension.storage
            if st ~= nil and not zlStorages[st] and not countedRwStorages[st] then
                countedRwStorages[st] = true
                if st.fillLevels ~= nil then
                    for idx, lvl in pairs(st.fillLevels) do addRohware(idx, lvl, act.SILO_EXTENSION) end
                end
            end
        end

        -- Tierhaltung
        if placeable.spec_husbandry ~= nil and placeable.ownerFarmId == myFarmId then
            local st = placeable.spec_husbandry.storage
            if st ~= nil and not zlStorages[st] and not countedRwStorages[st] then
                countedRwStorages[st] = true
                local ls = placeable.spec_husbandry.loadingStation
                if st.fillLevels ~= nil then
                    for idx, lvl in pairs(st.fillLevels) do
                        if ls == nil or ls.supportedFillTypes == nil or ls.supportedFillTypes[idx] then
                            addRohware(idx, lvl, act.HUSBANDRY)
                        end
                    end
                end
            end
        end

        -- Misthaufen
        if placeable.spec_manureHeap ~= nil and mine then
            local heap = placeable.spec_manureHeap.manureHeap
            if heap ~= nil and not countedRwStorages[heap] then
                countedRwStorages[heap] = true
                if heap.fillLevels ~= nil then
                    for idx, lvl in pairs(heap.fillLevels) do addRohware(idx, lvl, act.MANURE) end
                end
            end
        end

        -- Fahrsilo (BunkerSilo)
        if placeable.spec_bunkerSilo ~= nil and mine then
            local ok, err = pcall(function()
                local bs = placeable.spec_bunkerSilo.bunkerSilo
                if bs ~= nil then
                    local fillLevel = bs.fillLevel or 0
                    local ftIdx = bs.inputFillType
                    if bs.state == BunkerSilo.STATE_DRAIN or bs.state == BunkerSilo.STATE_FERMENTED then
                        ftIdx = bs.outputFillType
                    end
                    if fillLevel > 0 and ftIdx ~= nil and type(ftIdx) == "number" then
                        addRohware(ftIdx, fillLevel, act.BUNKER)
                    end
                end
            end)
            if not ok then print("## DL BUNKER ERROR: " .. tostring(err)) end
        end

        -- Objektlager (Ballen/Paletten in Lagerhallen — spec_objectStorage)
        if placeable.spec_objectStorage ~= nil and mine then
            local ok, err = pcall(function()
                local objInfos = placeable.spec_objectStorage.objectInfos
                if objInfos ~= nil then
                    for _, objectInfo in ipairs(objInfos) do
                        if objectInfo.objects ~= nil then
                            if #objectInfo.objects == 1 and (objectInfo.numObjects or 1) > 1 then
                                local obj = objectInfo.objects[1]
                                local ftIdx, lvl = nil, 0
                                if obj.baleAttributes ~= nil then
                                    ftIdx = obj.baleAttributes.fillType
                                    lvl   = obj.baleAttributes.fillLevel * objectInfo.numObjects
                                elseif obj.baleObject ~= nil then
                                    ftIdx = obj.baleObject.fillType
                                    lvl   = obj.baleObject.fillLevel * objectInfo.numObjects
                                elseif obj.palletAttributes ~= nil then
                                    ftIdx = obj.palletAttributes.fillType
                                    lvl   = obj.palletAttributes.fillLevel * objectInfo.numObjects
                                end
                                if ftIdx ~= nil and type(ftIdx) == "number" and lvl > 0 then
                                    addRohware(ftIdx, lvl, act.OBJEKTLAGER)
                                end
                            else
                                for _, obj in ipairs(objectInfo.objects) do
                                    local ftIdx, lvl = nil, 0
                                    if obj.baleAttributes ~= nil and
                                       (obj.baleAttributes.farmId == myFarmId or obj.baleAttributes.farmId == 0) then
                                        ftIdx = obj.baleAttributes.fillType
                                        lvl   = obj.baleAttributes.fillLevel
                                    elseif obj.baleObject ~= nil and
                                           (obj.baleObject.ownerFarmId == myFarmId or obj.baleObject.ownerFarmId == 0) then
                                        ftIdx = obj.baleObject.fillType
                                        lvl   = obj.baleObject.fillLevel
                                    elseif obj.palletAttributes ~= nil and
                                           (obj.palletAttributes.ownerFarmId == myFarmId or obj.palletAttributes.ownerFarmId == 0) then
                                        ftIdx = obj.palletAttributes.fillType
                                        lvl   = obj.palletAttributes.fillLevel
                                    end
                                    if ftIdx ~= nil and type(ftIdx) == "number" and lvl > 0 then
                                        addRohware(ftIdx, lvl, act.OBJEKTLAGER)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            if not ok then print("## DL OBJEKTLAGER ERROR: " .. tostring(err)) end
        end

        -- Bienenstock
        if placeable.spec_beehivePalletSpawner ~= nil and placeable.ownerFarmId == myFarmId then
            addRohware(placeable.spec_beehivePalletSpawner.fillType,
                       placeable.spec_beehivePalletSpawner.pendingLiters, act.BEEHIVE)
        end
    end

    -- Fahrzeuge: Paletten
    if g_currentMission.vehicleSystem ~= nil then
        for _, v in ipairs(g_currentMission.vehicleSystem.vehicles) do
            if v.isPallet and (v.ownerFarmId == myFarmId or v.ownerFarmId == 0) then
                if v.spec_fillUnit ~= nil and v.spec_fillUnit.fillUnits ~= nil then
                    for _, fu in ipairs(v.spec_fillUnit.fillUnits) do
                        addRohware(fu.fillType, fu.fillLevel, act.PALLET)
                    end
                end
            end
        end
    end

    -- Ballen auf der Karte
    if g_currentMission.itemSystem ~= nil and g_currentMission.itemSystem.items ~= nil then
        for _, item in pairs(g_currentMission.itemSystem.items) do
            local bale = (type(item) == "table" and item.item) and item.item or item
            if bale ~= nil and bale.isa ~= nil and bale:isa(Bale) then
                if bale.ownerFarmId == myFarmId or bale.ownerFarmId == 0 then
                    addRohware(bale.fillType, bale.fillLevel, act.BALE)
                end
            end
        end
    end

    local rwCount = 0
    for _ in pairs(stockLevels) do rwCount = rwCount + 1 end

    -- Meistbietende Station pro FillType
    local bestStation    = {}
    -- Höchster stationsspezifischer priceScale-Bonus pro FillType (siehe TSStockCheck-Vorbild:
    -- Stationen können in ihrer placeable-XML einen <fillType name="..." priceScale="X"/> Bonus
    -- haben, der on top der normalen Saisonkurve kommt. Ohne den Bonus kann der "theoretische
    -- Max-Preis" niedriger sein als der tatsächlich gezahlte aktuelle Preis -> Bug.
    local bestPriceScale = {}
    for _, station in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
        if station:isa(SellingStation) and not station.hideFromPricesMenu then
            local isOwnStation = station.ownerFarmId == myFarmId and station.ownerFarmId ~= 0
            if not isOwnStation then
                for ft, ok in pairs(station.acceptedFillTypes) do
                    if ok == true and allStockLevels[ft] ~= nil then
                        -- Freie Kapazitaet der Station fuer diese Ware. huge = echter Markt
                        -- (unbegrenzt). Baustelle/Lager-Station mit vollem Lager -> 0 -> raus
                        -- (Filter A). Der Wert wird zusaetzlich als Mengen-Deckel gespeichert
                        -- (Filter A+): an so einer Station kann man nur bis freeCap abladen.
                        -- Fehler/nil -> huge annehmen (nicht filtern/deckeln, Prinzip 5).
                        local freeCap = math.huge
                        local okC, fc = pcall(station.getFreeCapacity, station, ft, myFarmId)
                        if okC then
                            if fc ~= nil then freeCap = fc end
                        else
                            print("[DispoList] getFreeCapacity-Fehler bei '" .. tostring(station:getName())
                                .. "': " .. tostring(fc))
                        end
                        if freeCap > 0 then
                            -- getEffectiveFillTypePrice() liefert bereits den fertigen, tatsächlich gezahlten
                            -- Preis inkl. Schwierigkeitsgrad-Faktor -> NICHT nochmal mit priceMultiplier multiplizieren
                            -- (siehe TSStockCheck als Referenz, Zeile 238: kein priceMultiplier hier)
                            local price = station:getEffectiveFillTypePrice(ft)
                            if bestStation[ft] == nil or price > bestStation[ft].price then
                                bestStation[ft] = {
                                    stationName = station:getName(),
                                    price       = price,
                                    priceTrend  = station:getCurrentPricingTrend(ft),
                                    freeCap     = freeCap,
                                }
                            end
                        end
                    end
                end

                -- Stations-eigenen priceScale je FillType aus der placeable-XML auslesen
                if station.owningPlaceable ~= nil and station.owningPlaceable.xmlFile ~= nil then
                    local xmlFile = station.owningPlaceable.xmlFile
                    xmlFile:iterate("placeable.sellingStation.fillType", function(_, fillTypeKey)
                        local ftName = xmlFile:getValue(fillTypeKey .. "#name")
                        local ftIdx  = ftName ~= nil and g_fillTypeManager:getFillTypeIndexByName(ftName) or nil
                        if ftIdx ~= nil and allStockLevels[ftIdx] ~= nil then
                            local priceScale = xmlFile:getValue(fillTypeKey .. "#priceScale", 1)
                            if bestPriceScale[ftIdx] == nil or priceScale > bestPriceScale[ftIdx] then
                                bestPriceScale[ftIdx] = priceScale
                            end
                        end
                    end)
                end
            end
        end
    end

    -- Produktionsbedarf
    local demandPerHour = DispoList:getProductionDemandPerHour()

    -- Baustellen-Bedarf (EverythingConstructable, falls installiert & aktiviert)
    local constructionDemand = DispoList:getConstructionDemand()
    -- Fuer g_farmCore-Export cachen (analog CurrentItems) -- FarmAssistant soll
    -- den rohen Bedarf lesen koennen, ohne ecProjectManager selbst anzufassen.
    DispoList.lastConstructionDemand = constructionDemand
    -- Baustellen-Ansicht (Kran-Toggle) aus denselben Rohdaten bauen und cachen,
    -- damit der Draw pro Frame nur liest statt zu scannen. Stock = allStockLevels.
    DispoList.baustelleRows = DispoList:buildBaustelleRows(allStockLevels)
    -- Kassetten-Shops (Produktionsstellen mit CASH-Output) + Leerlauf-Ticker.
    -- "frei" respektiert denselben Bestand wie der Rest des HUDs (bei Stern nur ZL,
    -- sonst Lagertyp-gefiltert) UND zieht den 24h-Fabrikpuffer + Baustellenbedarf ab
    -- -- ABER OHNE die Kassetten-Shops selbst (skipCashOutput): deren eigener
    -- Verbrauch darf "frei" nicht schmaelern, sonst frisst sich ein Hofladen selbst
    -- weg. Ergebnis = frei lieferbar, ohne die anderen Fabriken zu bremsen.
    local kassettenBase   = DispoList._zlFilterActive and zlStockLevels or stockLevels
    local demandExclCash  = DispoList:getProductionDemandPerHour(true)
    local kassettenFrei   = {}
    for idx, lvl in pairs(kassettenBase) do
        local res = (demandExclCash[idx] or 0) * (DispoList.reserveStunden or 24) + (constructionDemand[idx] or 0)
        kassettenFrei[idx] = math.max(0, lvl - res)
    end
    DispoList.kassettenRows = DispoList:buildKassettenRows(kassettenFrei)
    DispoList:syncKassettenTicker()

    -- Finale Liste
    -- WICHTIG: Basis ist allStockLevels (Gesamtbestand, unabhaengig von Lagertyp-
    -- Einstellungen) -- so sieht der Export (CurrentItems) immer den kompletten
    -- Betrieb. activeStock traegt zusaetzlich den Anteil, der laut Einstellungen
    -- zaehlt -- nur DEN nutzt die HUD-Anzeige (DisplayItems) weiter unten.
    local entries = {}
    for idx, lvl in pairs(allStockLevels) do
        if lvl > 0 and bestStation[idx] ~= nil then
            local ft = g_fillTypeManager:getFillTypeByIndex(idx)
            if ft ~= nil then
                local demandLph     = demandPerHour[idx] or 0
                local reserveAmount = demandLph * (DispoList.reserveStunden or 24)
                local ecReserve     = constructionDemand[idx] or 0
                local sellable      = lvl - reserveAmount - ecReserve
                -- Debug: Fertigwand
                if ft.name ~= nil and string.upper(ft.name) == "PREFABWALL" then
                end
                -- Unverkaeuflich: nicht in Hauptliste aufnehmen
                local ber = DispoList.getBereich(ft.name)
                if ber ~= nil and ber.name == "Unverkaeuflich" then
                    -- skip
                else
                table.insert(entries, {
                    fillTypeIndex = idx,
                    ftName        = ft.name,
                    title         = ft.title,
                    icon          = ft.hudOverlayFilename,
                    stockLevel    = lvl,
                    sellable      = sellable,
                    activeStock   = stockLevels[idx] or 0,  -- Anteil laut Lagertyp-Einstellungen (fuer HUD)
                    zlStock       = zlStockLevels[idx] or 0,
                    demandPerHour = demandLph,
                    ecReserve     = ecReserve,
                    stationName   = bestStation[idx].stationName,
                    price         = bestStation[idx].price,
                    priceTrend    = bestStation[idx].priceTrend,
                    freeCap       = bestStation[idx].freeCap or math.huge,  -- Mengen-Deckel (Filter A+)
                    bereich       = ber,
                    maxPrice      = (function()
                        local maxP = 0
                        local scale = bestPriceScale[idx] or 1
                        if ft.economy ~= nil and ft.economy.factors ~= nil then
                            for period = 1, 12 do
                                local p = (ft.pricePerLiter or 0) * (ft.economy.factors[period] or 1.0) * priceMultiplier * scale
                                if p > maxP then maxP = p end
                            end
                        else
                            maxP = bestStation[idx].price
                        end
                        -- Sicherheitsnetz: Max darf nie unter dem tatsächlich gezahlten Preis liegen
                        if maxP < bestStation[idx].price then maxP = bestStation[idx].price end
                        return maxP
                    end)(),
                    bestMonth     = (function()
                        local maxP = 0
                        local bestM = 1
                        if ft.economy ~= nil and ft.economy.factors ~= nil then
                            for period = 1, 12 do
                                local p = (ft.pricePerLiter or 0) * (ft.economy.factors[period] or 1.0)
                                if p > maxP then
                                    maxP = p
                                    bestM = period
                                end
                            end
                        end
                        return bestM
                    end)(),
                })
                end  -- end else (Unverkaeuflich Filter)
            end
        end
    end

    -- Filter anwenden: gefilterte Station+FillType Kombinationen entfernen
    if DL_Filter ~= nil then
        local filtered = {}
        for _, e in ipairs(entries) do
            if e.isStationHeader or e.isBereichHeader then
                table.insert(filtered, e)
            else
                local ftName = nil
                local ft = g_fillTypeManager:getFillTypeByIndex(e.fillTypeIndex)
                if ft ~= nil then ftName = ft.name end
                if ftName == nil or not DL_Filter:isFiltered(e.stationName, ftName) then
                    table.insert(filtered, e)
                end
            end
        end
        entries = filtered
    end

    -- ── Suchfilter (inkrementell) ─────────────────────────────────────────────
    if DispoList.searchText ~= nil and DispoList.searchText ~= "" then
        local q = string.lower(DispoList.searchText)
        local filtered = {}
        local matchedStations = {}
        -- Erst prüfen welche Stationen komplett passen (Stationsname enthält Suche)
        for _, e in ipairs(entries) do
            if string.lower(e.stationName or "") :find(q, 1, true) then
                matchedStations[e.stationName] = true
            end
        end
        -- Einträge filtern: Warenname oder Station matched
        for _, e in ipairs(entries) do
            local wareMatch    = string.lower(e.title or ""):find(q, 1, true)
            local stationMatch = matchedStations[e.stationName]
            if wareMatch or stationMatch then
                table.insert(filtered, e)
            end
        end
        entries = filtered
    end

    -- ── Gesamt-Datensatz für Export (g_farmCore) ──────────────────────────────
    -- entries basiert auf allStockLevels (Gesamtbestand, siehe oben) -- FarmAssistant
    -- & Co. sehen also immer den KOMPLETTEN Betrieb, unabhaengig von Lagertyp-
    -- Einstellungen und vom Stern/CW-Filter im HUD.
    DispoList.CurrentItems = entries

    -- ── Lagertyp-Einstellungen: NUR fuer die HUD-Anzeige einschraenken ─────────
    -- Baut eine eigene Kopie-Liste, die nur den Anteil zeigt, der laut den
    -- Lagertyp-Haekchen (Einstellungen-Menue) aktiv ist (activeStock). Waren,
    -- die NUR ueber einen ausgeschalteten Lagertyp existieren, werden hier
    -- komplett ausgeblendet -- CurrentItems oben bleibt davon unberuehrt.
    local settingsEntries = {}
    for _, e in ipairs(entries) do
        local activeAmt = e.activeStock or 0
        if activeAmt > 0 then
            local reserveAmount = (e.demandPerHour or 0) * (DispoList.reserveStunden or 24)
            local copy = {}
            for k, v in pairs(e) do copy[k] = v end
            copy.stockLevel = activeAmt
            copy.sellable   = activeAmt - reserveAmount - (e.ecReserve or 0)
            table.insert(settingsEntries, copy)
        end
    end

    -- ZL-Filter ("Stern/CW only"): NUR fuer die HUD-Anzeige, baut aus den schon
    -- Lagertyp-eingeschraenkten settingsEntries eine weitere Kopie-Liste. Zeigt nur
    -- Waren mit echtem ZL-Bestand (zlStock), und zwar mit dem ZL-Anteil als
    -- Anzeigewert -- nicht mit der Gesamtmenge aus allen Lagertypen.
    local displayEntries = settingsEntries
    if DispoList._zlFilterActive then
        local zlFiltered = {}
        for _, e in ipairs(settingsEntries) do
            local zlStock = e.zlStock or 0
            if zlStock > 0 then
                local reserveAmount = (e.demandPerHour or 0) * (DispoList.reserveStunden or 24)
                local copy = {}
                for k, v in pairs(e) do copy[k] = v end
                copy.stockLevel = zlStock
                copy.sellable   = zlStock - reserveAmount - (e.ecReserve or 0)
                table.insert(zlFiltered, copy)
            end
        end
        displayEntries = zlFiltered
        DispoList._zlFilterEmpty = (#zlFiltered == 0)
    else
        DispoList._zlFilterEmpty = false
    end

    -- Stationswert berechnen (sellable * price pro Station) -- auf Basis dessen,
    -- was gerade im HUD sichtbar ist (displayEntries), nicht des Gesamtbestands.
    DispoList.stationValues = {}
    -- Baustellen/Lager-Stationen (endliche Kapazitaet, kein echter Markt) merken,
    -- damit der Draw ihren Kopf orange faerbt (Filter A+).
    DispoList.stationLimited = {}
    for _, e in ipairs(displayEntries) do
        local st = e.stationName or ""
        -- Mengen-Deckel: an einer Baustelle/Lager-Station nur bis freeCap abladbar.
        local sell = math.max(0, e.sellable or 0)
        local fc   = e.freeCap or math.huge
        if fc < sell then sell = fc end
        DispoList.stationValues[st] = (DispoList.stationValues[st] or 0) + sell * (e.price or 0)
        if fc ~= math.huge then DispoList.stationLimited[st] = true end
    end
    local stationValues = DispoList.stationValues

    -- Sortierung: A-Z oder Wert absteigend
    if DispoList.sortByValue then
        table.sort(displayEntries, function(a, b)
            local va = stationValues[a.stationName or ""] or 0
            local vb = stationValues[b.stationName or ""] or 0
            if va ~= vb then return va > vb end  -- höchster Wert zuerst
            local oa = a.bereich and a.bereich.order or 99
            local ob = b.bereich and b.bereich.order or 99
            if oa ~= ob then return oa < ob end
            return string.lower(a.title or "") < string.lower(b.title or "")
        end)
    else
        table.sort(displayEntries, function(a, b)
            local sa = string.lower(a.stationName or "")
            local sb = string.lower(b.stationName or "")
            if sa ~= sb then return sa < sb end
            local oa = a.bereich and a.bereich.order or 99
            local ob = b.bereich and b.bereich.order or 99
            if oa ~= ob then return oa < ob end
            return string.lower(a.title or "") < string.lower(b.title or "")
        end)
    end

    -- Header werden im Draw-Code eingefügt (nach stockLevel-Filter)

    -- HUD-Anzeigeliste: das sieht der Draw-Code (DL_Display_DrawBox.lua), NICHT
    -- CurrentItems -- damit bleibt der Export garantiert vom Stern/CW-Filter unberuehrt.
    DispoList.DisplayItems = displayEntries

    -- lagerCache aktualisieren falls Drill-Down aktiv
    if DispoList.lagerViewFt ~= nil then
        DispoList.lagerCache[DispoList.lagerViewFt] = DispoList.getLagerFuerFillType(DispoList.lagerViewFt)
    end

    -- Box zur Neuzeichnung zwingen
    if g_currentMission.hlHudSystem ~= nil and g_currentMission.hlHudSystem.hlBox ~= nil then
        local box = g_currentMission.hlHudSystem.hlBox:getData("DL_Display_Box")
        if box ~= nil then box.needsUpdate = true end
    end
end

-- ─── Lager-Drill-Down: alle Lager mit Level+Kapazität für einen FillType ─────
function DispoList.getLagerFuerFillType(ftName)
    if ftName == nil or g_currentMission == nil then return {} end
    local ft = g_fillTypeManager:getFillTypeByName(ftName)
    if ft == nil then return {} end
    local ftIdx = ft.index
    local myFarmId = g_currentMission:getFarmId()
    local act = DispoList.activeLagertypen or {}
    local result = {}
    local countedStorages = {}

    local function addStorage(st, name)
        if st == nil or countedStorages[st] then return end
        countedStorages[st] = true
        local lvl = 0
        local cap = 0
        local ok1, v1 = pcall(function() return st:getFillLevel(ftIdx) end)
        if not ok1 then print("## DL LAGER ERROR (getFillLevel): " .. tostring(v1)) end
        if ok1 and v1 ~= nil then lvl = math.floor(v1) end
        local ok2, v2 = pcall(function() return st:getCapacity(ftIdx) end)
        if not ok2 then print("## DL LAGER ERROR (getCapacity): " .. tostring(v2)) end
        if ok2 and v2 ~= nil then cap = math.floor(v2) end
        if lvl > 0 then
            result[#result+1] = {name=name, level=lvl, capacity=cap}
        end
    end

    for _, placeable in ipairs(g_currentMission.placeableSystem.placeables) do
        local mine = placeable.ownerFarmId == myFarmId or placeable.ownerFarmId == 0
        if mine then
            local pName = placeable:getName() or "?"

            -- Zentrallager
            if act.ZENTRALLAGER then
                for key, val in pairs(placeable) do
                    if type(key) == "string" and type(val) == "table" then
                        if key:find("extendedProductionPoint") or key:find("ExtendedProductionPoint") then
                            if val.productionPoint ~= nil and val.productionPoint.storage ~= nil then
                                addStorage(val.productionPoint.storage, pName)
                            end
                            break
                        end
                    end
                end
            end

            -- Silos
            if act.SILO and placeable.spec_silo ~= nil then
                for _, st in ipairs(placeable.spec_silo.storages or {}) do
                    addStorage(st, pName)
                end
            end

            -- SiloExtension
            if act.SILO_EXTENSION and placeable.spec_siloExtension ~= nil then
                addStorage(placeable.spec_siloExtension.storage, pName)
            end

            -- Tierhaltung
            if act.HUSBANDRY and placeable.spec_husbandry ~= nil and placeable.ownerFarmId == myFarmId then
                local st  = placeable.spec_husbandry.storage
                local ls  = placeable.spec_husbandry.loadingStation
                if st ~= nil and st.fillLevels ~= nil and countedStorages[st] == nil then
                    countedStorages[st] = true
                    local lvl = st.fillLevels[ftIdx] or 0
                    -- loadingStation-Filter: nur ausladbare FillTypes
                    local supported = ls == nil or ls.supportedFillTypes == nil
                                   or ls.supportedFillTypes[ftIdx] == true
                    if lvl > 0 and supported then
                        local cap = 0
                        local ok2, v2 = pcall(function() return st:getCapacity(ftIdx) end)
                        if not ok2 then print("## DL LAGER ERROR (Tierhaltung getCapacity): " .. tostring(v2)) end
                        if ok2 and v2 ~= nil then cap = math.floor(v2) end
                        result[#result+1] = {name=pName, level=math.floor(lvl), capacity=cap}
                    end
                end
            end

            -- Misthaufen
            if act.MANURE and placeable.spec_manureHeap ~= nil then
                local heap = placeable.spec_manureHeap.manureHeap
                if heap ~= nil then addStorage(heap, pName) end
            end

            -- Fahrsilo (BunkerSilo)
            if act.BUNKER and placeable.spec_bunkerSilo ~= nil then
                local bs = placeable.spec_bunkerSilo.bunkerSilo
                if bs ~= nil then
                    local fillLevel = bs.fillLevel or 0
                    local bsFtIdx = bs.inputFillType
                    if bs.state == BunkerSilo.STATE_DRAIN or bs.state == BunkerSilo.STATE_FERMENTED then
                        bsFtIdx = bs.outputFillType
                    end
                    if fillLevel > 0 and bsFtIdx == ftIdx then
                        result[#result+1] = {name=pName, level=math.floor(fillLevel), capacity=0}
                    end
                end
            end

            -- Objektlager (spec_objectStorage)
            if act.OBJEKTLAGER and placeable.spec_objectStorage ~= nil then
                local objInfos = placeable.spec_objectStorage.objectInfos
                if objInfos ~= nil then
                    local totalLvl = 0
                    for _, objectInfo in ipairs(objInfos) do
                        if objectInfo.objects ~= nil then
                            if #objectInfo.objects == 1 and (objectInfo.numObjects or 1) > 1 then
                                local obj = objectInfo.objects[1]
                                local oFt, oLvl = nil, 0
                                if obj.baleAttributes ~= nil then oFt=obj.baleAttributes.fillType; oLvl=obj.baleAttributes.fillLevel*(objectInfo.numObjects) end
                                if obj.baleObject ~= nil then oFt=obj.baleObject.fillType; oLvl=obj.baleObject.fillLevel*(objectInfo.numObjects) end
                                if obj.palletAttributes ~= nil then oFt=obj.palletAttributes.fillType; oLvl=obj.palletAttributes.fillLevel*(objectInfo.numObjects) end
                                if oFt == ftIdx then totalLvl = totalLvl + oLvl end
                            else
                                for _, obj in ipairs(objectInfo.objects) do
                                    local oFt, oLvl = nil, 0
                                    if obj.baleAttributes ~= nil then oFt=obj.baleAttributes.fillType; oLvl=obj.baleAttributes.fillLevel end
                                    if obj.baleObject ~= nil then oFt=obj.baleObject.fillType; oLvl=obj.baleObject.fillLevel end
                                    if obj.palletAttributes ~= nil then oFt=obj.palletAttributes.fillType; oLvl=obj.palletAttributes.fillLevel end
                                    if oFt == ftIdx then totalLvl = totalLvl + oLvl end
                                end
                            end
                        end
                    end
                    if totalLvl > 0 then
                        result[#result+1] = {name=pName, level=math.floor(totalLvl), capacity=0}
                    end
                end
            end

            -- Fabrik-Output: nur wenn ftIdx ein Output dieses Produktionspunkts ist
            if act.PRODUCTION_OUT and g_currentMission.productionChainManager ~= nil then
                if placeable.spec_productionPoint ~= nil then
                    local pp = placeable.spec_productionPoint.productionPoint
                    if pp ~= nil and pp.storage ~= nil and pp.outputFillTypeIdsArray ~= nil then
                        local isOutput = false
                        for _, outIdx in ipairs(pp.outputFillTypeIdsArray) do
                            if outIdx == ftIdx then isOutput = true; break end
                        end
                        if isOutput then addStorage(pp.storage, pName) end
                    end
                end
            end
        end
    end

    -- Fahrzeuge: Paletten (eine Summenzeile, nicht jede Palette einzeln)
    if act.PALLET and g_currentMission.vehicleSystem ~= nil then
        local palletTotal = 0
        for _, v in ipairs(g_currentMission.vehicleSystem.vehicles) do
            if v.isPallet and (v.ownerFarmId == myFarmId or v.ownerFarmId == 0) then
                if v.spec_fillUnit ~= nil and v.spec_fillUnit.fillUnits ~= nil then
                    for _, fu in ipairs(v.spec_fillUnit.fillUnits) do
                        if fu.fillType == ftIdx then
                            palletTotal = palletTotal + (fu.fillLevel or 0)
                        end
                    end
                end
            end
        end
        if palletTotal > 0 then
            result[#result+1] = {name = DL_t("lt_pallet"), level = math.floor(palletTotal), capacity = 0}
        end
    end

    -- Ballen auf der Karte (eine Summenzeile, nicht jeder Ballen einzeln)
    if act.BALE and g_currentMission.itemSystem ~= nil and g_currentMission.itemSystem.items ~= nil then
        local baleTotal = 0
        for _, item in pairs(g_currentMission.itemSystem.items) do
            local bale = (type(item) == "table" and item.item) and item.item or item
            if bale ~= nil and bale.isa ~= nil and bale:isa(Bale) then
                if bale.ownerFarmId == myFarmId or bale.ownerFarmId == 0 then
                    if bale.fillType == ftIdx then
                        baleTotal = baleTotal + (bale.fillLevel or 0)
                    end
                end
            end
        end
        if baleTotal > 0 then
            result[#result+1] = {name = DL_t("lt_bale"), level = math.floor(baleTotal), capacity = 0}
        end
    end

    -- Sortierung: Level absteigend
    table.sort(result, function(a, b) return a.level > b.level end)
    return result
end
function DispoList:RegisterDisplaySystem()
    if DispoList:getDetiServer() then return end
    g_currentMission.hlUtils.modLoad("FS25_DispoList")
    if g_currentMission.hlHudSystem ~= nil and
       g_currentMission.hlHudSystem.hlHud ~= nil and
       g_currentMission.hlHudSystem.hlHud.generate ~= nil then
        DL_Display_XmlBox:loadBox("DL_Display_Box", true)
        DL_Display_XmlBox:loadBox("DL_Filter_Box", true)
        DL_TitelHud_XmlHud:loadHud("DL_TitelHud")
        DispoList:refreshDispoTable()
    else
        print("#WARNING: DispoList MISSING --> HL Hud System!")
        g_currentMission.hlUtils.modUnLoad("FS25_DispoList")
    end
end

-- ─── loadMap ─────────────────────────────────────────────────────────────────
function DispoList:loadMap(mapName)
    DispoList.extProdSpecKey = nil
    -- Sicherheits-Reset: playerFrozen und Such-Fokus immer deaktivieren.
    -- Frische Mission -> Input-Kontexte sind neu, nur unsere Flags zuruecksetzen
    -- (KEIN revertContext hier, sonst Warnung auf ROOT-Ebene).
    DispoList.searchFocused       = false
    DispoList.searchContextPushed = false
    DispoList.filterSearchActive  = false
    DispoList.filterSearchText    = ""
    if g_currentMission ~= nil and g_currentMission.hlUtils ~= nil then
        pcall(function()
            g_currentMission.hlUtils.playerFrozen = false
        end)
    end
    source(DispoList.modDir .. "scripte_dl/DL_FilterManager.lua")
    -- DL_SellpointEvents.lua NICHT hier source()n: die MP-Event-Klassen werden
    -- zur Compile-Zeit ueber modDesc <extraSourceFiles> registriert (InitEventClass
    -- ist zur Laufzeit nicht erlaubt -> "Event initialization only allowed at compile time").
    source(DispoList.modDir .. "scripte_dl/DL_SellpointUnlock.lua")
    source(DispoList.modDir .. "scripte_dl/draw/DL_FilterMenu_Draw.lua")
    source(DispoList.modDir .. "scripte_dl/draw/DL_FilterMenu_Modes.lua")  -- Mode-Ansichten (ausgelagert)
    source(DispoList.modDir .. "scripte_dl/xml/DL_ColSettings_GuiBox.lua")
    source(DispoList.modDir .. "scripte_dl/xml/DL_TitelHud_XmlHud.lua")
    source(DispoList.modDir .. "scripte_dl/draw/DL_TitelHud_DrawHud.lua")
    source(DispoList.modDir .. "scripte_dl/mouseKeyEvents/DL_TitelHud_MouseKeyEventsHud.lua")
    if not DispoList:getDetiServer() then
        Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission, function()
            DL_Filter:init()
            DispoList.buildFillTypeToBereich()  -- Order aus XML übernehmen
            DispoList:scanLagertypen()
            DispoList:RegisterDisplaySystem()
            -- Sellpoint-Freischalt-Konsolenbefehle zuverlaessig hier registrieren
            -- (onStartMission feuert garantiert -- anders als FSBaseMission.loadMapFinished
            -- beim source()-Zeitpunkt, das die dlsp-Befehle in Etappe 1 verpasst hat).
            if DL_SellpointUnlock ~= nil then DL_SellpointUnlock.registerCommands() end
        end)
    end
    DispoList:hookStorageChanges()

    -- Zentraler Speicherpunkt: ALLE DispoList-XMLs werden nur noch hier geschrieben,
    -- exakt synchron mit dem offiziellen Giants-Spielstand-Speichern (manuelles
    -- Speichern, Autosave, Speichern-und-Beenden). Ersetzt frueher ~30 verstreute
    -- eager-save-Aufrufe bei jeder Nutzerinteraktion, die mit OneDrive-Sync
    -- kollidieren konnten (verifiziert 01.07. gegen AutoDrive-Referenzimplementierung:
    -- AutoDrive.lua Zeile 238, exakt dasselbe Pattern). Nur der Host/Server schreibt,
    -- da nur dieser eine gueltige savegameDirectory hat (analog AutoDrive g_server-Check).
    Logging.info("[DispoList] ItemSystem.save-Hook registriert")
    ItemSystem.save = Utils.prependedFunction(ItemSystem.save, function()
        -- KRITISCHER FIX (verifiziert 02.07. per Log-Beweis): Pfad NICHT aus dem bei
        -- init() gecachten DL_Filter.xmlPath nehmen, sondern bei JEDEM Speichern frisch
        -- aus missionInfo.savegameDirectory neu berechnen -- exakt wie AutoDrive es
        -- macht (UserDataManager.lua, nie gecacht). Grund: Im Moment des Speicherns
        -- zeigt savegameDirectory oft auf den temporaeren "tempsavegame"-Ordner (FS25
        -- Patch 1.5+ Verhalten), den Giants danach automatisch komplett nach
        -- savegameXX kopiert. Schreiben wir stattdessen mit dem alten gecachten Pfad
        -- DIREKT nach savegameXX, landet unsere Datei NICHT im tempsavegame-Ordner und
        -- wird von Giants' eigenem Kopiervorgang direkt danach ueberschrieben/verworfen
        -- -- das war die Ursache fuer "Einstellungen nach Neustart weg".
        local freshSaveDir = g_currentMission ~= nil and g_currentMission.missionInfo ~= nil
            and g_currentMission.missionInfo.savegameDirectory or nil
        if freshSaveDir ~= nil and DL_Filter ~= nil then
            DL_Filter.xmlPath = freshSaveDir .. "/dispoList_filter.xml"
        end
        Logging.info("[DispoList] ItemSystem.save gefeuert -- g_server=%s DL_Filter=%s frischerXmlPath=%s",
            tostring(g_server ~= nil), tostring(DL_Filter ~= nil), tostring(DL_Filter ~= nil and DL_Filter.xmlPath or "nil"))
        if g_server ~= nil and DL_Filter ~= nil and DL_Filter.xmlPath ~= nil then
            DL_Filter:saveToXml()
            DL_Filter:saveBereiche()
            DL_Filter:saveBereichZuordnung()
            DL_Filter:savePauseSetting()
            Logging.info("[DispoList] Gespeichert: filter, bereiche, zuordnung, settings -> %s", tostring(DL_Filter.xmlPath))
        else
            Logging.info("[DispoList] NICHT gespeichert -- Bedingung nicht erfuellt (siehe oben)")
        end
    end)
end

-- 1:1 aus PIH (nur Namen angepasst)
-- registerActionEvent ist global definiert (ausserhalb loadMap)

function DispoList:hookStorageChanges()
    DispoList.dirtyFlag  = false
    DispoList.dirtyTimer = 0
    local origSetFillLevel = Storage.setFillLevel
    if origSetFillLevel ~= nil then
        Storage.setFillLevel = function(self, fillLevel, fillType, fillInfo)
            local result = origSetFillLevel(self, fillLevel, fillType, fillInfo)
            if (DispoList.refreshInterval or 5000) == 0 then return result end
            if not DispoList.dirtyFlag and not DispoList._refreshRunning then
                if g_currentMission ~= nil and g_currentMission.hlHudSystem ~= nil
                   and g_currentMission.hlHudSystem.hlBox ~= nil then
                    local box = g_currentMission.hlHudSystem.hlBox:getData("DL_Display_Box")
                    if box ~= nil and box.show == true then
                        DispoList.dirtyFlag = true
                    end
                end
            end
            return result
        end
    end
end

-- ─── Filter-State ────────────────────────────────────────────────────────────
DispoList.filterMenuOpen         = false
DispoList.filterSelStation       = nil
DispoList.filterSelBereich       = nil
DispoList.filterExpandedBereich  = nil    -- Akkordeon: aufgeklappter Bereich im Stations-Modus
DispoList.filterContextMenu      = nil    -- Rechtsklick-Kontextmenü {bereich, posX, posY}
DispoList.filterMode             = "bereich"
DispoList.filterLeftAreas        = {}
DispoList.filterRightAreas       = {}
DispoList.filterClearAllArea     = nil
DispoList.filterLeftScroll       = 1
DispoList.filterRightScroll      = 1

-- Pause-Toggle State
DispoList.filterPauseEnabled = false

-- Filter-Pause aufheben: Zeitraffer/Pause-Zustand wiederherstellen.
-- Gemeinsamer Helfer, damit die Wiederherstellung nur an EINER Stelle gepflegt wird
-- (wird beim Schliessen aus Haupt-, Filter- und Settings-Box aufgerufen).
function DispoList.restoreFilterPause()
    if not DispoList.filterPauseEnabled then return end
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

function DispoList:toggleFilterMenu()
    if g_currentMission.hlHudSystem == nil then return end
    local fbox = g_currentMission.hlHudSystem.hlBox:getData("DL_Filter_Box")
    if fbox == nil then return end
    fbox.show = not fbox.show
    DispoList.filterMenuOpen = fbox.show
    if fbox.show then
        -- Reset beim Öffnen
        DispoList.filterSelStation       = nil
        DispoList.filterSelBereich       = nil
        DispoList.filterLeftScroll       = 1
        DispoList.filterAllStations      = nil
        if DL_FilterMenu_Draw ~= nil then DL_FilterMenu_Draw.clearCache() end
        -- Spiel pausieren wenn gewünscht
        if DispoList.filterPauseEnabled then
            DispoList.previousTimeScale = g_currentMission.timeScale
            DispoList.previousMissionTimeScale = g_currentMission.missionInfo ~= nil and g_currentMission.missionInfo.timeScale or nil
            if g_currentMission.timeScale ~= nil then g_currentMission.timeScale = 0 end
            if g_currentMission.missionInfo ~= nil and g_currentMission.missionInfo.timeScale ~= nil then g_currentMission.missionInfo.timeScale = 0 end
            if g_currentMission.paused ~= nil then g_currentMission.paused = true end
        end
        DL_FilterMenu_Draw._remainingCache = nil
        -- xmlPath sicherstellen (falls init() nicht aufgerufen wurde)
        if DL_Filter ~= nil and DL_Filter.xmlPath == nil then
            local saveDir = g_currentMission and g_currentMission.missionInfo and g_currentMission.missionInfo.savegameDirectory
            if saveDir ~= nil then
                DL_Filter.xmlPath = saveDir .. "/dispoList_filter.xml"
                DL_Filter:loadBereiche()
                DL_Filter:loadBereichZuordnung()
                DispoList.buildFillTypeToBereich()
            end
        end
    else
        -- Suche beenden (Fokus+Kontext frei, Query leer)
        DispoList.resetSearch()
        -- Pause aufheben beim Schließen
        DispoList.restoreFilterPause()
    end
end


-- ─── g_farmCore Export ───────────────────────────────────────────────────────
-- Ermittelt den Grund fuer einen (evtl. leeren) Datenstand -- fuer den FarmCore-Export.
-- Basis: CurrentItems (echte Datenliste) + activeLagertypen.
local function getDispoReason()
    local anyActive = false
    for _, active in pairs(DispoList.activeLagertypen or {}) do
        if active then anyActive = true; break end
    end
    if not anyActive then return "no_active_lagertyp" end
    local t = DispoList.CurrentItems
    if t == nil or #t == 0 then return "no_sellable_stock" end
    for _, entry in ipairs(t) do
        if (entry.sellable or 0) > 0 then return "ok" end
    end
    return "no_sellable_stock"
end

g_farmCore = g_farmCore or { modules = {} }
g_farmCore.modules.dispoList = {

    -- Gibt Waren zurück die im aktuellen Monat Höchstpreis haben
    -- Rückgabe: {{ fillType, name, price, station }, ...}
    getBestPriceNow = function()
        local result = {}
        local currentPeriod = g_currentMission.environment.currentPeriod
        local table_ = DispoList.CurrentItems
        if table_ == nil then return result end
        local seen = {}
        for _, entry in ipairs(table_) do
            local key = entry.ftName or ""
            if not seen[key] and entry.bestMonth == currentPeriod then
                seen[key] = true
                table.insert(result, {
                    fillType = entry.ftName,
                    name     = entry.title,
                    amount   = entry.sellable,
                    price    = entry.price,
                    station  = entry.stationName,
                    bereich  = entry.bereich and entry.bereich.name or nil,
                })
            end
        end
        return result
    end,

    -- Gesamtwert aller freien Waren
    getGesamtwert = function()
        local total = 0
        local table_ = DispoList.CurrentItems
        if table_ == nil then return 0, getDispoReason() end
        for _, entry in ipairs(table_) do
            if (entry.sellable or 0) > 0 and (entry.price or 0) > 0 then
                total = total + entry.sellable * entry.price
            end
        end
        return total, getDispoReason()
    end,

    -- Alle freien Waren mit Menge und Wert
    -- Aufnahmebedingung: sellable > 0 (normaler Fall) ODER ecReserve > 0
    -- (Baustelle braucht diese Ware -- dann Eintrag auch bei negativem
    -- sellable aufnehmen, damit FarmAssistant stockLevel/ecReserve als
    -- rohe Zahlen fuer die eigene Baustellen-vs-Lager-Rechnung bekommt,
    -- 14.07., siehe FarmAssistant-Session).
    getFreeGoods = function()
        local result = {}
        local table_ = DispoList.CurrentItems
        if table_ == nil then return result, getDispoReason() end
        local seen = {}
        for _, entry in ipairs(table_) do
            local key = entry.ftName or ""
            if not seen[key] and ((entry.sellable or 0) > 0 or (entry.ecReserve or 0) > 0) then
                seen[key] = true
                table.insert(result, {
                    fillType   = entry.ftName,
                    name       = entry.title,
                    amount     = entry.sellable,
                    stockLevel = entry.stockLevel,    -- NEU (14.07.): roher Bestand, ungedeckelt von Fabrik-Puffer/ecReserve
                    price      = entry.price,
                    station    = entry.stationName,
                    bereich    = entry.bereich and entry.bereich.name or nil,
                    ecReserve  = entry.ecReserve or 0,  -- davon fuer Baustellen reserviert (0 wenn EC nicht installiert/aus)
                })
            end
        end
        return result, getDispoReason()
    end,

    -- Offener Baustellen-Materialbedarf (EverythingConstructable), roh je FillType.
    -- Rueckgabe: {{ fillType, name, amount }, ...}, projectCount
    -- amount = noch offener Rest (mat.amount - mat.delivered) ueber alle offenen
    -- Baustellen summiert. Leere Liste wenn EC nicht installiert, deaktiviert,
    -- oder keine offenen Baustellen vorhanden -- projectCount unterscheidet die Faelle.
    getConstructionDemand = function()
        local result = {}
        local demand = DispoList.lastConstructionDemand or {}
        for idx, amount in pairs(demand) do
            local ft = g_fillTypeManager:getFillTypeByIndex(idx)
            if ft ~= nil and amount > 0 then
                table.insert(result, {
                    fillType = ft.name,
                    name     = ft.title,
                    amount   = amount,
                })
            end
        end
        return result, DispoList.lastEcProjectCount or 0
    end,
}

-- ─── deleteMap ───────────────────────────────────────────────────────────────
function DispoList:deleteMap()
    DispoList.isInit = false
    -- Kein eager save() mehr hier -- alle Speicherungen laufen zentral ueber den
    -- ItemSystem.save-Hook (siehe DispoList:loadMap), exakt synchron mit dem
    -- offiziellen Giants-Speicherpunkt. Analog zu AutoDrive (verifiziert 01.07.).
end

-- ─── checkPresetDialog ──────────────────────────────────────────────────────
-- Wird beim allerersten Öffnen des HUDs (Tastendruck) aufgerufen.
-- Erststart-Entscheidung automatisch: ZL vorhanden -> ZL-Preset, sonst -> Giants-Preset.
-- Kein Dialog/Fenster mehr — der Presets-Button im Einstellungs-HUD bleibt für
-- spaeteres manuelles Umschalten unveraendert bestehen.
function DispoList:checkPresetDialog()
    if DL_Filter == nil or DL_Filter.presetDialogShown then return end
    DL_Filter.presetDialogShown = true
    DL_Filter.userPersonalized  = false

    if (DispoList.foundZentrallager or 0) > 0 then
        -- ZL erkannt: Zentrallager-Preset automatisch laden
        DL_Filter:applyPreset(DispoList.BEREICHE_PRESET_ERWEITERT)
        DL_Filter:autoAssignFromZentrallager()
        DL_Filter.activePreset = "ZL"
    else
        -- Kein ZL: Giants-Standard automatisch laden
        if DispoList.BEREICHE_DEFAULT ~= nil then
            DispoList.BEREICHE = {}
            DL_Filter.bereichZuordnung = {}
            for name, data in pairs(DispoList.BEREICHE_DEFAULT) do
                DispoList.BEREICHE[name] = { order = data.order, fillTypes = data.fillTypes or {} }
                DL_Filter.bereichZuordnung[name] = {}
                for _, ftName in ipairs(data.fillTypes or {}) do
                    DL_Filter.bereichZuordnung[name][ftName] = true
                end
            end
        end
        DL_Filter.activePreset = "GIANTS"
    end

    -- Kein eager save() mehr -- naechster ItemSystem.save schreibt konsistent alles
    DispoList:refreshDispoTable()

    -- Erst-Überblick: Haupt-HUD, Filter-HUD und Einstellungs-HUD nebeneinander
    -- oeffnen, damit der Spieler auf einen Blick sieht was er einstellen kann.
    if g_currentMission.hlHudSystem ~= nil and g_currentMission.hlHudSystem.hlBox ~= nil then
        local dBox = g_currentMission.hlHudSystem.hlBox:getData("DL_Display_Box")
        if dBox ~= nil and dBox.screen ~= nil then
            dBox.screen:setPosition(0.04, 0.12, "box")
            -- Sichtbarkeit nicht mehr annehmen (frueher setzte das immer der
            -- Tastendruck-Handler vor diesem Aufruf) -- jetzt selbst erzwingen,
            -- da checkPresetDialog() auch unabhaengig vom Tastendruck laeuft.
            dBox.show = true
            dBox:setUpdateState(true)
        end
        local fBox = g_currentMission.hlHudSystem.hlBox:getData("DL_Filter_Box")
        if fBox == nil then
            DL_Display_XmlBox:loadBox("DL_Filter_Box", true)
            fBox = g_currentMission.hlHudSystem.hlBox:getData("DL_Filter_Box")
        end
        if fBox ~= nil then
            fBox.screen:setPosition(0.40, 0.12, "box")
            fBox.show = true
            fBox:setUpdateState(true)
        end
    end
    if DL_ColSettings ~= nil then
        local gb = DL_ColSettings:createGuiBox()
        if gb ~= nil and gb.screen ~= nil then
            gb.screen:setPosition(0.74, 0.12, "guiBox")
            -- WICHTIG: Die automatische "passt zum Inhalt"-Höhenberechnung im
            -- Framework (hlGuiBox:resetDimension) greift nur, wenn noch KEINE
            -- gespeicherte guibox-XML existiert (modSettings/HL/HudSystem/guibox/
            -- DL_ColSettings_GuiBox.xml). Die existiert aber meist schon global
            -- aus frueheren Sessions (ggf. mit kleinerer Hoehe) -> hier bewusst
            -- selbst erzwingen, damit der Spieler beim Erststart wirklich alle
            -- Einstellungen auf einen Blick sieht, ohne scrollen zu muessen.
            if gb.lineHeight ~= nil and gb.titleHeight ~= nil and gb.viewMaxLines ~= nil then
                gb.screen.height = (gb.lineHeight * gb.viewMaxLines) + gb.titleHeight
            end
            gb:setShow(true)
        end
    end
end

-- ─── update ──────────────────────────────────────────────────────────────────
function DispoList:update(dt)
    if DispoList:getDetiServer() then return end

    if not DispoList.isInit then
        DispoList.isInit = true
        -- WICHTIG: checkPresetDialog() hing bisher ausschliesslich am Tastendruck-Event
        -- (DL_ONOFFDISPLAY, show false->true). Die Box-Sichtbarkeit wird aber global
        -- (modSettings/HL/HudSystem/box/DL_Display_Box.xml) gespeichert, nicht pro
        -- Savegame -> war die Box von der letzten Session noch "offen" (show=true),
        -- feuert das Tastendruck-Event nie und die Erststart-Logik (Preset, 3-HUD-
        -- Positionierung) lief nie. Deshalb hier zusaetzlich beim allerersten Tick
        -- pruefen -- checkPresetDialog() ist durch presetDialogShown selbst bereits
        -- gegen Mehrfachausfuehrung abgesichert, ein doppelter Aufruf ist also sicher.
        DispoList:checkPresetDialog()
    end

    -- Settings-Box schliessen wenn Hauptbox ODER Filterbox schliesst
    local mainBoxShow = g_currentMission ~= nil and
        g_currentMission.hlHudSystem ~= nil and
        g_currentMission.hlHudSystem.hlBox ~= nil and
        (g_currentMission.hlHudSystem.hlBox:getData("DL_Display_Box") or {}).show == true
    local filterBoxShow = g_currentMission ~= nil and
        g_currentMission.hlHudSystem ~= nil and
        g_currentMission.hlHudSystem.hlBox ~= nil and
        (g_currentMission.hlHudSystem.hlBox:getData("DL_Filter_Box") or {}).show == true
    local anyBoxShow = mainBoxShow or filterBoxShow
    if DispoList._lastMainBoxShow == true and not anyBoxShow then
        -- Alle DispoList-Boxen wurden geschlossen
        if DL_ColSettings ~= nil and DL_ColSettings.guiBox ~= nil
           and DL_ColSettings.guiBox.show then
            DL_ColSettings.guiBox.show = false
            DL_ColSettings.guiBox = nil
        end
    end
    DispoList._lastMainBoxShow = anyBoxShow


    -- Cursor blinken
    if DispoList.searchActive then
        DispoList.searchCursorTimer = DispoList.searchCursorTimer + dt
        if DispoList.searchCursorTimer > 500 then
            DispoList.searchCursorTimer = 0
            DispoList.searchCursorVisible = not DispoList.searchCursorVisible
        end
    end
    if DispoList.filterSearchActive then
        DispoList.filterSearchCursorTimer = DispoList.filterSearchCursorTimer + dt
        if DispoList.filterSearchCursorTimer > 500 then
            DispoList.filterSearchCursorTimer = 0
            DispoList.filterSearchCursorVisible = not DispoList.filterSearchCursorVisible
        end
    end

    -- Suche: wenn searchText geändert wurde -> sofort neu laden
    if DispoList.searchDirty then
        DispoList.searchDirty = false
        DispoList:refreshDispoTable()
        local box = g_currentMission.hlHudSystem ~= nil and
                    g_currentMission.hlHudSystem.hlBox ~= nil and
                    g_currentMission.hlHudSystem.hlBox:getData("DL_Display_Box") or nil
        if box ~= nil then box.needsUpdate = true end
    end

    -- dirtyFlag Debounce: Wartezeit = eingestelltes Intervall (mind. 3s)
    local interval = DispoList.refreshInterval or 5000
    if DispoList.dirtyFlag and interval > 0 then
        DispoList.dirtyTimer = (DispoList.dirtyTimer or 0) + dt
        local waitTime = math.max(3000, interval)
        if DispoList.dirtyTimer >= waitTime then
            DispoList.dirtyFlag  = false
            DispoList.dirtyTimer = 0
            DispoList.timePast   = 0
            -- Kein Refresh wenn nach Erloes sortiert (Liste wuerde wegspringen)
            if not DispoList.sortByValue then
                if g_currentMission.hlHudSystem ~= nil and g_currentMission.hlHudSystem.hlBox ~= nil then
                    local box = g_currentMission.hlHudSystem.hlBox:getData("DL_Display_Box")
                    if box ~= nil and box.show == true then
                        DispoList:refreshDispoTable()
                    end
                end
            end
        end
    end

    -- Countdown-Timer hochzählen (immer, unabhängig vom Intervall)
    DispoList.refreshSinceMs = (DispoList.refreshSinceMs or 0) + dt

    -- Auto-Refresh (Intervall konfigurierbar, 0 = manuell/nur beim Öffnen)
    -- Pausiert automatisch wenn Sortierung nach Wert aktiv (Liste würde sonst wegspringen)
    local interval = DispoList.refreshInterval or 5000
    if interval > 0 and not DispoList.sortByValue then
        DispoList.timePast = DispoList.timePast + dt
        if DispoList.timePast >= interval then
            DispoList.timePast = 0
            if g_currentMission.hlHudSystem ~= nil and g_currentMission.hlHudSystem.hlBox ~= nil then
                local box = g_currentMission.hlHudSystem.hlBox:getData("DL_Display_Box")
                if box ~= nil and box.show == true then
                    DispoList:refreshDispoTable()
                end
            end
        end
    end
end

function DispoList:getDetiServer()
    return g_server ~= nil and g_client ~= nil and g_dedicatedServer ~= nil
end

-- ─── Action (Toggle) ─────────────────────────────────────────────────────────

-- ─── Input-Blocking Hilfsfunktionen ─────────────────────────────────────────
-- Setzt/loest den Fokus des Suchfelds. Bei Fokus wird ein eigener Giants-
-- Input-Kontext gesetzt ("DISPOLIST_SEARCH"): darin sind KEINE Gameplay-/Fahr-
-- Aktionen registriert (nur globale wie ESC), also steuern die Tasten nur noch
-- die Suche. Beim Loslassen (Enter/Feld-Klick weg/HUD zu) wird der Kontext
-- zurueckgesetzt -> Fahren wieder frei. Verifiziert aus Giants InputBinding.lua
-- (setContext/revertContext, ROOT_CONTEXT). Idempotent ueber searchContextPushed.
function DispoList.setSearchFocus(on)
    on = (on == true)
    DispoList.searchFocused = on
    if g_inputBinding == nil then return end
    if on then
        if not DispoList.searchContextPushed then
            g_inputBinding:setContext("DISPOLIST_SEARCH", true, false)
            DispoList.searchContextPushed = true
        end
    else
        if DispoList.searchContextPushed then
            g_inputBinding:revertContext(true)
            DispoList.searchContextPushed = false
        end
    end
    -- TEMP-Diagnose (nur bei Fokuswechsel, kein Spam): zeigt Fokus-Zustand +
    -- welcher Input-Kontext danach aktiv ist. Bei fertigem Build wieder raus.
    if DispoList.searchDebug then
        local ctx = (g_inputBinding.getContextName ~= nil) and g_inputBinding:getContextName() or "?"
        print(string.format("[DispoList] setSearchFocus(%s) -> focused=%s, context=%s, pushed=%s",
            tostring(on), tostring(DispoList.searchFocused), tostring(ctx), tostring(DispoList.searchContextPushed)))
    end
end

-- Filter-Suche komplett beenden: Fokus loesen (Kontext frei), Query leeren.
-- An JEDEM Schliess-Weg der Filter-Box aufgerufen (auch HL-eigener X-Button).
function DispoList.resetSearch()
    DispoList.setSearchFocus(false)
    DispoList.filterSearchActive = false
    DispoList.filterSearchText   = ""
end

-- Haupt-Lupe komplett beenden: Fokus loesen (Kontext frei), Query leeren, Lupe aus.
-- An JEDEM Schliess-Weg der Haupt-Box aufgerufen (HUD-Toggle, X-Button).
function DispoList.resetMainSearch()
    DispoList.setSearchFocus(false)
    DispoList.searchActive = false
    DispoList.searchText   = ""
    DispoList.searchDirty  = true
end

-- Gemeinsamer Renderer fuer BEIDE Suchfelder (Haupt-Lupe + Filter-Lupe) — eine
-- Wahrheit statt zwei fast identischer Draw-Bloecke. Zeichnet den Fokus-
-- Hintergrund (nur bei Fokus), den Text (hell/fett = tippt, grau = bestaetigt)
-- und registriert den Klickbereich (= wieder ins Feld). Gibt das neue ixPos
-- zurueck. `text`/`cursorVisible`/`whereClick` unterscheiden die zwei Felder.
function DispoList.renderSearchField(box, typPos, ixPos, iconPosY, iconH, size, difW, bgLine, inArea, text, cursorVisible, whereClick)
    local focused = DispoList.searchFocused
    local cursor  = (focused and cursorVisible) and "|" or ""
    local shown   = (text or "") .. cursor
    if shown == "" then shown = " " end   -- leeres Feld trotzdem sichtbar
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(focused)
    local fieldX1 = ixPos
    local fieldX2 = fieldX1 + getTextWidth(size, shown) + difW * 2
    if focused and bgLine ~= nil then
        g_currentMission.hlUtils.setOverlay(bgLine, fieldX1 - difW * 0.6, iconPosY - iconH * 0.30,
            (fieldX2 - fieldX1) + difW * 0.4, iconH * 1.20)
        g_currentMission.hlUtils.setBackgroundColor(bgLine, {0.0, 0.42, 0.36, 0.90})
        bgLine:render()
    end
    if focused then setTextColor(0.55, 1.0, 0.92, 1) else setTextColor(unpack(DL_Colors.grauMit)) end
    renderText(fieldX1, iconPosY, size, utf8Substr(shown, 0))
    setTextBold(false)
    if inArea and not g_currentMission.hlUtils:disableInArea() then
        box:setClickArea({fieldX1 - difW, fieldX2, iconPosY - iconH * 0.3, iconPosY + iconH * 0.7,
            onClick = box.onSettingClick, whereClick = whereClick, typPos = typPos})
    end
    return fieldX2
end

-- Gemeinsamer Icon-Renderer fuer alle Hover-Icons (Haupt-HUD + Filter-Panel) —
-- eine Wahrheit statt der frueheren fast identischen Zeichner (drawPng/drawFIcon;
-- ein totes drittes hlIcon wurde entfernt). Farben aus dem Theme DL_Colors.
-- Faerbt (Hover-Weiss / aktiv / inaktiv), zeichnet, setzt Tooltip + Klickflaeche.
-- Das fertige Overlay `o` liefert der Aufrufer (Quelle unterscheidet sich je Box:
-- eigenes PNG aus images/ vs. HL-Default-Icon aus dem Sheet). `geo` buendelt die
-- Layout-Werte (siehe Aufrufstellen). Gibt das neue posX zurueck.
function DispoList.drawHoverIcon(box, args, geo, o, posX, activeCol, inactiveCol, whereClick, tooltip)
    g_currentMission.hlUtils.setOverlay(o, posX, geo.iconPosY, geo.iconW, geo.iconH)
    g_currentMission.hlUtils.setStateInArea(o)
    local inIcon = (o.mouseInArea ~= nil) and o.mouseInArea() or false
    local col = inIcon and DL_Colors.iconHover
             or activeCol or inactiveCol or DL_Colors.iconIdle
    g_currentMission.hlUtils.setBackgroundColor(o, col)
    o:render()
    if inIcon and tooltip and g_currentMission.hlHudSystem.infoDisplay.on then
        local ttSize = geo.size * 0.85
        local ttW = getTextWidth(ttSize, utf8Substr(tooltip .. "  ", 0)) * 1.1
        g_currentMission.hlHudSystem:addTextDisplay({txt=tooltip, maxLine=0, txtSize=ttSize,
            posX = geo.x + (geo.w - ttW) * 0.5,
            posY = geo.iconLineY + geo.lineH * 1.0})
    end
    if whereClick and geo.inArea and not g_currentMission.hlUtils:disableInArea() then
        box:setClickArea({o.x, o.x+o.width, o.y, o.y+o.height,
            onClick=box.onSettingClick, whereClick=whereClick, typPos=args.typPos})
    end
    return posX + geo.iconW + geo.difW
end

-- Kompatibilitaets-Shim: alte Aufrufe von setInputBlocking(bool) -> Fokus setzen.
function DispoList.setInputBlocking(block)
    DispoList.setSearchFocus(block)
end

-- ─── keyEvent: Texteingabe für Suche ────────────────────────────────────────
-- Mausposition cachen (wird vor HL-System-Listener aufgerufen)
function DispoList:mouseEvent(posX, posY, isDown, isUp, button)
    DispoList._mouseX = posX
    DispoList._mouseY = posY
    -- Hinweis: "Klick woanders loest Fokus" laeuft NICHT ueber rohe mouseEvents
    -- (die feuern zu oft/synthetisch und koennen den Fokus sofort wieder
    -- wegklicken). Stattdessen blurrt der onSettingClick-Handler der Filter-Box
    -- bei einem echten Klick auf ein ANDERES Bedienelement -- siehe
    -- DL_FilterMenu_Draw.lua.

    -- Mausrad-Scroll für linke Spalte im Filter-Panel
    if DispoList.filterMenuOpen and (button == Input.MOUSE_BUTTON_WHEEL_UP or button == Input.MOUSE_BUTTON_WHEEL_DOWN) and isDown then
        local fbox = g_currentMission.hlHudSystem and g_currentMission.hlHudSystem.hlBox and
                     g_currentMission.hlHudSystem.hlBox:getData("DL_Filter_Box")
        if fbox ~= nil and fbox.show then
            local bx = fbox.screen.posX or 0
            local bw = fbox.screen.width or 0
            local col2X = bx + bw * 0.32
            -- Maus in linker Spalte?
            if posX >= bx and posX < col2X then
                local dir = button == Input.MOUSE_BUTTON_WHEEL_UP and -1 or 1
                DispoList.filterLeftScroll = math.max(1, (DispoList.filterLeftScroll or 1) + dir)
            end
            -- Rechte Spalte: HL-System übernimmt bounds[1] automatisch
        end
    end
end

function DispoList:keyEvent(unicode, sym, modifier, isDown)
    -- Live-Suche: Tasten NUR abfangen, solange das Suchfeld den FOKUS hat.
    -- Waehrenddessen ist der Fahr-/Gameplay-Input ueber den Input-Kontext
    -- "DISPOLIST_SEARCH" suspendiert (siehe DispoList.setSearchFocus). Enter
    -- loest den Fokus -> Filter bleibt sichtbar, Steuerung wieder frei.
    -- Live-Suche: Tasten NUR abfangen, solange ein Suchfeld den FOKUS hat.
    -- Es gibt ZWEI Suchen: die Haupt-Lupe (searchActive/searchText) und die
    -- Filter-Suche (filterSearchActive/filterSearchText). Beide setzen beim
    -- Oeffnen searchFocused=true (Input-Kontext "DISPOLIST_SEARCH" -> Fahren
    -- gesperrt). Hier ins jeweils aktive Feld tippen. Enter loest den Fokus.
    if DispoList.searchFocused then
        if not isDown then return end
        if DispoList.searchDebug then
            print(string.format("[DispoList] keyEvent while focused: sym=%s unicode=%s main=%s filter=%s",
                tostring(sym), tostring(unicode), tostring(DispoList.searchActive), tostring(DispoList.filterSearchActive)))
        end
        if sym == Input.KEY_return or sym == Input.KEY_kp_enter then
            DispoList.setSearchFocus(false)   -- bestaetigen, weiterspielen
            return
        end
        -- Zielfeld: Haupt-Suche hat Vorrang, sonst Filter-Suche
        local useMain = DispoList.searchActive == true
        if sym == Input.KEY_backspace then
            if useMain then
                local len = utf8Strlen(DispoList.searchText)
                if len > 0 then
                    DispoList.searchText = utf8Substr(DispoList.searchText, 0, len - 1)
                    DispoList.searchDirty = true
                end
            else
                local len = utf8Strlen(DispoList.filterSearchText)
                if len > 0 then
                    DispoList.filterSearchText = utf8Substr(DispoList.filterSearchText, 0, len - 1)
                end
            end
            return
        elseif unicode > 31 and unicode < 128 then
            local ok, char = pcall(string.char, unicode)
            if ok and char ~= nil and char ~= "" then
                if useMain then
                    DispoList.searchText  = DispoList.searchText .. char
                    DispoList.searchDirty = true
                else
                    DispoList.filterSearchText = DispoList.filterSearchText .. char
                end
            end
            return
        end
        return   -- alle anderen Tasten schlucken (Fahrzeug soll nicht reagieren)
    end
    -- Kein Fokus -> keyEvent macht nichts, Tasten gehen ans Spiel (Fahren frei).
end

-- ─── mouseEvent: nicht genutzt ───────────────────────────────────────────────

-- Callback direkt auf PlayerInputComponent definieren (global, beim Script-Laden)
function PlayerInputComponent:dlSystemActionCallback(actionName, inputValue, callbackState, isAnalog, isMouse, deviceCategory)
    if not g_currentMission.hlUtils.dragDrop.on then
        if actionName == "DL_ONOFFDISPLAY" then
            if g_currentMission.hlHudSystem ~= nil and g_currentMission.hlHudSystem.hlBox ~= nil then
                local box = g_currentMission.hlHudSystem.hlBox:getData("DL_Display_Box");
                if box ~= nil and box.show ~= nil then
                    box.show = not box.show;
                    box:setUpdateState(true);
                    if box.show then
                        DispoList:refreshDispoTable();
                        DispoList:checkPresetDialog()
                        DispoList.timePast       = 0
                        DispoList.refreshSinceMs = 0
                    else
                        -- Meldungen nach Schließen zurücksetzen
                        DispoList.deltaNewCount = 0
                        DispoList.deltaNotOnMap = 0
                        DispoList.zlHinweisGesehen = true  -- Zentrallager-Hinweis dauerhaft ausblenden
                        local fbox = g_currentMission.hlHudSystem.hlBox:getData("DL_Filter_Box");
                        if fbox ~= nil and fbox.show then
                            fbox.show = false;
                            DispoList.filterMenuOpen = false;
                            DispoList.resetSearch()  -- Sicherheits-Reset (Fokus+Kontext frei, Query leer)
                            DispoList.dlSelectedFt = nil;
                            DispoList.dlSelectedFtTitle = nil;
                            DispoList.dlSelectedFtBereich = nil;
                            DispoList.filterSearchActive = false;
                            DispoList.filterSearchText = "";
                            DispoList.filterResetConfirm = false;
                        end
                        DispoList.resetMainSearch()  -- Haupt-Lupe beenden (Fokus frei, Query leer)
                    end
                end
            end
        end;
    end;
end;

-- Append global beim Script-Laden (bevor loadMap oder Spieler-Spawn)
PlayerInputComponent.registerGlobalPlayerActionEvents = Utils.appendedFunction(
    PlayerInputComponent.registerGlobalPlayerActionEvents,
    function(self, controlling)
        local inputAction = InputAction["DL_ONOFFDISPLAY"];
        local callbackTarget = self;
        local callbackFunc = self.dlSystemActionCallback;
        local _, eventId = g_inputBinding:registerActionEvent(inputAction, callbackTarget, callbackFunc, false, true, false, true, nil, true);
        g_inputBinding:setActionEventTextVisibility(eventId, false);
    end
)

addModEventListener(DispoList)

-- Mouse/Key Events werden über box.onClick und box.onKeyEvent im HL-System registriert
-- Siehe DL_Display_XmlBox.lua
