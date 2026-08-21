-- =====================================================================
--  DispoList / DL_SellpointUnlock.lua        (Etappe 1: Motor + Persistenz)
-- ---------------------------------------------------------------------
--  Laesst eine Verkaufsstation zusaetzliche Waren annehmen, die sie laut
--  Karte NICHT fuehrt - OHNE Kartendateien zu aendern. Deals sind pro
--  Savegame persistent, mit optionalem Preis-Faktor (Abzug oder Aufschlag).
--
--  1:1 uebernommene, ingame bewiesene Kern-Mechanik aus dem eigenstaendigen
--  Mod FS25_CustomizeSellpoints v0.4.0 (jetzt in DispoList gefaltet). Details
--  siehe Projekt-Doku claude/FS25_CustomizeSellpoints.md.
--
--  Verifizierte Kern-Mechanik:
--   1. Anwendung beim ERSTEN Update-Tick - erst dann ist das Placeable
--      verknuepft und station:getName() liefert den echten Namen (bei
--      load/loadMapFinished noch nicht -> 0 Treffer).
--   2. Pro Treffer VERKAUFSSEITE: station:addAcceptedFillType(...) (Giants
--      baut die 15 Preis-Tabellen) + supportedFillTypes, danach einmal
--      station:initPricingDynamics() pro betroffener Station.
--   3. Pro Treffer TRIGGER-SEITE: unloadTrigger.fillTypes[idx]=true (sonst
--      "Ware wird hier nicht angenommen" beim physischen Abladen).
--   4. Persistenz NUR ueber die Save-Hooks (FS25 benennt tempsavegame ->
--      savegameN um; direkt geschriebene Dateien wuerden weggewischt).
--      MP-Client speichert nie.
--
--  Etappe 1 = Motor + Persistenz + Debug-Konsole (dlsp*). GUI (Station-Modus)
--  und MP-Event kommen in Etappe 2 bzw. 3.
--
--  Nur Giants-Lua fuer LS25.
-- =====================================================================

DL_SellpointUnlock = DL_SellpointUnlock or {}
local SU = DL_SellpointUnlock

SU.DEBUG             = false     -- true = ausfuehrliche Diagnose ins log.txt
SU.deals             = SU.deals or {}   -- { {station=, fillType=, priceScale=}, ... }
SU.dealsLoaded       = false
SU.commandsRegistered = false
SU.applied           = false
SU.updateTicks       = 0
SU.hooksInstalled    = SU.hooksInstalled or false

local function toLog(fmt, ...)
	print("[DispoList/Sellpoint] " .. string.format(fmt, ...))
end
local function dbg(fmt, ...)
	if SU.DEBUG then
		print("[DispoList/Sellpoint-DEBUG] " .. string.format(fmt, ...))
	end
end

-- ---------------------------------------------------------------------
--  Hilfen: Stationen finden (per station:getName(), Teilstring)
-- ---------------------------------------------------------------------
function SU.forEachSellingStation(callback)
	if g_currentMission == nil or g_currentMission.storageSystem == nil then
		return
	end
	for _, station in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
		if station.isa ~= nil and station:isa(SellingStation) then
			callback(station)
		end
	end
end

function SU.matchingLoadedStations(needle)
	local out = {}
	if needle == nil then
		return out
	end
	needle = string.lower(needle)
	SU.forEachSellingStation(function(station)
		local name = tostring(station:getName())
		if string.find(string.lower(name), needle, 1, true) ~= nil then
			table.insert(out, name)
		end
	end)
	return out
end

function SU.findStation(needle)
	local found = nil
	if needle == nil then
		return nil
	end
	needle = string.lower(needle)
	SU.forEachSellingStation(function(station)
		if found == nil and string.find(string.lower(tostring(station:getName())), needle, 1, true) ~= nil then
			found = station
		end
	end)
	return found
end

-- ---------------------------------------------------------------------
--  Persistenz (Savegame-XML, nur ueber die Save-Hooks geschrieben)
-- ---------------------------------------------------------------------
function SU.getSavePath()
	local mission = g_currentMission
	if mission == nil or mission.missionInfo == nil or mission.missionInfo.savegameDirectory == nil then
		return nil
	end
	return mission.missionInfo.savegameDirectory .. "/dispoList_sellpoints.xml"
end

function SU.loadDeals()
	SU.deals = {}
	local path = SU.getSavePath()
	dbg("loadDeals: path=%s exists=%s", tostring(path), tostring(path ~= nil and fileExists(path) or false))
	if path == nil then
		return  -- savegameDirectory noch nicht bereit -> NICHT als geladen markieren
	end
	SU.dealsLoaded = true
	if not fileExists(path) then
		return
	end
	local xml = loadXMLFile("dlSellpointDeals", path)
	if xml == nil or xml == 0 then
		return
	end
	local i = 0
	while true do
		local key = string.format("dispoListSellpoints.deal(%d)", i)
		if not hasXMLProperty(xml, key) then
			break
		end
		local station = getXMLString(xml, key .. "#station")
		local fillType = getXMLString(xml, key .. "#fillType")
		local priceScale = getXMLFloat(xml, key .. "#priceScale") or 1
		if station ~= nil and fillType ~= nil then
			table.insert(SU.deals, { station = station, fillType = string.upper(fillType), priceScale = priceScale })
		end
		i = i + 1
	end
	delete(xml)
	toLog("%d Deal(s) aus Savegame geladen.", #SU.deals)
end

function SU.saveDeals()
	local path = SU.getSavePath()
	if path == nil then
		dbg("saveDeals: kein savegameDirectory")
		return false
	end
	local xml = createXMLFile("dlSellpointDeals", path, "dispoListSellpoints")
	if xml == nil or xml == 0 then
		toLog("saveDeals: createXMLFile fehlgeschlagen (%s)", path)
		return false
	end
	for i, d in ipairs(SU.deals) do
		local key = string.format("dispoListSellpoints.deal(%d)", i - 1)
		setXMLString(xml, key .. "#station", d.station)
		setXMLString(xml, key .. "#fillType", d.fillType)
		setXMLFloat(xml, key .. "#priceScale", d.priceScale)
	end
	saveXMLFile(xml)
	delete(xml)
	dbg("saveDeals: %d Deal(s) -> %s", #SU.deals, path)
	return true
end

function SU.onSaveSavegame()
	if g_server == nil then
		return  -- MP-Client speichert nie
	end
	SU.saveDeals()
end

-- ---------------------------------------------------------------------
--  Native-Snapshot je Station (VOR dem ersten Deal): Preis-Akzeptanz +
--  Trigger-Zustand. Basis fuer korrektes "ab Werk" UND sicheres Entfernen
--  (native Annahme wird beim Deal-Entfernen exakt wiederhergestellt, nie
--  zerschossen). Keyed am Station-Objekt (Session-stabil).
-- ---------------------------------------------------------------------
SU.nativeSnap = SU.nativeSnap or {}
function SU.snapshotNative(station)
	if station == nil or SU.nativeSnap[station] ~= nil then return end
	local acc = {}
	if station.acceptedFillTypes ~= nil then
		for k, v in pairs(station.acceptedFillTypes) do if v == true then acc[k] = true end end
	end
	local trig = {}
	if station.unloadTriggers ~= nil then
		for ti, tr in ipairs(station.unloadTriggers) do
			local s = {}
			if tr.fillTypes ~= nil then
				for k, v in pairs(tr.fillTypes) do if v == true then s[k] = true end end
			end
			trig[ti] = s
		end
	end
	SU.nativeSnap[station] = { acc = acc, trig = trig }
end

-- ---------------------------------------------------------------------
--  Deal auf eine Station anwenden (Verkaufsseite + Trigger-Seite)
-- ---------------------------------------------------------------------
function SU.applyDealToStation(station, deal)
	local idx = g_fillTypeManager:getFillTypeIndexByName(deal.fillType)
	if idx == nil then
		return false
	end
	local fillType = g_fillTypeManager:getFillTypeByIndex(idx)
	if fillType == nil then
		return false
	end
	SU.snapshotNative(station)   -- native Basis EINMALIG festhalten, VOR dem Schreiben
	local scale = deal.priceScale or 1
	local price = fillType.pricePerLiter * scale
	if price <= 0 then
		return false
	end

	-- Verkaufsseite
	if station.supportedFillTypes ~= nil then
		station.supportedFillTypes[idx] = true
	end
	if station.acceptedFillTypes ~= nil and station.acceptedFillTypes[idx] then
		if scale ~= 1 then
			station.originalFillTypePricesUnscaled[idx] = price
			station.originalFillTypePrices[idx] = price
			station.fillTypePrices[idx] = price
		end
	elseif station.addAcceptedFillType ~= nil then
		station:addAcceptedFillType(idx, price, false, false)
	end

	-- Trigger-Seite (physisches Abladen)
	local trg = 0
	if station.unloadTriggers ~= nil then
		for _, trigger in ipairs(station.unloadTriggers) do
			if trigger.fillTypes ~= nil then
				trigger.fillTypes[idx] = true
				trg = trg + 1
			end
		end
	end

	local ok = station.acceptedFillTypes ~= nil and station.acceptedFillTypes[idx] ~= nil
	toLog("Deal aktiv: '%s' <- %s (scale %.2f, %d Trigger)", tostring(station:getName()), deal.fillType, scale, trg)
	return ok
end

function SU.applyAllDeals()
	if not SU.dealsLoaded then
		SU.loadDeals()
	end
	if #SU.deals == 0 then
		return
	end
	if g_currentMission == nil or g_currentMission.storageSystem == nil then
		return
	end

	local applied, seen = 0, 0
	local names = {}
	SU.forEachSellingStation(function(station)
		seen = seen + 1
		local realName = tostring(station:getName())
		if SU.DEBUG then
			names[#names + 1] = realName
		end
		local name = string.lower(realName)
		local touched = false
		for _, deal in ipairs(SU.deals) do
			if string.find(name, string.lower(deal.station), 1, true) ~= nil then
				if SU.applyDealToStation(station, deal) then
					applied = applied + 1
					touched = true
				end
			end
		end
		if touched and station.initPricingDynamics ~= nil then
			station:initPricingDynamics()
		end
	end)

	toLog("applyAllDeals: %d angewandt (%d Stationen geprueft).", applied, seen)
	if SU.DEBUG and applied == 0 then
		dbg("KEIN Treffer - Stationsnamen:")
		for _, n in ipairs(names) do
			dbg("   '%s'", n)
		end
	end
end

-- Oeffentlicher Re-Apply (fuer spaetere GUI/Etappe 2: nach Aenderung sofort wirken)
function SU.reapply()
	SU.applied = true
	SU.applyAllDeals()
end

-- ---------------------------------------------------------------------
--  GUI-Bruecke (Etappe 2): Bedienung aus dem Station-Modus des Filter-HUDs
-- ---------------------------------------------------------------------
-- Station-Objekt per exaktem Namen (GUI liefert den vollen getName()).
function SU.findStationByExactName(name)
	local found = nil
	SU.forEachSellingStation(function(station)
		if found == nil and tostring(station:getName()) == name then found = station end
	end)
	return found
end

function SU.getDeal(stationName, ftUpper)
	for _, d in ipairs(SU.deals) do
		if d.station == stationName and d.fillType == ftUpper then return d end
	end
	return nil
end

-- GUI-Klick: Ware an Station umschalten. Freischalten wirkt SOFORT (addAcceptedFillType
-- + Trigger), Entfernen nimmt die Ware aus der Liste + schliesst die Trigger sofort;
-- der Preis-Eintrag verschwindet vollstaendig erst beim naechsten Laden (bewusst, um
-- nicht an Giants' internen Preistabellen herumzuoperieren).
function SU.guiToggle(stationName, ftName)
	if not SU.dealsLoaded then SU.loadDeals() end
	local ftUpper = string.upper(ftName)
	local existing = SU.getDeal(stationName, ftUpper)
	if existing ~= nil then
		local kept = {}
		for _, d in ipairs(SU.deals) do
			if not (d.station == stationName and d.fillType == ftUpper) then table.insert(kept, d) end
		end
		SU.deals = kept
		local station = SU.findStationByExactName(stationName)
		local idx = g_fillTypeManager:getFillTypeIndexByName(ftUpper)
		if station ~= nil and idx ~= nil and station.unloadTriggers ~= nil then
			-- Auf nativen Ur-Zustand zuruecksetzen: war die Ware nativ in einem
			-- Trigger, bleibt sie dort; nur die zusaetzlich freigeschalteten
			-- Trigger (z.B. Palette) fallen weg. Ohne Snapshot (reiner Zusatz-
			-- Deal) -> aus allen Triggern raus (wie bisher).
			local snap = SU.nativeSnap ~= nil and SU.nativeSnap[station] or nil
			for ti, trigger in ipairs(station.unloadTriggers) do
				if trigger.fillTypes ~= nil then
					local nativeHad = snap ~= nil and snap.trig ~= nil
						and snap.trig[ti] ~= nil and snap.trig[ti][idx] == true
					trigger.fillTypes[idx] = nativeHad and true or nil
				end
			end
		end
		toLog("GUI: Deal entfernt '%s' <- %s", stationName, ftUpper)
	else
		local deal = { station = stationName, fillType = ftUpper, priceScale = 1.0 }
		table.insert(SU.deals, deal)
		local station = SU.findStationByExactName(stationName)
		if station ~= nil then
			SU.applyDealToStation(station, deal)
			if station.initPricingDynamics ~= nil then station:initPricingDynamics() end
		end
		toLog("GUI: Deal freigeschaltet '%s' <- %s", stationName, ftUpper)
	end
	SU.syncAfterEdit()
end

-- GUI-Klick: Preis-Faktor eines Deals um 0.05 aendern (0.50 .. 1.50), sofort wirksam.
function SU.guiScale(stationName, ftName, dir)
	if not SU.dealsLoaded then SU.loadDeals() end
	local deal = SU.getDeal(stationName, string.upper(ftName))
	if deal == nil then return end
	local v = (deal.priceScale or 1) + (dir or 0) * 0.05
	v = math.max(0.50, math.min(1.50, math.floor(v * 100 + 0.5) / 100))
	deal.priceScale = v
	local station = SU.findStationByExactName(stationName)
	if station ~= nil then
		SU.applyDealToStation(station, deal)
		if station.initPricingDynamics ~= nil then station:initPricingDynamics() end
	end
	SU.syncAfterEdit()
end

-- ---------------------------------------------------------------------
--  Konsolenbefehle (Etappe-1 Debug-Weg; Bedienung kommt in Etappe 2 per GUI)
-- ---------------------------------------------------------------------
function SU:dlspAdd(stationName, fillTypeName, priceScaleStr)
	if stationName == nil or fillTypeName == nil then
		return "Verwendung: dlspAdd <Stationsname-Teil> <FillType> [priceScale]"
	end
	if not SU.dealsLoaded then
		SU.loadDeals()
	end

	local ft = string.upper(fillTypeName)
	local idx = g_fillTypeManager:getFillTypeIndexByName(ft)
	if idx == nil then
		return string.format("Unbekannter FillType '%s' (exakter Giants-Name, z.B. POTATO, WHEAT, SUGARBEET).", ft)
	end

	local priceScale = 1
	if priceScaleStr ~= nil then
		priceScale = tonumber(priceScaleStr)
		if priceScale == nil or priceScale <= 0 then
			return "priceScale muss > 0 sein (0.8 = 20% Abzug, 1.2 = 20% Aufschlag, 1 = normal)."
		end
	end

	local updated = false
	for _, d in ipairs(SU.deals) do
		if string.lower(d.station) == string.lower(stationName) and d.fillType == ft then
			d.priceScale = priceScale
			updated = true
			break
		end
	end
	if not updated then
		table.insert(SU.deals, { station = stationName, fillType = ft, priceScale = priceScale })
	end

	local lines = {
		string.format("%s: '%s' nimmt kuenftig '%s' an (priceScale %.2f).",
			updated and "Deal aktualisiert" or "Neuer Deal", stationName, ft, priceScale),
		"  -> Jetzt SPIEL SPEICHERN, dann wirkt der Deal ab dem naechsten Laden.",
	}
	local matches = SU.matchingLoadedStations(stationName)
	if #matches == 0 then
		table.insert(lines, "  ACHTUNG: aktuell passt KEINE geladene Station zum Namensteil - Tippfehler? (dlspStations)")
	else
		table.insert(lines, string.format("  Passt aktuell zu %d Station(en): %s", #matches, table.concat(matches, ", ")))
	end
	return table.concat(lines, "\n")
end

function SU:dlspList()
	if not SU.dealsLoaded then
		SU.loadDeals()
	end
	if #SU.deals == 0 then
		return "Keine Deals gespeichert."
	end
	local lines = { string.format("%d Deal(s):", #SU.deals) }
	for i, d in ipairs(SU.deals) do
		table.insert(lines, string.format("  %d) Station~'%s'   Ware=%s   priceScale=%.2f", i, d.station, d.fillType, d.priceScale))
	end
	return table.concat(lines, "\n")
end

function SU:dlspClear(stationName)
	if not SU.dealsLoaded then
		SU.loadDeals()
	end
	if stationName == nil then
		local n = #SU.deals
		SU.deals = {}
		return string.format("Alle %d Deal(s) geloescht (im Speicher). Spiel speichern -> wirkt ab naechstem Laden.", n)
	end
	local kept, removed = {}, 0
	for _, d in ipairs(SU.deals) do
		if string.lower(d.station) == string.lower(stationName) then
			removed = removed + 1
		else
			table.insert(kept, d)
		end
	end
	SU.deals = kept
	return string.format("%d Deal(s) fuer '%s' geloescht (im Speicher). Spiel speichern -> wirkt ab naechstem Laden.", removed, stationName)
end

function SU:dlspStations()
	if g_currentMission == nil or g_currentMission.storageSystem == nil then
		return "storageSystem nicht verfuegbar."
	end
	local lines = { "--- Verkaufsstationen ---" }
	local i = 0
	SU.forEachSellingStation(function(station)
		i = i + 1
		table.insert(lines, string.format("%d) %s", i, tostring(station:getName())))
	end)
	table.insert(lines, string.format("--- %d Station(en) ---", i))
	return table.concat(lines, "\n")
end

function SU:dlspInfo(namePart)
	if namePart == nil then
		return "Nutzung: dlspInfo <Teil des Stationsnamens>"
	end
	local station = SU.findStation(namePart)
	if station == nil then
		return "Keine Station gefunden, die '" .. tostring(namePart) .. "' enthaelt."
	end
	if station.acceptedFillTypes == nil then
		return "Station: " .. tostring(station:getName()) .. " (acceptedFillTypes ist nil)"
	end
	local lines = { "Station: " .. tostring(station:getName()) }
	for ft, isOk in pairs(station.acceptedFillTypes) do
		if isOk == true then
			local ftDef = g_fillTypeManager:getFillTypeByIndex(ft)
			local ftName = ftDef ~= nil and ftDef.name or tostring(ft)
			local price = 0
			local okP, p = pcall(function() return station:getEffectiveFillTypePrice(ft) end)
			if okP then price = p end
			table.insert(lines, string.format("  %s  Preis: %.4f", ftName, price))
		end
	end
	return table.concat(lines, "\n")
end

function SU:dlspDebug()
	local mi = g_currentMission ~= nil and g_currentMission.missionInfo or nil
	local sgDir = mi ~= nil and mi.savegameDirectory or nil
	local path = SU.getSavePath()
	local exists = path ~= nil and fileExists(path) or false
	local lines = {
		"--- DispoList Sellpoint-Unlock Diagnose ---",
		string.format("savegameDirectory = %s", tostring(sgDir)),
		string.format("deals-Pfad        = %s", tostring(path)),
		string.format("Datei existiert   = %s", tostring(exists)),
		string.format("dealsLoaded       = %s", tostring(SU.dealsLoaded)),
		string.format("applied           = %s", tostring(SU.applied)),
		string.format("Deals im Speicher = %d", #SU.deals),
	}
	for i, d in ipairs(SU.deals) do
		table.insert(lines, string.format("   %d) %s / %s / %.2f", i, d.station, d.fillType, d.priceScale))
	end
	return table.concat(lines, "\n")
end

-- Diagnose: pro Ware akzeptiert(Preis)? / supported? / in wie vielen Triggern?
-- Deckt den Fall auf "zeigt kaufbar (acceptedFillTypes), laedt aber nicht ab
-- (kein unloadTrigger)". Reiner Lese-Dump, aendert nichts.
function SU:dlspDiag(namePart, ftName)
	if namePart == nil then
		return "Nutzung: dlspDiag <Station-Teil> [FillType]  -- akzeptiert/supported/#Trigger je Ware"
	end
	local station = SU.findStation(namePart)
	if station == nil then
		return "Keine Station gefunden, die '" .. tostring(namePart) .. "' enthaelt."
	end
	local acc      = station.acceptedFillTypes or {}
	local sup      = station.supportedFillTypes or {}
	local triggers = station.unloadTriggers or {}
	local function trgCount(idx)
		local c = 0
		for _, t in ipairs(triggers) do
			if t.fillTypes ~= nil and t.fillTypes[idx] == true then c = c + 1 end
		end
		return c
	end
	local nAcc, nSup = 0, 0
	for _, v in pairs(acc) do if v == true then nAcc = nAcc + 1 end end
	for _, v in pairs(sup) do if v == true then nSup = nSup + 1 end end
	local lines = {
		string.format("=== Diagnose '%s' ===", tostring(station:getName())),
		string.format("acceptedFillTypes=%d  supportedFillTypes=%d  unloadTriggers=%d", nAcc, nSup, #triggers),
		"A=akzeptiert(Preis)  S=supported  T=#Trigger mit der Ware",
	}
	-- Einzelne Ware abfragen (z.B. dlspDiag Messe SILAGE_ADDITIVE)
	if ftName ~= nil then
		local idx = g_fillTypeManager:getFillTypeIndexByName(string.upper(ftName))
		if idx == nil then
			table.insert(lines, "FillType '" .. tostring(ftName) .. "' unbekannt.")
		else
			table.insert(lines, string.format("  %s : A=%s  S=%s  T=%d",
				string.upper(ftName), tostring(acc[idx] == true), tostring(sup[idx] == true), trgCount(idx)))
		end
		return table.concat(lines, "\n")
	end
	-- Alle akzeptierten Waren; Mismatch (akzeptiert aber 0 Trigger) zuoberst
	local rows = {}
	for idx, isOk in pairs(acc) do
		if isOk == true then
			local def = g_fillTypeManager:getFillTypeByIndex(idx)
			local nm  = (def ~= nil and def.name) or tostring(idx)
			local tc  = trgCount(idx)
			rows[#rows + 1] = { nm = nm, s = (sup[idx] == true), t = tc, bad = (tc == 0) }
		end
	end
	table.sort(rows, function(a, b)
		if a.bad ~= b.bad then return a.bad end
		return a.nm < b.nm
	end)
	local nBad = 0
	for _, r in ipairs(rows) do
		if r.bad then nBad = nBad + 1 end
		table.insert(lines, string.format("  %-22s A=1 S=%s T=%d%s",
			r.nm, r.s and "1" or "0", r.t, r.bad and "   <-- KEIN TRIGGER (zeigt kaufbar, laedt NICHT ab)" or ""))
	end
	table.insert(lines, string.format("--- %d akzeptiert, davon %d OHNE Trigger ---", #rows, nBad))
	return table.concat(lines, "\n")
end

-- Diagnose der freien Kapazitaet je akzeptierter Ware (fuer die Spielplatz-/
-- Baustellen-Falschdaten). Zeigt: Preis, getFreeCapacity (0 = Lager voll ->
-- kann NICHT mehr abgeladen werden), ob die Station ein natives Constructible
-- ist, und die bereits gelieferte Menge. Rein lesend.
function SU:dlspFreeCap(namePart)
	if namePart == nil then
		return "Nutzung: dlspFreeCap <Station-Teil>  -- freie Kapazitaet je Ware (0 = voll)"
	end
	local station = SU.findStation(namePart)
	if station == nil then
		return "Keine Station gefunden, die '" .. tostring(namePart) .. "' enthaelt."
	end
	local myFarmId = (g_currentMission ~= nil and g_currentMission.getFarmId ~= nil)
		and g_currentMission:getFarmId() or 1
	local placeable = station.owningPlaceable
	local isConstr  = placeable ~= nil and placeable.spec_constructible ~= nil
	local stateInfo = ""
	if isConstr then
		local ok, fin, tot = pcall(function()
			return placeable:getNumFinishedConstructibleStates()
		end)
		if ok then stateInfo = string.format("  Bauzustand=%s/%s", tostring(fin), tostring(tot)) end
	end
	local lines = {
		string.format("=== FreeCap '%s' ===", tostring(station:getName())),
		string.format("Constructible=%s%s  farmId=%d", tostring(isConstr), stateInfo, myFarmId),
		"Ware : Preis | freieKap (0=voll, huge=Markt) | geliefert(Constructible)",
	}
	local rows = {}
	for idx, isOk in pairs(station.acceptedFillTypes or {}) do
		if isOk == true then
			local def = g_fillTypeManager:getFillTypeByIndex(idx)
			local nm  = (def ~= nil and def.name) or tostring(idx)
			local price = 0
			local okP, p = pcall(function() return station:getEffectiveFillTypePrice(idx) end)
			if okP and p ~= nil then price = p end
			local free = -1
			local okF, f = pcall(function() return station:getFreeCapacity(idx, myFarmId) end)
			if okF and f ~= nil then free = f end
			local deliv = nil
			if isConstr then
				local okD, d = pcall(function() return placeable:getConstructibleFillLevel(idx) end)
				if okD then deliv = d end
			end
			rows[#rows + 1] = { nm = nm, price = price, free = free, deliv = deliv }
		end
	end
	table.sort(rows, function(a, b) return a.free < b.free end)
	for _, r in ipairs(rows) do
		local freeStr = (r.free == math.huge) and "huge" or string.format("%.0f", r.free)
		local delivStr = (r.deliv ~= nil) and string.format(" | geliefert=%.0f", r.deliv) or ""
		local flag = (r.free == 0) and "   <-- VOLL (kann nicht mehr rein)" or ""
		table.insert(lines, string.format("  %-20s Preis=%.0f | freieKap=%s%s%s",
			r.nm, r.price, freeStr, delivStr, flag))
	end
	table.insert(lines, string.format("--- %d akzeptierte Waren ---", #rows))
	return table.concat(lines, "\n")
end

-- Diagnose der Produktionsstellen (Fenster/Hofmarkt/Eisdiele ...): pro Punkt die
-- Eingangswaren (+ freie Kapazitaet) und die Produktions-OUTPUTS mit Modus
-- (directSell = Geld direkt / PALETTE = spawnt Palette, z.B. Bargeld-Kassette /
-- autoDeliver / keep). So sehen wir, welche Punkte wirklich Geld/Kassetten
-- ausgeben und wie man sie erkennt. Rein lesend.
function SU:dlspProd(namePart)
	local mission = g_currentMission
	if mission == nil then return "Keine Mission." end
	local farmId = (mission.getFarmId ~= nil) and mission:getFarmId() or 1

	-- Produktionsstellen sammeln (primaer productionChainManager, Fallback ueber
	-- die Verkaufsstationen -> owningPlaceable.spec_productionPoint).
	local seen, pps = {}, {}
	local pcm = mission.productionChainManager
	if pcm ~= nil and pcm.productionPoints ~= nil then
		for _, pp in ipairs(pcm.productionPoints) do
			if pp ~= nil and not seen[pp] then seen[pp] = true; pps[#pps + 1] = pp end
		end
	end
	if mission.storageSystem ~= nil then
		for _, st in pairs(mission.storageSystem:getUnloadingStations()) do
			local pl   = st.owningPlaceable
			local spec = pl ~= nil and pl.spec_productionPoint or nil
			local pp   = spec ~= nil and spec.productionPoint or nil
			if pp ~= nil and not seen[pp] then seen[pp] = true; pps[#pps + 1] = pp end
		end
	end

	local function ftName(idx)
		local ft = g_fillTypeManager:getFillTypeByIndex(idx)
		return (ft ~= nil and ft.name) or tostring(idx)
	end
	local function outMode(pp, idx)
		if pp.outputFillTypeIdsDirectSell   and pp.outputFillTypeIdsDirectSell[idx]   then return "directSell(Geld)" end
		if pp.outputFillTypeIdsToPallets    and pp.outputFillTypeIdsToPallets[idx]    then return "PALETTE" end
		if pp.outputFillTypeIdsAutoDeliver  and pp.outputFillTypeIdsAutoDeliver[idx]  then return "autoDeliver" end
		return "keep(Lager)"
	end

	local lines = { string.format("=== Produktionsstellen (%d) ===", #pps) }
	for _, pp in ipairs(pps) do
		local nm    = (pp.getName ~= nil) and tostring(pp:getName()) or "?"
		if namePart == nil or string.find(string.lower(nm), string.lower(namePart), 1, true) ~= nil then
			local owner = pp.ownerFarmId or 0
			table.insert(lines, string.format("PP '%s'  F%s", nm, tostring(owner)))
			-- Eingangswaren (aus den Produktions-Inputs, dedupliziert) + freie Kap
			local inSeen = {}
			for _, prod in ipairs(pp.productions or {}) do
				for _, inp in ipairs(prod.inputs or {}) do
					local idx = inp.type
					if idx ~= nil and not inSeen[idx] then
						inSeen[idx] = true
						local free = "?"
						if pp.unloadingStation ~= nil then
							local okF, f = pcall(pp.unloadingStation.getFreeCapacity, pp.unloadingStation, idx, farmId)
							if okF and f ~= nil then free = (f == math.huge) and "huge" or string.format("%.0f", f) end
						end
						table.insert(lines, string.format("   IN  %-20s freieKap=%s", ftName(idx), free))
					end
				end
			end
			-- Outputs mit Modus (PALETTE = Bargeld-Kassette-Kandidat)
			local outSeen = {}
			for _, prod in ipairs(pp.productions or {}) do
				for _, outp in ipairs(prod.outputs or {}) do
					local idx = outp.type
					if idx ~= nil and not outSeen[idx] then
						outSeen[idx] = true
						table.insert(lines, string.format("   OUT %-20s %s", ftName(idx), outMode(pp, idx)))
					end
				end
			end
		end
	end
	if #lines == 1 then table.insert(lines, "(keine passende Produktionsstelle gefunden)") end
	return table.concat(lines, "\n")
end

-- ---------------------------------------------------------------------
--  Registrierung / Lebenszyklus
-- ---------------------------------------------------------------------
function SU.registerCommands()
	if SU.commandsRegistered then
		return
	end
	SU.commandsRegistered = true
	addConsoleCommand("dlspAdd",      "dlspAdd <Station-Teil> <FillType> [priceScale] -- Ware freischalten (ab naechstem Laden)", "dlspAdd",      SU)
	addConsoleCommand("dlspList",     "Listet alle Sellpoint-Deals",                                                              "dlspList",     SU)
	addConsoleCommand("dlspClear",    "dlspClear [Station-Teil] -- Deals loeschen (leer = alle)",                                 "dlspClear",    SU)
	addConsoleCommand("dlspStations", "Listet alle Verkaufsstationen (zum Namen finden)",                                         "dlspStations", SU)
	addConsoleCommand("dlspInfo",     "dlspInfo <Station-Teil> -- zeigt angenommene Waren + Preis",                               "dlspInfo",     SU)
	addConsoleCommand("dlspDiag",     "dlspDiag <Station-Teil> [FillType] -- akzeptiert/supported/#Trigger je Ware (Mismatch)",  "dlspDiag",     SU)
	addConsoleCommand("dlspFreeCap",  "dlspFreeCap <Station-Teil> -- freie Kapazitaet je Ware (0 = Lager voll)",                  "dlspFreeCap",  SU)
	addConsoleCommand("dlspProd",     "dlspProd [Name-Teil] -- Produktionsstellen: Eingang(+Kap) + Output-Modus (PALETTE=Kassette)", "dlspProd",  SU)
	addConsoleCommand("dlspDebug",    "Diagnose (Pfad, Datei, Deals)",                                                            "dlspDebug",    SU)
end

function SU.onLoadMapFinished(mission)
	SU.registerCommands()
	-- Deals NICHT hier anwenden (Placeable/getName noch nicht bereit),
	-- sondern beim ersten Update-Tick.
	SU.applied = false
	SU.updateTicks = 0
end

function SU.onUpdate(mission, dt)
	if SU.applied then
		return
	end
	SU.updateTicks = (SU.updateTicks or 0) + 1
	if SU.updateTicks < 5 then
		return
	end
	SU.applied = true
	if g_server == nil then
		-- MP-Client: KEINE eigene Savegame-Liste (die liegt nur beim Host) --
		-- stattdessen die autoritative Liste beim Server anfragen.
		if g_client ~= nil and DL_SellpointRequestEvent ~= nil then
			g_client:getServerConnection():sendEvent(DL_SellpointRequestEvent.new())
		end
	else
		-- Host bzw. Singleplayer: aus dem eigenen Savegame anwenden.
		SU.applyAllDeals()
	end
end

-- MP-Sync nach einer GUI-Aenderung (guiToggle/guiScale). Nur im Multiplayer aktiv.
-- Host -> Broadcast an alle Clients. Client -> volle Liste an den Server (der
-- uebernimmt sie autoritativ und verteilt sie weiter).
function SU.syncAfterEdit()
	if g_currentMission == nil or DL_SellpointDealsEvent == nil then return end
	local mdi = g_currentMission.missionDynamicInfo
	if mdi == nil or not mdi.isMultiplayer then return end
	if g_server ~= nil then
		g_server:broadcastEvent(DL_SellpointDealsEvent.new(SU.deals), false)
	elseif g_client ~= nil then
		g_client:getServerConnection():sendEvent(DL_SellpointDealsEvent.new(SU.deals))
	end
end

function SU.onMissionDelete(mission)
	if SU.commandsRegistered then
		removeConsoleCommand("dlspAdd")
		removeConsoleCommand("dlspList")
		removeConsoleCommand("dlspClear")
		removeConsoleCommand("dlspStations")
		removeConsoleCommand("dlspInfo")
		removeConsoleCommand("dlspDebug")
		SU.commandsRegistered = false
	end
	SU.dealsLoaded = false
	SU.deals = {}
	SU.applied = false
	SU.updateTicks = 0
end

-- ---------------------------------------------------------------------
--  Base-Game-Funktionen erweitern -- EINMALIG (Guard gegen Doppel-Hook,
--  da DispoList:loadMap diese Datei per source() laedt).
-- ---------------------------------------------------------------------
function SU.installHooks()
	if SU.hooksInstalled then
		return
	end
	if FSBaseMission == nil then
		return
	end
	SU.hooksInstalled = true
	FSBaseMission.loadMapFinished = Utils.appendedFunction(FSBaseMission.loadMapFinished, SU.onLoadMapFinished)
	FSBaseMission.update          = Utils.appendedFunction(FSBaseMission.update,          SU.onUpdate)
	FSBaseMission.delete          = Utils.appendedFunction(FSBaseMission.delete,          SU.onMissionDelete)
	FSBaseMission.saveSavegame    = Utils.appendedFunction(FSBaseMission.saveSavegame,    SU.onSaveSavegame)
	if ItemSystem ~= nil then
		ItemSystem.save = Utils.prependedFunction(ItemSystem.save, SU.onSaveSavegame)
	end
	toLog("Motor geladen (Etappe 1). Debug-Befehle: dlspAdd, dlspList, dlspClear, dlspStations, dlspInfo, dlspDebug")
end

SU.installHooks()
