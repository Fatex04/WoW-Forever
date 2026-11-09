local _, ns = ...
local DF = ns.DF
local german = GetLocale() == 'deDE'
local function T(en, de) return german and de or en end

DF.discordURL = 'https://discord.gg/ZfYDHV6Qgs'
DF.releaseNotes = {
    T('Flyout startup hotfix', 'Hotfix für den Flyout-Start'),
    T('Fixed the missing secure helper on flyout popups. All ten launchers and their slots now finish initializing with the Forever client templates.',
      'Fehlende Secure-Hilfsmethode am Flyout-Popup behoben. Alle zehn Knöpfe und ihre Plätze werden mit den Forever-Clientvorlagen vollständig aufgebaut.'),
    T('Incomplete flyouts stay hidden. Cooldown updates and opening or closing Edit Mode no longer cause follow-up popup or mover errors after an interrupted startup.',
      'Unvollständige Flyouts bleiben ausgeblendet. Cooldown-Updates sowie das Öffnen und Schließen des Edit Mode verursachen nach einem abgebrochenen Start keine Folgefehler bei Popup oder Verschieberahmen mehr.'),
    T('Your saved flyout actions, shortcuts, positions and layouts are retained.',
      'Gespeicherte Flyout-Aktionen, Tastenkürzel, Positionen und Layouts bleiben erhalten.'),
    T('Classic-style extra flyouts', 'Zusätzliche Flyouts wie in Classic'),
    T('Ten configurable flyout buttons with twelve slots each: drag spells, items, toys, mounts, macros or equipment sets onto a slot.',
      'Zehn konfigurierbare Flyout-Knöpfe mit je zwölf Plätzen: Zauber, Gegenstände, Spielzeuge, Reittiere, Makros oder Ausrüstungssets auf einen Platz ziehen.'),
    T('Mage teleport, portal, food and water presets; warlock demon presets. Customize each character with /df flyouts.',
      'Magier-Vorgaben für Teleports, Portale, Essen und Wasser; Dämonen-Vorgaben für Hexenmeister. Pro Charakter über /df flyouts anpassen.'),
    T('Choose the direction, size and shortcut of each flyout. Move the extra buttons in Luna Edit Mode.',
      'Richtung, Größe und Tastenkürzel jedes Flyouts einstellen. Die zusätzlichen Knöpfe lassen sich im Luna Edit Mode verschieben.'),
    T('Patchnotes and a selectable Discord invite now appear once per account after each Forever update. Reopen them with /df patchnotes or /df discord.',
      'Patchnotes mit markierbarem Discord-Link erscheinen nach jedem Forever-Update einmal pro Account. Erneut öffnen mit /df patchnotes oder /df discord.'),
    T('Existing layouts, profiles and native action bars are retained.',
      'Vorhandene Layouts, Profile und native Aktionsleisten bleiben erhalten.'),
}

local function Label(parent, text, template)
    local label = parent:CreateFontString(nil, 'OVERLAY', template or 'GameFontHighlight')
    label:SetText(text)
    label:SetJustifyH('LEFT')
    return label
end

function DF:CreateUpdateNotice()
    if self.updateNotice then return self.updateNotice end
    local frame = CreateFrame('Frame', 'DragonflightUIForeverChangelog', UIParent, 'BackdropTemplate')
    self.updateNotice = frame
    frame:SetSize(590, 485)
    frame:SetScale(math.min(1, math.max(0.5, (UIParent:GetHeight() - 40) / 485)))
    frame:SetPoint('CENTER')
    frame:SetFrameStrata('DIALOG')
    frame:SetFrameLevel(500)
    frame:SetClampedToScreen(true)
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag('LeftButton')
    frame:SetScript('OnDragStart', frame.StartMoving)
    frame:SetScript('OnDragStop', frame.StopMovingOrSizing)
    frame:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',
        edgeSize=24,insets={left=8,right=8,top=8,bottom=8}})
    frame:SetBackdropColor(0.025, 0.02, 0.04, 0.93)
    frame:SetBackdropBorderColor(0.62, 0.48, 0.78, 1)

    local logo = frame:CreateTexture(nil, 'ARTWORK')
    logo:SetSize(42,42)
    logo:SetPoint('TOPLEFT',20,-15)
    logo:SetTexture('Interface\\AddOns\\DragonflightUI\\Textures\\Art\\luna-logo.tga')
    local title = Label(frame, self.title, 'GameFontNormalLarge')
    title:SetPoint('TOPLEFT',74,-21)
    title:SetWidth(455)
    local version = Label(frame, T('Update ', 'Version ') .. self.version, 'GameFontHighlightSmall')
    version:SetPoint('TOPLEFT',74,-44)
    local close = CreateFrame('Button', nil, frame, 'UIPanelCloseButton')
    close:SetPoint('TOPRIGHT',-6,-6)
    close:SetScript('OnClick',function() frame:Hide() end)

    local prompt = Label(frame, T('Found a bug or have feedback? Join our Discord:',
        'Fehler gefunden oder Feedback? Komm auf unseren Discord:'))
    prompt:SetPoint('TOPLEFT',26,-79)
    prompt:SetWidth(535)
    local discordLogo = frame:CreateTexture(nil,'ARTWORK')
    discordLogo:SetSize(24,24)
    discordLogo:SetPoint('TOPLEFT',26,-110)
    discordLogo:SetTexture('Interface\\AddOns\\DragonflightUI\\Textures\\Art\\discord')
    local link = CreateFrame('EditBox', nil, frame, 'InputBoxTemplate')
    link:SetSize(282,24)
    link:SetPoint('TOPLEFT',63,-111)
    link:SetAutoFocus(false)
    link:SetFontObject(GameFontHighlight)
    link:SetText(self.discordURL)
    link:SetCursorPosition(0)
    link:SetScript('OnEditFocusGained',function(box) box:HighlightText() end)
    link:SetScript('OnMouseUp',function(box) box:HighlightText() end)
    link:SetScript('OnTextChanged',function(box,userInput)
        if userInput then box:SetText(DF.discordURL); box:HighlightText() end
    end)
    link:SetScript('OnEscapePressed',function(box) box:ClearFocus() end)
    link:SetScript('OnEnterPressed',function(box) box:ClearFocus() end)
    frame.DiscordLink = link
    local hint = Label(frame,T('Click + Ctrl+C to copy','Klicken + Strg+C kopieren'),'GameFontHighlightSmall')
    hint:SetPoint('LEFT',link,'RIGHT',12,0)
    hint:SetWidth(205)

    local divider = frame:CreateTexture(nil,'ARTWORK')
    divider:SetColorTexture(0.55,0.42,0.18,0.8)
    divider:SetPoint('TOPLEFT',26,-150)
    divider:SetSize(535,1)
    local scroll = CreateFrame('ScrollFrame', nil, frame, 'UIPanelScrollFrameTemplate')
    scroll:SetPoint('TOPLEFT',26,-169)
    scroll:SetPoint('BOTTOMRIGHT',-45,44)
    local content = CreateFrame('Frame',nil,scroll)
    content:SetSize(510,1)
    scroll:SetScrollChild(content)
    local notes = Label(content,table.concat(self.releaseNotes,'\n\n'))
    notes:SetPoint('TOPLEFT')
    notes:SetWidth(510)
    notes:SetWordWrap(true)
    content:SetHeight(math.max(270,notes:GetStringHeight()+12))
    frame.ScrollFrame = scroll
    frame.Notes = notes
    local footer = Label(frame,T('Shown once per update · /df patchnotes to reopen',
        'Einmal pro Update · erneut öffnen mit /df patchnotes'),'GameFontHighlightSmall')
    footer:SetPoint('BOTTOMLEFT',26,19)
    footer:SetWidth(535)
    frame:SetScript('OnHide',function(self) self:StopMovingOrSizing(); link:ClearFocus() end)
    UISpecialFrames[#UISpecialFrames+1] = 'DragonflightUIForeverChangelog'
    frame:Hide()
    return frame
end

function DF:ShowUpdateNotice(manual)
    if not self.active or not DragonflightUIDB then return end
    DragonflightUIDB.global = DragonflightUIDB.global or {}
    if not manual and DragonflightUIDB.global.lastForeverUpdateNoticeVersion == self.version then
        self.pendingUpdateNotice = false
        return
    end
    if not IsLoggedIn() or InCombatLockdown() or (not manual and (self.editModeSession or
        (EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()))) then
        self.pendingUpdateNotice = true
        self.manualUpdateNotice = manual or self.manualUpdateNotice
        return
    end
    local frame = self:CreateUpdateNotice()
    frame.ScrollFrame:SetVerticalScroll(0)
    frame:Show()
    DragonflightUIDB.global.lastForeverUpdateNoticeVersion = self.version
    self.pendingUpdateNotice, self.manualUpdateNotice = false, false
end

function DF:QueueUpdateNotice()
    if not self.active or self.updateNoticeQueued then return end
    self.updateNoticeQueued = true
    C_Timer.After(1,function()
        self.updateNoticeQueued = false
        self:ShowUpdateNotice(self.manualUpdateNotice)
    end)
end
