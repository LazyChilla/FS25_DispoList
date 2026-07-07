--
-- FS25 - DispoList v2.0
-- Dispositionsliste: Zentrallager-Bestand + meistbietende Verkaufsstation
-- Basiert auf HappyLooser HUD System
--

DispoList = {}
DispoList.Debug = false
DispoList.isInit = false
DispoList.timePast       = 0
DispoList.refreshInterval  = 5000 -- ms: 5000/15000/30000/60000/120000/0=manuell (Default: 5 Sekunden)
DispoList.refreshSinceMs   = 0     -- ms seit letztem Refresh (für Countdown-Anzeige)
DispoList.CurrentItems = {}
DispoList.modDir = g_currentModDirectory
DispoList.searchActive = false
DispoList.searchText   = ""
DispoList.searchDirty  = false
DispoList.searchCursorTimer = 0
DispoList.searchCursorVisible = true
-- FilterBox Suche (separate Variablen)
DispoList.filterSearchActive  = false
DispoList.filterSearchText    = ""
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
DispoList.reserveStunden      = 24     -- Zeitreserve für Fabrik-Puffer in Stunden

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

-- ZL-Filter: nur diese Bereiche anzeigen wenn "nur ZL"-Button aktiv
-- Erweiterbar wenn FedAction neue ZL-Lager baut (z.B. 16x-Karte)
DispoList.ZL_BEREICHE_FILTER = {
    "Fluessig", "Kuehlung", "Lebensmittel", "ObstGemuese", "Werkstoffe"
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
DispoList.VERSION          = "v1.2.2.0"-- Build-Version (in Icon-Zeile angezeigt)

-- ─── Lokalisierung ───────────────────────────────────────────────────────────
local DL_L10N = {
    spalte_ware        = {de="Ware",          en="Goods",        fr="Produit",      it="Merce",        pt="Produto",      es="Producto"},
    spalte_bestand     = {de="Bestand",        en="Stock",        fr="Stock",        it="Stock",        pt="Estoque",      es="Stock"},
    spalte_frei        = {de="Frei",           en="Free",         fr="Libre",        it="Libero",       pt="Livre",        es="Libre"},
    spalte_preis       = {de="Preis",          en="Price",        fr="Prix",         it="Prezzo",       pt="Preço",        es="Precio"},
    spalte_max         = {de="Max",            en="Max",          fr="Max",          it="Max",          pt="Max",          es="Max"},
    spalte_wert        = {de="Wert",           en="Value",        fr="Valeur",       it="Valore",       pt="Valor",        es="Valor"},
    spalte_frei_wert   = {de="Frei Wert",      en="Free Val.",    fr="Val. libre",   it="Val. lib.",    pt="Val. livre",   es="Val. libre"},
    spalte_frei_max    = {de="Frei Max",       en="Free Max",     fr="Max libre",    it="Max lib.",     pt="Max livre",    es="Max libre"},
    spalte_bester      = {de="Bester",         en="Best",         fr="Meilleur",     it="Migliore",     pt="Melhor",       es="Mejor"},
    spalte_monat       = {de="Monat",          en="Month",        fr="Mois",         it="Mese",         pt="Mes",          es="Mes"},
    status_pausiert    = {de="Pausiert",       en="Paused",       fr="En pause",     it="In pausa",     pt="Pausado",      es="Pausado"},
    status_manuell     = {de="manuell",        en="manual",       fr="manuel",       it="manuale",      pt="manual",       es="manual"},
    filter_titel       = {de="DispoList Filter",en="DispoList Filter",fr="DispoList Filtre",it="DispoList Filtro",pt="DispoList Filtro",es="DispoList Filtro"},
    filter_bereich_lbl = {de="Bereich:",       en="Zone:",        fr="Zone:",        it="Zona:",        pt="Zona:",        es="Zona:"},
    filter_station_lbl = {de="Station:",       en="Station:",     fr="Station:",     it="Stazione:",    pt="Estacao:",     es="Estacion:"},
    filter_suche_lbl   = {de="Suche:",         en="Search:",      fr="Chercher:",    it="Cerca:",       pt="Buscar:",      es="Buscar:"},
    filter_bereich_hint= {de="Bitte links einen Bereich auswaehlen",en="Please select a zone on the left",fr="Selectionner une zone a gauche",it="Seleziona una zona a sinistra",pt="Selecione uma zona a esquerda",es="Seleccione una zona a la izquierda"},
    filter_station_hint= {de="Bitte links eine Station auswaehlen",en="Please select a station on the left",fr="Selectionner une station a gauche",it="Seleziona una stazione a sinistra",pt="Selecione uma estacao a esquerda",es="Seleccione una estacion a la izquierda"},
    filter_keine_treffer={de="Keine Treffer",  en="No results",   fr="Aucun resultat",it="Nessun risultato",pt="Sem resultados",es="Sin resultados"},
    hint_zl_empty      = {de="Keine ZL/CW-Bereiche gefunden — bitte ZL/CW-Preset laden (Presets-Button)",en="No ZL/CW zones found — please load the ZL/CW preset (Presets button)",fr="Aucune zone ZL/CW trouvee — veuillez charger le preset ZL/CW (bouton Presets)",it="Nessuna zona ZL/CW trovata — carica il preset ZL/CW (pulsante Presets)",pt="Nenhuma zona ZL/CW encontrada — carregue a predefinicao ZL/CW (botao Presets)",es="No se encontraron zonas ZL/CW — cargue el preset ZL/CW (boton Presets)"},
    filter_gesamtwert  = {de="Gesamtwert freier Waren:",en="Total value of free goods:",fr="Valeur totale produits libres:",it="Valore totale merci libere:",pt="Valor total produtos livres:",es="Valor total productos libres:"},
    hint_lager_check   = {de="Nichts sichtbar? Pruefe die aktiven Lagertypen (Einstellungen)",en="Nothing shown? Check your active storage types (Settings)",fr="Rien d'affiche? Verifiez les types de stockage actifs (Parametres)",it="Niente visualizzato? Controlla i tipi di deposito attivi (Impostazioni)",pt="Nada visivel? Verifique os tipos de armazenamento ativos (Definicoes)",es="Nada visible? Comprueba los tipos de almacen activos (Ajustes)"},
    hint_kein_bestand  = {de="Aktuell kein verkaufbarer Bestand",en="No sellable stock right now",fr="Aucun stock vendable actuellement",it="Nessuna merce vendibile al momento",pt="Sem stock vendavel de momento",es="Sin existencias vendibles ahora mismo"},
    -- Gruppe A: Buttons / Kontextmenue / Dialoge
    btn_neuer_bereich  = {de="+ Neuer Bereich",en="+ New zone",fr="+ Nouvelle zone",it="+ Nuova zona",pt="+ Nova zona",es="+ Nueva zona"},
    btn_rueckgaengig   = {de="<< Rueckgaengig",en="<< Undo",fr="<< Annuler",it="<< Annulla",pt="<< Desfazer",es="<< Deshacer"},
    tt_suche_schliessen= {de="Suche schliessen",en="Close search",fr="Fermer la recherche",it="Chiudi la ricerca",pt="Fechar a pesquisa",es="Cerrar la busqueda"},
    tt_suche_oeffnen   = {de="Suche oeffnen  |  Achtung: Tasten steuern weiterhin das Fahrzeug!",en="Open search  |  Note: keys still control the vehicle!",fr="Ouvrir la recherche  |  Attention: les touches commandent toujours le vehicule!",it="Apri la ricerca  |  Attenzione: i tasti comandano ancora il veicolo!",pt="Abrir a pesquisa  |  Atencao: as teclas continuam a controlar o veiculo!",es="Abrir la busqueda  |  Atencion: las teclas siguen controlando el vehiculo!"},
    hint_bereich_wahl  = {de="Bereich auswaehlen",en="Select zone",fr="Selectionner une zone",it="Seleziona una zona",pt="Selecionar uma zona",es="Seleccionar una zona"},
    hint_station_wahl  = {de="Station auswaehlen",en="Select station",fr="Selectionner une station",it="Seleziona una stazione",pt="Selecionar uma estacao",es="Seleccionar una estacion"},
    dlg_bereich_umbenennen={de="Bereich umbenennen",en="Rename zone",fr="Renommer la zone",it="Rinomina zona",pt="Renomear zona",es="Renombrar zona"},
    dlg_bereich_loeschen={de="Bereich loeschen",en="Delete zone",fr="Supprimer la zone",it="Elimina zona",pt="Eliminar zona",es="Eliminar zona"},
    ctx_umbenennen     = {de="Umbenennen",en="Rename",fr="Renommer",it="Rinomina",pt="Renomear",es="Renombrar"},
    ctx_loeschen       = {de="Loeschen",en="Delete",fr="Supprimer",it="Elimina",pt="Eliminar",es="Eliminar"},
    -- Gruppe B: Einstellungsmenue (Ueberschriften/Buttons)
    set_spalten_anzeigen={de="Spalten anzeigen",en="Show columns",fr="Afficher les colonnes",it="Mostra colonne",pt="Mostrar colunas",es="Mostrar columnas"},
    set_einstellungen  = {de="Einstellungen",en="Settings",fr="Parametres",it="Impostazioni",pt="Definicoes",es="Ajustes"},
    set_fabrik_puffer  = {de="Fabrik-Puffer: ",en="Production buffer: ",fr="Tampon de production: ",it="Buffer di produzione: ",pt="Buffer de producao: ",es="Bufer de produccion: "},
    set_puffer_formel  = {de="Bestand - (Bedarf/h x Puffer) = Freie Menge",en="Stock - (demand/h x buffer) = free amount",fr="Stock - (besoin/h x tampon) = quantite libre",it="Scorte - (fabbisogno/h x buffer) = quantita libera",pt="Estoque - (procura/h x buffer) = quantidade livre",es="Existencias - (demanda/h x bufer) = cantidad libre"},
    set_lagertypen     = {de="Lagertypen (was wird gezaehlt)",en="Storage types (what is counted)",fr="Types de stockage (ce qui est compte)",it="Tipi di deposito (cosa viene conteggiato)",pt="Tipos de armazenamento (o que e contado)",es="Tipos de almacen (que se cuenta)"},
    set_bereiche_preset= {de="Bereiche-Preset",en="Zone preset",fr="Preset de zones",it="Preset zone",pt="Predefinicao de zonas",es="Preajuste de zonas"},
    set_selbst         = {de="Selbst einrichten (keine Aenderung)",en="Set up yourself (no change)",fr="Configurer soi-meme (aucun changement)",it="Configura da solo (nessuna modifica)",pt="Configurar por si (sem alteracoes)",es="Configurar tu mismo (sin cambios)"},
    set_zl_laden       = {de="Zentrallager-Preset laden",en="Load central warehouse preset",fr="Charger le preset entrepot central",it="Carica preset magazzino centrale",pt="Carregar predefinicao armazem central",es="Cargar preajuste almacen central"},
    set_giants_laden   = {de="Giants-Standard laden",en="Load Giants default",fr="Charger le standard Giants",it="Carica standard Giants",pt="Carregar padrao Giants",es="Cargar estandar Giants"},
    -- Gruppe B: Spalten-Labels (Einstellungsmenue)
    col_bestand        = {de="Bestand",en="Stock",fr="Stock",it="Scorte",pt="Estoque",es="Existencias"},
    col_frei           = {de="Frei",en="Free",fr="Libre",it="Libero",pt="Livre",es="Libre"},
    col_preis          = {de="Preis/1000l",en="Price/1000l",fr="Prix/1000l",it="Prezzo/1000l",pt="Preco/1000l",es="Precio/1000l"},
    col_maxpreis       = {de="Max/1000l",en="Max/1000l",fr="Max/1000l",it="Max/1000l",pt="Max/1000l",es="Max/1000l"},
    col_wert           = {de="Wert",en="Value",fr="Valeur",it="Valore",pt="Valor",es="Valor"},
    col_vkwert         = {de="Frei Wert",en="Free value",fr="Valeur libre",it="Valore libero",pt="Valor livre",es="Valor libre"},
    col_max            = {de="Max €",en="Max €",fr="Max €",it="Max €",pt="Max €",es="Max €"},
    col_vkmax          = {de="Frei Max",en="Free max",fr="Max libre",it="Max libero",pt="Max livre",es="Max libre"},
    col_monat          = {de="Bester Monat",en="Best month",fr="Meilleur mois",it="Miglior mese",pt="Melhor mes",es="Mejor mes"},
    -- Gruppe B: Lagertyp-Namen
    lt_zentrallager    = {de="Zentrallager",en="Central warehouse",fr="Entrepot central",it="Magazzino centrale",pt="Armazem central",es="Almacen central"},
    lt_silo            = {de="Silos & Tanks",en="Silos & tanks",fr="Silos & citernes",it="Sili & serbatoi",pt="Silos & tanques",es="Silos y tanques"},
    lt_silo_ext        = {de="Silo-Erweiterungen",en="Silo extensions",fr="Extensions de silo",it="Estensioni sili",pt="Extensoes de silo",es="Extensiones de silo"},
    lt_husbandry       = {de="Tierhaltung",en="Animal pens",fr="Elevages",it="Allevamenti",pt="Estabulos",es="Establos"},
    lt_manure          = {de="Misthaufen",en="Manure heaps",fr="Tas de fumier",it="Cumuli di letame",pt="Montes de estrume",es="Montones de estiercol"},
    lt_beehive         = {de="Bienenstock",en="Beehive",fr="Ruche",it="Alveare",pt="Colmeia",es="Colmena"},
    lt_bunker          = {de="Fahrsilos",en="Bunker silos",fr="Silos-couloirs",it="Trincee",pt="Silos-trincheira",es="Silos zanja"},
    lt_objektlager     = {de="Objektlager (Hallen)",en="Object storage (halls)",fr="Stockage d'objets (halls)",it="Deposito oggetti (capannoni)",pt="Armazem de objetos (galpoes)",es="Almacen de objetos (naves)"},
    lt_bale            = {de="Ballen (Feld/Hof)",en="Bales (field/yard)",fr="Balles (champ/cour)",it="Balle (campo/cortile)",pt="Fardos (campo/patio)",es="Balas (campo/patio)"},
    lt_pallet          = {de="Paletten (Fahrzeuge)",en="Pallets (vehicles)",fr="Palettes (vehicules)",it="Pallet (veicoli)",pt="Paletes (veiculos)",es="Palets (vehiculos)"},
    lt_production_out  = {de="Fabrik-Ausgangslager",en="Factory output storage",fr="Stockage sortie usine",it="Deposito uscita produzione",pt="Armazem de saida da fabrica",es="Almacen salida fabrica"},
    -- Nachtrag Gruppe A: Filter-Tabs
    tab_bereiche       = {de="Bereiche",en="Zones",fr="Zones",it="Zone",pt="Zonas",es="Zonas"},
    tab_stationen      = {de="Stationen",en="Stations",fr="Stations",it="Stazioni",pt="Estacoes",es="Estaciones"},
    -- Gruppe C: Bereichsnamen (Presets) - key bleibt Speicher-ID, nur Anzeige uebersetzt
    ber_schuettgut     = {de="Schuettgut",en="Bulk goods",fr="Vrac",it="Sfuso",pt="Granel",es="A granel"},
    ber_fluessig       = {de="Fluessig",en="Liquids",fr="Liquides",it="Liquidi",pt="Liquidos",es="Liquidos"},
    ber_tier           = {de="Tier",en="Animals",fr="Animaux",it="Animali",pt="Animais",es="Animales"},
    ber_stueckgut      = {de="Stueckgut",en="General cargo",fr="Marchandises",it="Merci varie",pt="Carga geral",es="Carga general"},
    ber_produkte       = {de="Produkte",en="Products",fr="Produits",it="Prodotti",pt="Produtos",es="Productos"},
    ber_holz           = {de="Holz",en="Wood",fr="Bois",it="Legno",pt="Madeira",es="Madera"},
    ber_kuehlung       = {de="Kuehlung",en="Refrigerated",fr="Refrigere",it="Refrigerati",pt="Refrigerados",es="Refrigerados"},
    ber_lebensmittel   = {de="Lebensmittel",en="Food",fr="Alimentaire",it="Alimentari",pt="Alimentos",es="Alimentos"},
    ber_obstgemuese    = {de="ObstGemuese",en="Fruit & veg",fr="Fruits & legumes",it="Frutta & verdura",pt="Fruta & legumes",es="Fruta & verduras"},
    ber_werkstoffe     = {de="Werkstoffe",en="Materials",fr="Materiaux",it="Materiali",pt="Materiais",es="Materiales"},
    ber_ballen         = {de="Ballen",en="Bales",fr="Balles",it="Balle",pt="Fardos",es="Balas"},
    ber_milchtier      = {de="MilchTier",en="Milk & animals",fr="Lait & animaux",it="Latte & animali",pt="Leite & animais",es="Leche & animales"},
    ber_futtermittel   = {de="Futtermittel",en="Feed",fr="Aliments betail",it="Mangimi",pt="Racao",es="Piensos"},
    ber_betriebsstoffe = {de="Betriebsstoffe",en="Supplies",fr="Consommables",it="Materiali esercizio",pt="Consumiveis",es="Consumibles"},
    ber_duenger        = {de="Duenger",en="Fertilizer",fr="Engrais",it="Fertilizzanti",pt="Fertilizantes",es="Fertilizantes"},
    ber_forstwirtschaft= {de="Forstwirtschaft",en="Forestry",fr="Sylviculture",it="Silvicoltura",pt="Silvicultura",es="Silvicultura"},
    ber_unverkaeuflich = {de="Unverkaeuflich",en="Not sellable",fr="Non vendable",it="Non vendibile",pt="Nao vendavel",es="No vendible"},
    -- Gruppe D: Rest
    hint_neue_waren    = {de=" neue Waren automatisch zugeordnet",en=" new goods auto-assigned",fr=" nouveaux produits attribues",it=" nuove merci assegnate",pt=" novos produtos atribuidos",es=" nuevos productos asignados"},
    hint_kein_lager    = {de="(kein Lager gefunden)",en="(no storage found)",fr="(aucun stockage trouve)",it="(nessun deposito trovato)",pt="(nenhum armazem encontrado)",es="(ningun almacen encontrado)"},
    dlg_neuer_bereich  = {de="Neuen Bereich anlegen",en="Create new zone",fr="Creer une nouvelle zone",it="Crea nuova zona",pt="Criar nova zona",es="Crear nueva zona"},
    dlg_loeschen_frage = {de="Bereich wirklich loeschen:",en="Really delete zone:",fr="Vraiment supprimer la zone:",it="Eliminare davvero la zona:",pt="Eliminar mesmo a zona:",es="Eliminar de verdad la zona:"},
    filter_zu_bereich  = {de="Zu Bereich hinzufuegen:",en="Add to zone:",fr="Ajouter a la zone:",it="Aggiungi alla zona:",pt="Adicionar a zona:",es="Anadir a la zona:"},
    filter_legende_gruen={de="Gruen = zugeordnet",en="Green = assigned",fr="Vert = assigne",it="Verde = assegnato",pt="Verde = atribuido",es="Verde = asignado"},
    filter_legende_grau= {de="Grau = nicht zugeordnet",en="Grey = not assigned",fr="Gris = non assigne",it="Grigio = non assegnato",pt="Cinza = nao atribuido",es="Gris = no asignado"},
    filter_legende_blau= {de="Blau = in Bereich einordnen (links anklicken)",en="Blue = assign to zone (click left)",fr="Bleu = assigner a zone (clic gauche)",it="Blu = assegna a zona (clic sinistro)",pt="Azul = atribuir a zona (clique esquerdo)",es="Azul = asignar a zona (clic izquierdo)"},
    filter_bereich_col = {de="Bereich",        en="Zone",         fr="Zone",         it="Zona",         pt="Zona",         es="Zona"},
    filter_station_col = {de="Station",        en="Station",      fr="Station",      it="Stazione",     pt="Estacao",      es="Estacion"},
    filter_bereich_ware= {de="Bereich / Ware", en="Zone / Goods", fr="Zone / Produit",it="Zona / Merce", pt="Zona / Produto",es="Zona / Producto"},
    tooltip_bereiche   = {de="Bereiche-Ansicht: FillTypes nach Kategorien gruppiert",en="Zone view: FillTypes grouped by category",fr="Vue zones: FillTypes groupes par categorie",it="Vista zone: FillTypes raggruppati per categoria",pt="Vista de zonas: FillTypes agrupados por categoria",es="Vista zonas: FillTypes agrupados por categoria"},
    tooltip_stationen  = {de="Stations-Ansicht: Filter pro Verkaufsstation",en="Station view: filter per selling station",fr="Vue stations: filtre par station de vente",it="Vista stazioni: filtro per stazione di vendita",pt="Vista estacoes: filtro por estacao de venda",es="Vista estaciones: filtro por estacion de venta"},
    tooltip_presets    = {de="Preset laden oder Einstellungen oeffnen",en="Load preset or open settings",fr="Charger un prereglage ou ouvrir les parametres",it="Carica preset o apri impostazioni",pt="Carregar predefinicao ou abrir definicoes",es="Cargar ajuste predef. o abrir configuracion"},
    tooltip_cwonly     = {de="ZL/CW only: nur Zentrallager-Bereiche anzeigen (ZL-Preset empfohlen)",en="ZL/CW only: show central warehouse zones only (ZL/CW preset recommended)",fr="ZL/CW only: afficher zones entrepot central uniquement (preset ZL/CW recommande)",it="ZL/CW only: mostra solo zone magazzino centrale (preset ZL/CW consigliato)",pt="ZL/CW only: mostrar apenas zonas do armazem central (predefinicao ZL/CW recomendada)",es="ZL/CW only: mostrar solo zonas almacen central (preset ZL/CW recomendado)"},
}

function DL_t(key)
    local lang = (g_languageShort or "en"):lower()
    local entry = DL_L10N[key]
    if not entry then return key end
    return entry[lang] or entry["en"] or key
end

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
function DispoList:getProductionDemandPerHour()
    local demand = {}
    if g_currentMission == nil then return demand end
    local myFarmId   = g_currentMission:getFarmId()
    local timeFactor = 1 / g_currentMission.environment.daysPerPeriod
    local chainMgr   = g_currentMission.productionChainManager
    if chainMgr == nil then return demand end

    local prodPoints = chainMgr:getProductionPointsForFarmId(myFarmId)
    if prodPoints ~= nil then
        for _, pp in pairs(prodPoints) do
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
    return demand
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

-- Absicherung: scanLagertypen mit pcall
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
    if DispoList._refreshRunning then return end
    DispoList._refreshRunning = true
    local ok, err = pcall(function() DispoList:_refreshDispoTableInner() end)
    DispoList._refreshRunning = false
    if not ok then
        print("## DispoList ERROR refreshDispoTable: " .. tostring(err))
        DispoList.CurrentItems = {}
    end
end
function DispoList:_refreshDispoTableInner()
    DispoList.refreshSinceMs = 0
    if g_currentMission == nil then return end
    local myFarmId        = g_currentMission:getFarmId()
    local priceMultiplier = EconomyManager.getPriceMultiplier()
    local stockLevels     = {}

    local act = DispoList.activeLagertypen or {}
    local zlStorages = {}  -- ZL-Storages nicht doppelt zählen
    local countedProdStorages = {}  -- Fabrik-Output nicht doppelt zählen
    local foundZentrallager = 0

    -- ── Zentrallager ─────────────────────────────────────────────────────────
    if act.ZENTRALLAGER then
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
                        for idx, lvl in pairs(pp.storage.fillLevels) do
                            if lvl > 0 then stockLevels[idx] = (stockLevels[idx] or 0) + lvl end
                        end
                        -- Fabrik-Output des ZL wird hier erfasst (verhindert Doppelzählung)
                        if pp.outputFillTypeIdsArray ~= nil then
                            countedProdStorages[pp.storage] = true
                        end
                    end
                end
            end
        end
    end

    -- ── Fabrik-Output (normale Fabriken, nicht ZL) ────────────────────────────
    if act.PRODUCTION_OUT and g_currentMission.productionChainManager ~= nil then
        for _, prod in ipairs(g_currentMission.productionChainManager.productionPoints) do
            if prod:getOwnerFarmId() == myFarmId then
                local st = prod.storage
                if st ~= nil and not zlStorages[st] and not countedProdStorages[st] then
                    countedProdStorages[st] = true
                    if prod.outputFillTypeIdsArray ~= nil then
                        for _, ftIdx in ipairs(prod.outputFillTypeIdsArray) do
                            local ok, lvl = pcall(function() return prod.storage:getFillLevel(ftIdx) end)
                            if ok and lvl ~= nil and lvl > 0 then
                                stockLevels[ftIdx] = (stockLevels[ftIdx] or 0) + math.floor(lvl)
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
    local function addRohware(idx, lvl)
        if idx ~= nil and lvl ~= nil and lvl > 0 then
            stockLevels[idx] = (stockLevels[idx] or 0) + lvl
        end
    end

    local countedRwStorages = {}

    for _, placeable in ipairs(g_currentMission.placeableSystem.placeables) do
        local mine = placeable.ownerFarmId == myFarmId or placeable.ownerFarmId == 0

        -- Silos (spec_silo)
        if act.SILO and placeable.spec_silo ~= nil and mine then
            for _, st in ipairs(placeable.spec_silo.storages or {}) do
                if not zlStorages[st] and not countedRwStorages[st] then
                    countedRwStorages[st] = true
                    if st.fillLevels ~= nil then
                        for idx, lvl in pairs(st.fillLevels) do addRohware(idx, lvl) end
                    end
                end
            end
        end

        -- SiloExtension
        if act.SILO_EXTENSION and placeable.spec_siloExtension ~= nil and mine then
            local st = placeable.spec_siloExtension.storage
            if st ~= nil and not zlStorages[st] and not countedRwStorages[st] then
                countedRwStorages[st] = true
                if st.fillLevels ~= nil then
                    for idx, lvl in pairs(st.fillLevels) do addRohware(idx, lvl) end
                end
            end
        end

        -- Tierhaltung
        if act.HUSBANDRY and placeable.spec_husbandry ~= nil and placeable.ownerFarmId == myFarmId then
            local st = placeable.spec_husbandry.storage
            if st ~= nil and not zlStorages[st] and not countedRwStorages[st] then
                countedRwStorages[st] = true
                local ls = placeable.spec_husbandry.loadingStation
                if st.fillLevels ~= nil then
                    for idx, lvl in pairs(st.fillLevels) do
                        if ls == nil or ls.supportedFillTypes == nil or ls.supportedFillTypes[idx] then
                            addRohware(idx, lvl)
                        end
                    end
                end
            end
        end

        -- Misthaufen
        if act.MANURE and placeable.spec_manureHeap ~= nil and mine then
            local heap = placeable.spec_manureHeap.manureHeap
            if heap ~= nil and not countedRwStorages[heap] then
                countedRwStorages[heap] = true
                if heap.fillLevels ~= nil then
                    for idx, lvl in pairs(heap.fillLevels) do addRohware(idx, lvl) end
                end
            end
        end

        -- Fahrsilo (BunkerSilo)
        if act.BUNKER and placeable.spec_bunkerSilo ~= nil and mine then
            local ok, err = pcall(function()
                local bs = placeable.spec_bunkerSilo.bunkerSilo
                if bs ~= nil then
                    local fillLevel = bs.fillLevel or 0
                    local ftIdx = bs.inputFillType
                    if bs.state == BunkerSilo.STATE_DRAIN or bs.state == BunkerSilo.STATE_FERMENTED then
                        ftIdx = bs.outputFillType
                    end
                    if fillLevel > 0 and ftIdx ~= nil and type(ftIdx) == "number" then
                        addRohware(ftIdx, fillLevel)
                    end
                end
            end)
            if not ok then print("## DL BUNKER ERROR: " .. tostring(err)) end
        end

        -- Objektlager (Ballen/Paletten in Lagerhallen — spec_objectStorage)
        if act.OBJEKTLAGER and placeable.spec_objectStorage ~= nil and mine then
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
                                    addRohware(ftIdx, lvl)
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
                                        addRohware(ftIdx, lvl)
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
        if act.BEEHIVE and placeable.spec_beehivePalletSpawner ~= nil and placeable.ownerFarmId == myFarmId then
            addRohware(placeable.spec_beehivePalletSpawner.fillType,
                       placeable.spec_beehivePalletSpawner.pendingLiters)
        end
    end

    -- Fahrzeuge: Paletten
    if act.PALLET and g_currentMission.vehicleSystem ~= nil then
        for _, v in ipairs(g_currentMission.vehicleSystem.vehicles) do
            if v.isPallet and (v.ownerFarmId == myFarmId or v.ownerFarmId == 0) then
                if v.spec_fillUnit ~= nil and v.spec_fillUnit.fillUnits ~= nil then
                    for _, fu in ipairs(v.spec_fillUnit.fillUnits) do
                        addRohware(fu.fillType, fu.fillLevel)
                    end
                end
            end
        end
    end

    -- Ballen auf der Karte
    if act.BALE and g_currentMission.itemSystem ~= nil and g_currentMission.itemSystem.items ~= nil then
        for _, item in pairs(g_currentMission.itemSystem.items) do
            local bale = (type(item) == "table" and item.item) and item.item or item
            if bale ~= nil and bale.isa ~= nil and bale:isa(Bale) then
                if bale.ownerFarmId == myFarmId or bale.ownerFarmId == 0 then
                    addRohware(bale.fillType, bale.fillLevel)
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
                    if ok == true and stockLevels[ft] ~= nil then
                        -- getEffectiveFillTypePrice() liefert bereits den fertigen, tatsächlich gezahlten
                        -- Preis inkl. Schwierigkeitsgrad-Faktor -> NICHT nochmal mit priceMultiplier multiplizieren
                        -- (siehe TSStockCheck als Referenz, Zeile 238: kein priceMultiplier hier)
                        local price = station:getEffectiveFillTypePrice(ft)
                        if bestStation[ft] == nil or price > bestStation[ft].price then
                            bestStation[ft] = {
                                stationName = station:getName(),
                                price       = price,
                                priceTrend  = station:getCurrentPricingTrend(ft),
                            }
                        end
                    end
                end

                -- Stations-eigenen priceScale je FillType aus der placeable-XML auslesen
                if station.owningPlaceable ~= nil and station.owningPlaceable.xmlFile ~= nil then
                    local xmlFile = station.owningPlaceable.xmlFile
                    xmlFile:iterate("placeable.sellingStation.fillType", function(_, fillTypeKey)
                        local ftName = xmlFile:getValue(fillTypeKey .. "#name")
                        local ftIdx  = ftName ~= nil and g_fillTypeManager:getFillTypeIndexByName(ftName) or nil
                        if ftIdx ~= nil and stockLevels[ftIdx] ~= nil then
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

    -- Finale Liste
    local entries = {}
    for idx, lvl in pairs(stockLevels) do
        if lvl > 0 and bestStation[idx] ~= nil then
            local ft = g_fillTypeManager:getFillTypeByIndex(idx)
            if ft ~= nil then
                local demandLph     = demandPerHour[idx] or 0
                local reserveAmount = demandLph * (DispoList.reserveStunden or 24)
                local sellable      = lvl - reserveAmount
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
                    demandPerHour = demandLph,
                    stationName   = bestStation[idx].stationName,
                    price         = bestStation[idx].price,
                    priceTrend    = bestStation[idx].priceTrend,
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

    -- ZL-Filter: nur ZL-Bereiche anzeigen wenn aktiv
    if DispoList._zlFilterActive then
        local zlSet = {}
        for _, name in ipairs(DispoList.ZL_BEREICHE_FILTER or {}) do
            zlSet[name] = true
        end
        local zlFiltered = {}
        for _, e in ipairs(entries) do
            local bName = e.bereich and e.bereich.name or ""
            if zlSet[bName] then
                table.insert(zlFiltered, e)
            end
        end
        entries = zlFiltered
        DispoList._zlFilterEmpty = (#zlFiltered == 0)
    else
        DispoList._zlFilterEmpty = false
    end

    -- Stationswert berechnen (sellable * price pro Station)
    DispoList.stationValues = {}
    for _, e in ipairs(entries) do
        local st = e.stationName or ""
        local val = math.max(0, e.sellable or 0) * (e.price or 0)
        DispoList.stationValues[st] = (DispoList.stationValues[st] or 0) + val
    end
    local stationValues = DispoList.stationValues

    -- Sortierung: A-Z oder Wert absteigend
    if DispoList.sortByValue then
        table.sort(entries, function(a, b)
            local va = stationValues[a.stationName or ""] or 0
            local vb = stationValues[b.stationName or ""] or 0
            if va ~= vb then return va > vb end  -- höchster Wert zuerst
            local oa = a.bereich and a.bereich.order or 99
            local ob = b.bereich and b.bereich.order or 99
            if oa ~= ob then return oa < ob end
            return string.lower(a.title or "") < string.lower(b.title or "")
        end)
    else
        table.sort(entries, function(a, b)
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

    DispoList.CurrentItems = entries

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
        if ok1 and v1 ~= nil then lvl = math.floor(v1) end
        local ok2, v2 = pcall(function() return st:getCapacity(ftIdx) end)
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
        DispoList:refreshDispoTable()
    else
        print("#WARNING: DispoList MISSING --> HL Hud System!")
        g_currentMission.hlUtils.modUnLoad("FS25_DispoList")
    end
end

-- ─── loadMap ─────────────────────────────────────────────────────────────────
function DispoList:loadMap(mapName)
    DispoList.extProdSpecKey = nil
    -- Sicherheits-Reset: playerFrozen und Input-Blocking immer deaktivieren
    if g_currentMission ~= nil and g_currentMission.hlUtils ~= nil then
        pcall(function()
            g_currentMission.hlUtils.playerFrozen = false
        end)
    end
    source(DispoList.modDir .. "scripte_dl/DL_FilterManager.lua")
    source(DispoList.modDir .. "scripte_dl/draw/DL_FilterMenu_Draw.lua")
    source(DispoList.modDir .. "scripte_dl/xml/DL_ColSettings_GuiBox.lua")
    if not DispoList:getDetiServer() then
        Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission, function()
            DL_Filter:init()
            DispoList.buildFillTypeToBereich()  -- Order aus XML übernehmen
            DispoList:scanLagertypen()
            DispoList:RegisterDisplaySystem()
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
        -- Pause aufheben beim Schließen
        if DispoList.filterPauseEnabled then
            if DispoList.previousTimeScale ~= nil then g_currentMission.timeScale = DispoList.previousTimeScale end
            if g_currentMission.missionInfo ~= nil and DispoList.previousMissionTimeScale ~= nil then g_currentMission.missionInfo.timeScale = DispoList.previousMissionTimeScale end
            if g_currentMission.paused ~= nil then g_currentMission.paused = false end
            DispoList.previousTimeScale = nil
            DispoList.previousMissionTimeScale = nil
        end
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
    getFreeGoods = function()
        local result = {}
        local table_ = DispoList.CurrentItems
        if table_ == nil then return result, getDispoReason() end
        local seen = {}
        for _, entry in ipairs(table_) do
            local key = entry.ftName or ""
            if not seen[key] and (entry.sellable or 0) > 0 then
                seen[key] = true
                table.insert(result, {
                    fillType = entry.ftName,
                    name     = entry.title,
                    amount   = entry.sellable,
                    price    = entry.price,
                    station  = entry.stationName,
                })
            end
        end
        return result, getDispoReason()
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
function DispoList.setInputBlocking(block)
    -- Input-Blocking deaktiviert (zu riskant in FS25)
    -- Bekanntes Problem: WASD reagiert während Texteingabe
end

-- ─── keyEvent: Texteingabe für Suche ────────────────────────────────────────
-- Mausposition cachen (wird vor HL-System-Listener aufgerufen)
function DispoList:mouseEvent(posX, posY, isDown, isUp, button)
    DispoList._mouseX = posX
    DispoList._mouseY = posY
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
    -- Input-Blocking: Spielaktionen sperren wenn Suchfeld aktiv
    if DispoList.filterSearchActive and g_inputBinding ~= nil then
        if unicode > 31 and unicode < 256 then
            -- blockieren durch vorzeitiges Verarbeiten
        elseif sym ~= Input.KEY_backspace and sym ~= Input.KEY_return and sym ~= Input.KEY_kp_enter then
            if isDown then return end
        end
    end
    -- FilterBox Suche hat Vorrang
    if DispoList.filterSearchActive then
        if not isDown then return end
        if sym == Input.KEY_backspace then
            if utf8Strlen(DispoList.filterSearchText) > 0 then
                local len = utf8Strlen(DispoList.filterSearchText)
                DispoList.filterSearchText = utf8Substr(DispoList.filterSearchText, 0, len - 1)
                if utf8Strlen(DispoList.filterSearchText) == 0 then
                    DispoList.filterSearchActive = false
                end
            end
        elseif sym == Input.KEY_return or sym == Input.KEY_kp_enter then
            -- nichts, läuft inkrementell
        elseif unicode > 31 and unicode < 128 then
            local ok, char = pcall(string.char, unicode)
            if ok and char ~= nil and char ~= "" then
                DispoList.filterSearchText = DispoList.filterSearchText .. char
            end
        end
        return
    end
    if not DispoList.searchActive then return end
    if not isDown then return end
    -- Escape wird von FS25 abgefangen - nicht verwenden
    -- Backspace: letztes Zeichen löschen, bei leerem Text Suche schliessen
    if sym == Input.KEY_backspace then
        if utf8Strlen(DispoList.searchText) > 0 then
            local len = utf8Strlen(DispoList.searchText)
            DispoList.searchText = utf8Substr(DispoList.searchText, 0, len - 1)
            DispoList.searchDirty = true
            -- Leer -> Suche schliessen
            if utf8Strlen(DispoList.searchText) == 0 then
                DispoList.searchActive = false
            end
        end
        return
    end
    -- Enter: Suche bestätigen (nichts tun, läuft schon inkrementell)
    if sym == Input.KEY_return or sym == Input.KEY_kp_enter then return end
    -- Zeichen anhängen wenn druckbar (unicode > 31 und < 127 für ASCII)
    if unicode > 31 and unicode < 256 then
        local char = string.char(unicode)
        if char ~= nil and char ~= "" then
            DispoList.searchText  = DispoList.searchText .. char
            DispoList.searchDirty = true
        end
    end
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
                            DispoList.setInputBlocking(false)  -- Sicherheits-Reset
                            DispoList.dlSelectedFt = nil;
                            DispoList.dlSelectedFtTitle = nil;
                            DispoList.dlSelectedFtBereich = nil;
                            DispoList.filterSearchActive = false;
                            DispoList.filterSearchText = "";
                            DispoList.filterResetConfirm = false;
                        end
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
