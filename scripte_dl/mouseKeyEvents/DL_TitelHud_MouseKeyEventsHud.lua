DL_TitelHud_MouseKeyEventsHud = {}

function DL_TitelHud_MouseKeyEventsHud.onClick(args)
    if args == nil or type(args) ~= "table" or args.clickAreaTable == nil then return end
    if not args.isDown then return end
    if g_currentMission.hlUtils.dragDrop.on then return end
    if args.button ~= Input.MOUSE_BUTTON_LEFT then return end
    if args.clickAreaTable.whereClick ~= "dlTitelIcon_" then return end

    -- Gleiches Ziel wie das bestehende Tastenkuerzel DL_ONOFFDISPLAY
    -- (dispoList.lua, PlayerInputComponent:dlSystemActionCallback) --
    -- beide Wege bleiben unabhaengig nebeneinander bestehen.
    local box = g_currentMission.hlHudSystem.hlBox:getData("DL_Display_Box")
    if box == nil or box.show == nil then return end

    box.show = not box.show
    box:setUpdateState(true)
    if box.show then
        DispoList:refreshDispoTable()
        DispoList:checkPresetDialog()
        DispoList.timePast       = 0
        DispoList.refreshSinceMs = 0
    else
        DispoList.deltaNewCount = 0
        DispoList.deltaNotOnMap = 0
        DispoList.zlHinweisGesehen = true
        local fbox = g_currentMission.hlHudSystem.hlBox:getData("DL_Filter_Box")
        if fbox ~= nil and fbox.show then
            fbox.show = false
            DispoList.filterMenuOpen = false
            if DispoList.resetSearch ~= nil then DispoList.resetSearch() end
        end
        if DispoList.resetMainSearch ~= nil then DispoList.resetMainSearch() end
    end
end
