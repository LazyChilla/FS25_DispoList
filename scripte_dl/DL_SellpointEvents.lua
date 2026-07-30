-- =====================================================================
--  DispoList / DL_SellpointEvents.lua        (Etappe 3: Multiplayer-Sync)
-- ---------------------------------------------------------------------
--  Server-autoritative Synchronisation der Sellpoint-Deals.
--  Muster verifiziert aus FS25_AD_Extension (ADExtSnapshotEvent) +
--  claude/FS25_Modding_Architektur.md (MP-Event-Pattern, aus AutoDrive).
--
--  Ablauf:
--   - Host aendert einen Deal (GUI)  -> broadcastet die volle Liste an alle Clients.
--   - Client tritt bei (1. Tick)     -> fragt per Request-Event beim Server an,
--                                        der die volle Liste an genau diesen Client schickt.
--   - Client aendert einen Deal (GUI)-> schickt die volle Liste an den Server;
--                                        der uebernimmt sie, wendet sie an und
--                                        verteilt sie an alle ANDEREN Clients.
--   - Der eigentliche Verkauf laeuft ohnehin serverautoritativ (Giants).
--
--  Nur Giants-Lua fuer LS25.
-- =====================================================================

-- ── Deals-Event: traegt die volle Deal-Liste ────────────────────────────────
DL_SellpointDealsEvent = {}
local DL_SellpointDealsEvent_mt = Class(DL_SellpointDealsEvent, Event)
InitEventClass(DL_SellpointDealsEvent, "DL_SellpointDealsEvent")

function DL_SellpointDealsEvent.emptyNew()
	return Event.new(DL_SellpointDealsEvent_mt)
end

function DL_SellpointDealsEvent.new(deals)
	local self = DL_SellpointDealsEvent.emptyNew()
	self.deals = deals or {}
	return self
end

function DL_SellpointDealsEvent:writeStream(streamId, connection)
	local deals = self.deals or {}
	streamWriteInt32(streamId, #deals)
	for _, d in ipairs(deals) do
		streamWriteString(streamId, tostring(d.station or ""))
		streamWriteString(streamId, tostring(d.fillType or ""))
		streamWriteFloat32(streamId, d.priceScale or 1)
	end
end

function DL_SellpointDealsEvent:readStream(streamId, connection)
	local n = streamReadInt32(streamId)
	local deals = {}
	for _ = 1, n do
		local station  = streamReadString(streamId)
		local fillType = streamReadString(streamId)
		local scale    = streamReadFloat32(streamId)
		table.insert(deals, { station = station, fillType = string.upper(fillType), priceScale = scale })
	end
	self.deals = deals
	self:run(connection)
end

function DL_SellpointDealsEvent:run(connection)
	if DL_SellpointUnlock == nil then return end
	DL_SellpointUnlock.deals       = self.deals or {}
	DL_SellpointUnlock.dealsLoaded = true
	DL_SellpointUnlock.applyAllDeals()
	-- Auf dem Server (von einem Client empfangen): uebernommene Liste an alle
	-- ANDEREN Clients weiterverteilen (ignoreConnection = der Absender).
	if g_server ~= nil then
		g_server:broadcastEvent(DL_SellpointDealsEvent.new(DL_SellpointUnlock.deals), false, connection, nil)
	end
end

-- ── Request-Event: Client bittet Server um die aktuelle Liste ────────────────
DL_SellpointRequestEvent = {}
local DL_SellpointRequestEvent_mt = Class(DL_SellpointRequestEvent, Event)
InitEventClass(DL_SellpointRequestEvent, "DL_SellpointRequestEvent")

function DL_SellpointRequestEvent.emptyNew()
	return Event.new(DL_SellpointRequestEvent_mt)
end

function DL_SellpointRequestEvent.new()
	return DL_SellpointRequestEvent.emptyNew()
end

function DL_SellpointRequestEvent:writeStream(streamId, connection)
	-- keine Nutzdaten
end

function DL_SellpointRequestEvent:readStream(streamId, connection)
	self:run(connection)
end

function DL_SellpointRequestEvent:run(connection)
	-- Laeuft auf dem Server: dem anfragenden Client die aktuelle Liste schicken.
	if g_server == nil or DL_SellpointUnlock == nil then return end
	if not DL_SellpointUnlock.dealsLoaded then DL_SellpointUnlock.loadDeals() end
	connection:sendEvent(DL_SellpointDealsEvent.new(DL_SellpointUnlock.deals))
end
