DL_TitelHud_XmlHud = {}

-- Laedt das einzelne weisse Titel-Icon (dlTitel) aus icons_dl/icons.xml
-- + icons_dl/icons.dds ins hud.overlays.modIcons-Table (analog zu
-- PlayerTeleport_DisplaySetGet:loadHudIcons, siehe FS25_PlayerTeleportDisplay).
-- Eingefaerbt wird erst zur Laufzeit im Draw (grau/gruen), siehe DL_TitelHud_DrawHud.
function DL_TitelHud_XmlHud:loadIcons(hud)
    if hud.overlays.modIcons == nil then hud.overlays.modIcons = {byName = {}} end
    g_currentMission.hlUtils.insertIcons(
        {
            xmlTagName = "dispoList.hudIcons",
            modDir     = DispoList.modDir,
            iconFile   = "icons_dl/icons.dds",
            xmlFile    = "icons_dl/icons.xml",
            modName    = "DispoList",
            groupName  = "hud",
            fileFormat = {128, 128, 128},  -- Icon fuellt das ganze 128x128-Sheet (voller UV-Bereich)
            iconTable  = hud.overlays.modIcons,
        }
    )
end

-- Erzeugt das Titel-HUD-Icon in der HL-Icon-Zeile.
-- Klick darauf toggelt dieselbe DL_Display_Box wie das bestehende
-- Tastenkuerzel (DL_ONOFFDISPLAY) -- beide Wege bleiben unabhaengig
-- nebeneinander bestehen, siehe dispoList.lua ~Zeile 1757.
function DL_TitelHud_XmlHud:loadHud(name)
    if name ~= "DL_TitelHud" then return false end
    local hud = g_currentMission.hlHudSystem.hlHud.generate(
        {
            name          = name,
            width         = 40,
            info          = "DispoList\nLagerbestand + Bestpreise",
            displayName   = "DispoList Hud",
            hiddenMod     = "DispoList",
            autoZoomOutIn = "",
            ownTable      = {},
        }
    )
    if hud == nil then
        print("#ERROR DispoList: DL_TitelHud generate() returned nil")
        return false
    end
    DL_TitelHud_XmlHud:loadIcons(hud)
    hud.onDraw  = DL_TitelHud_DrawHud.setHud
    hud.onClick = DL_TitelHud_MouseKeyEventsHud.onClick
    return true
end
