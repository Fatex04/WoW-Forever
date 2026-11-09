local _, ns = ...
local DF = ns.DF
local german = GetLocale() == 'deDE'
local function T(en,de) return german and de or en end
local COUNT, SLOTS, QUESTION = 10, 12, 134400
DF.flyoutCount, DF.flyoutSlots = COUNT, SLOTS

local function Public(value, kind)
    return not DF.IsSecretValue(value) and type(value) == kind
end
local function Number(value, low, high, default)
    if not Public(value,'number') or value ~= value then return default end
    return math.max(low,math.min(high,value))
end
local function Text(parent,text,x,y,width,template)
    local label=parent:CreateFontString(nil,'OVERLAY',template or 'GameFontHighlight')
    label:SetPoint('TOPLEFT',x,y); label:SetWidth(width); label:SetJustifyH('LEFT'); label:SetText(text)
    return label
end
local function Button(parent,text,width,callback)
    local button=CreateFrame('Button',nil,parent,'BackdropTemplate')
    button:SetSize(width,26)
    button:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
    button:SetBackdropColor(0.12,0.09,0.18,1); button:SetBackdropBorderColor(0.4,0.3,0.55,1)
    button.Label=button:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    button.Label:SetPoint('CENTER'); button.Label:SetText(text)
    button:SetScript('OnClick',callback)
    return button
end
local function Edit(parent,width,x,y)
    local box=CreateFrame('EditBox',nil,parent,'InputBoxTemplate')
    box:SetSize(width,24); box:SetPoint('TOPLEFT',x,y); box:SetAutoFocus(false)
    box:SetMaxLetters(120); box:SetFontObject(GameFontHighlight)
    box:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
    return box
end

local presets={
    teleportAlliance={3561,3562,3565,32271,49359,33690,53140,120145,88342,132621},
    teleportHorde={3567,3563,3566,32272,49358,35715,53140,120145,88344,132627},
    portalsAlliance={10059,11416,11419,32266,49360,33691,53142,120146,88345,132620},
    portalsHorde={11417,11418,11420,32267,49361,35717,53142,120146,88346,132626},
    water={5504,5505,5506,6127,10138,10139,10140,37420,27090},
    food={587,597,990,6129,10144,10145,28612,33717},
    demons={688,697,712,713,691,30146,1122,18540},
}

local function KnownSpell(id)
    local fn=C_SpellBook and C_SpellBook.IsSpellKnown or IsPlayerSpell or IsSpellKnown
    if not fn then return false end
    local ok,known=pcall(fn,id)
    return ok and Public(known,'boolean') and known
end

function DF:ValidateFlyoutAction(action)
    if type(action)~='table' or not Public(action.type,'string') then return end
    local kind,value=action.type,action.value
    if kind=='spell' or kind=='item' or kind=='toy' then
        if Public(value,'number') and value>0 and value<=2147483647 and value==math.floor(value) then
            return {type=kind,value=value}
        end
    elseif kind=='macro' or kind=='equipmentset' then
        if Public(value,'string') and #value>0 and #value<=120 then return {type=kind,value=value} end
        if Public(value,'number') and value>0 and value==math.floor(value) then return {type=kind,value=value} end
    end
end

function DF:InitializeFlyouts()
    if self.flyoutData then return true end
    if not IsLoggedIn() then return false end
    local key=UnitGUID and UnitGUID('player')
    if not Public(key,'string') or key=='' then
        local name=UnitName and UnitName('player')
        local realm=GetRealmName and GetRealmName()
        if not Public(name,'string') or not Public(realm,'string') then return false end
        key=name .. ' - ' .. realm
    end
    if type(DragonflightUIDB.foreverFlyouts)~='table' then DragonflightUIDB.foreverFlyouts={} end
    local characters=DragonflightUIDB.foreverFlyouts
    if type(characters[key])~='table' then characters[key]={} end
    local data=characters[key]
    if type(data.bars)~='table' then data.bars={} end
    local _,class=UnitClass('player')
    local faction=UnitFactionGroup and UnitFactionGroup('player')
    for index=1,COUNT do
        local fresh=type(data.bars[index])~='table'
        local bar=fresh and {} or data.bars[index]
        data.bars[index]=bar
        if type(bar.enabled)~='boolean' then bar.enabled=index<=5 end
        bar.name=type(bar.name)=='string' and bar.name:sub(1,40) or ('Flyout ' .. index)
        bar.icon=Number(bar.icon,1,2147483647,QUESTION)
        bar.scale=Number(bar.scale,0.5,1.5,0.8)
        bar.x=Number(bar.x,-4000,4000,-320+(index-1)*80)
        bar.y=Number(bar.y,-4000,4000,230)
        local points={TOP=true,TOPLEFT=true,TOPRIGHT=true,CENTER=true,LEFT=true,RIGHT=true,
            BOTTOM=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}
        bar.point=points[bar.point] and bar.point or 'BOTTOM'
        bar.relativePoint=points[bar.relativePoint] and bar.relativePoint or 'BOTTOM'
        local directions={UP=true,DOWN=true,LEFT=true,RIGHT=true}
        bar.direction=directions[bar.direction] and bar.direction or 'UP'
        bar.columns=math.floor(Number(bar.columns,1,SLOTS,1))
        if type(bar.closeAfterClick)~='boolean' then bar.closeAfterClick=true end
        bar.binding=type(bar.binding)=='string' and bar.binding:upper():sub(1,40) or ''
        if type(bar.entries)~='table' then bar.entries={} end
        for slot=1,SLOTS do bar.entries[slot]=self:ValidateFlyoutAction(bar.entries[slot]) end
        if fresh and class=='MAGE' then
            if index==1 then bar.name=T('Teleports','Teleports'); bar.icon=237509; bar.preset='teleport' .. (faction=='Horde' and 'Horde' or 'Alliance') end
            if index==2 then bar.name=T('Portals','Portale'); bar.icon=135748; bar.preset='portals' .. (faction=='Horde' and 'Horde' or 'Alliance') end
            if index==3 then bar.name=T('Water','Wasser'); bar.icon=132793; bar.preset='water' end
            if index==4 then bar.name=T('Food','Essen'); bar.icon=134029; bar.preset='food' end
        elseif fresh and class=='WARLOCK' and index==1 then
            bar.name=T('Demons','Dämonen'); bar.icon=136082; bar.preset='demons'
        end
    end
    self.flyoutData,self.flyoutCharacterKey=data,key
    return true
end

function DF:RefreshFlyoutPresets()
    for _,bar in ipairs(self.flyoutData.bars) do
        if presets[bar.preset] then
            local entries={}
            for _,id in ipairs(presets[bar.preset]) do
                if KnownSpell(id) and #entries<SLOTS then entries[#entries+1]={type='spell',value=id} end
            end
            bar.entries=entries
        end
    end
end

function DF:GetFlyoutActionInfo(action)
    if not action then return '',QUESTION end
    local kind,value=action.type,action.value
    if kind=='spell' then
        if C_Spell and C_Spell.GetSpellInfo then
            local info=C_Spell.GetSpellInfo(value)
            if Public(info,'table') then return info.name,info.iconID or QUESTION,value end
        elseif GetSpellInfo then
            local name,_,icon=GetSpellInfo(value)
            if Public(name,'string') then return name,icon or QUESTION,value end
        end
    elseif kind=='item' or kind=='toy' then
        local name,_,_,_,_,_,_,_,_,icon
        if C_Item and C_Item.GetItemInfo then name,_,_,_,_,_,_,_,_,icon=C_Item.GetItemInfo(value) end
        if not icon and C_Item and C_Item.GetItemIconByID then icon=C_Item.GetItemIconByID(value) end
        return name or ('Item ' .. value),icon or QUESTION,value
    elseif kind=='macro' and GetMacroInfo then
        local name,icon=GetMacroInfo(value)
        if Public(name,'string') then return name,icon or QUESTION,value end
    elseif kind=='equipmentset' and C_EquipmentSet then
        local id=Public(value,'number') and value or C_EquipmentSet.GetEquipmentSetID(value)
        if Public(id,'number') then
            local name,icon=C_EquipmentSet.GetEquipmentSetInfo(id)
            if Public(name,'string') then return name,icon or QUESTION,name end
        end
    end
    return T('Unavailable: ','Nicht verfügbar: ') .. tostring(value),QUESTION
end

function DF:SetFlyoutAction(index,slot,action)
    if InCombatLockdown() then self:Print(T('Change flyouts outside combat.','Flyouts außerhalb des Kampfes ändern.')); return false end
    if not self:InitializeFlyouts() then return false end
    if not Public(index,'number') or not Public(slot,'number') or index<1 or index>COUNT or slot<1 or slot>SLOTS or
        index~=math.floor(index) or slot~=math.floor(slot) then return false end
    local normalized=self:ValidateFlyoutAction(action)
    if action~=nil and not normalized then return false end
    if self.flyoutEditor and self.flyoutEditor:IsShown() then self:SaveFlyoutEditor(true) end
    local bar=self.flyoutData.bars[index]
    bar.preset=nil
    bar.entries[slot]=normalized
    self:RefreshFlyouts()
    if self.flyoutEditor then self:RefreshFlyoutEditor() end
    return true
end

function DF:GetFlyoutCursorAction()
    if not GetCursorInfo then return end
    local kind,first,bank,spellID=GetCursorInfo()
    if not Public(kind,'string') then return end
    if not Public(first,'number') and not Public(first,'string') then return end
    local action
    if kind=='spell' then
        if not Public(spellID,'number') and C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
            local bookBank=bank
            if Public(bank,'string') then bookBank=Enum.SpellBookSpellBank[bank=='pet' and 'Pet' or 'Player'] end
            local info=C_SpellBook.GetSpellBookItemInfo(first,bookBank)
            if Public(info,'table') then spellID=info.spellID end
        end
        action={type='spell',value=spellID}
    elseif kind=='item' then
        local toy=C_ToyBox and C_ToyBox.PlayerHasToy and C_ToyBox.PlayerHasToy(first)
        action={type=Public(toy,'boolean') and toy and 'toy' or 'item',value=first}
    elseif kind=='macro' and GetMacroInfo then
        local name=GetMacroInfo(first)
        action={type='macro',value=name}
    elseif kind=='equipmentset' then
        local id=C_EquipmentSet and C_EquipmentSet.GetEquipmentSetID and C_EquipmentSet.GetEquipmentSetID(first)
        action={type='equipmentset',value=Public(id,'number') and id or first}
    elseif kind=='companion' and C_MountJournal and C_MountJournal.GetMountInfoByID then
        local _,id=C_MountJournal.GetMountInfoByID(first)
        action={type='spell',value=id}
    end
    return self:ValidateFlyoutAction(action)
end

function DF:ReceiveFlyoutAction(index,slot)
    if InCombatLockdown() then return false end
    local action=self:GetFlyoutCursorAction()
    if action and self:SetFlyoutAction(index,slot,action) then
        if ClearCursor then ClearCursor() end
        return true
    end
    return false
end

function DF:PickupFlyoutAction(index,slot)
    if InCombatLockdown() or not self.flyoutData then return end
    local action=self.flyoutData.bars[index].entries[slot]
    if not action then return end
    if action.type=='spell' and C_Spell and C_Spell.PickupSpell then C_Spell.PickupSpell(action.value)
    elseif action.type=='item' and C_Item and C_Item.PickupItem then C_Item.PickupItem(action.value)
    elseif action.type=='toy' and C_ToyBox and C_ToyBox.PickupToyBoxItem then C_ToyBox.PickupToyBoxItem(action.value)
    elseif action.type=='macro' and PickupMacro then PickupMacro(action.value)
    elseif action.type=='equipmentset' and C_EquipmentSet and C_EquipmentSet.PickupEquipmentSet then
        local id=Public(action.value,'number') and action.value or C_EquipmentSet.GetEquipmentSetID(action.value)
        if Public(id,'number') then C_EquipmentSet.PickupEquipmentSet(id) end
    end
end

local function IconButton(button,cooldown)
    button:SetSize(45,45)
    button.icon=button:CreateTexture(nil,'ARTWORK')
    button.Icon=button.icon
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.06,0.94,0.06,0.94)
    button.IconMask=button:CreateMaskTexture(nil,'ARTWORK')
    button.IconMask:SetAllPoints(button.icon)
    button.IconMask:SetTexture('Interface\\AddOns\\DragonflightUI\\Textures\\maskNew')
    button.icon:AddMaskTexture(button.IconMask)
    button:SetNormalTexture('Interface\\Buttons\\UI-Quickslot2')
    button:SetPushedTexture('Interface\\Buttons\\UI-Quickslot-Depress')
    button:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square')
    button.Count=button:CreateFontString(nil,'OVERLAY','NumberFontNormal')
    button.Count:SetPoint('BOTTOMRIGHT',-2,2)
    if cooldown then
        button.cooldown=CreateFrame('Cooldown',nil,button,'CooldownFrameTemplate')
        button.cooldown:SetAllPoints(button)
        button.cooldown:SetDrawEdge(false)
    end
end

local openSnippet=[[
    if button ~= 'LeftButton' or down then return end
    local popup=self:GetFrameRef('popup')
    local wasShown=popup:IsShown()
    local controller=self:GetFrameRef('controller')
    for i=1,10 do controller:GetFrameRef('popup'..i):Hide() end
    if not wasShown then popup:Show() end
]]
local closeSnippet=[[
    if button == 'LeftButton' and not down and self:GetAttribute('closeAfterClick') then control:Hide() end
]]
local receiveSnippet=[[
    local controller=control:GetFrameRef('controller')
    if button == 'LeftButton' and not down and controller:GetAttribute('state-cursor') == 'true' then
        if controller:GetAttribute('state-combat') ~= 'true' then self:CallMethod('ReceiveLunaAction') end
        return false
    end
    return nil, true
]]

function DF:CreateFlyoutFrames()
    if self.flyoutRoot then return self.flyoutFramesReady==true end
    if InCombatLockdown() then self.pendingFlyouts=true; return false end
    local root=CreateFrame('Frame','DragonflightUIForeverFlyouts',UIParent,'SecureHandlerBaseTemplate')
    root:Hide()
    root:SetSize(1,1); root:SetPoint('BOTTOMLEFT'); root:EnableMouse(false)
    self.flyoutRoot=root; self.flyoutButtons={}; self.flyoutFramesReady=false
    RegisterStateDriver(root,'cursor','[cursor] true; false')
    RegisterStateDriver(root,'combat','[combat] true; false')
    for index=1,COUNT do
        local launcher=CreateFrame('Button','DragonflightUIForeverFlyout' .. index,root,'SecureHandlerClickTemplate')
        self.flyoutButtons[index]=launcher
        launcher.index=index; launcher:SetClampedToScreen(true); launcher:SetMovable(true)
        launcher:SetFrameStrata('MEDIUM'); launcher:SetFrameLevel(40)
        IconButton(launcher)
        launcher:RegisterForClicks('LeftButtonUp','RightButtonUp')
        launcher:SetAttribute('_onclick',openSnippet)
        SecureHandlerSetFrameRef(launcher,'controller',root)
        launcher.Label=launcher:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
        launcher.Label:SetPoint('TOP',launcher,'BOTTOM',0,-3); launcher.Label:SetWidth(74)
        launcher.Label:SetWordWrap(false); launcher.Label:SetMaxLines(1)
        launcher.HotKey=launcher:CreateFontString(nil,'OVERLAY','NumberFontNormalSmall')
        launcher.HotKey:SetPoint('TOPRIGHT',-1,-1)
        local arrow=launcher:CreateTexture(nil,'OVERLAY')
        arrow:SetTexture('Interface\\AddOns\\DragonflightUI\\Textures\\uiactionbar2x')
        arrow:SetTexCoord(0.884766,0.955078,0.438965,0.445801)
        arrow:SetSize(18,6); arrow:SetPoint('TOP',0,5); launcher.Arrow=arrow
        local popup=CreateFrame('Frame',launcher:GetName() .. 'Popup',launcher,'SecureHandlerShowHideTemplate,BackdropTemplate')
        popup:SetFrameStrata('DIALOG'); popup:SetFrameLevel(80); popup:SetClampedToScreen(true)
        popup:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
        popup:SetBackdropColor(0.025,0.02,0.04,0.96); popup:SetBackdropBorderColor(0.5,0.35,0.65,1)
        popup:SetAttribute('_onshow',[[self:RegisterAutoHide(0.5); self:AddToAutoHide(self:GetParent())]])
        -- BackdropTemplate replaces the inherited SecureHandler OnLoad. Use the
        -- native functions instead of relying on its optional helper methods.
        SecureHandlerSetFrameRef(popup,'controller',root)
        popup:HookScript('OnShow',function() DF:RefreshFlyoutDisplays() end)
        popup:Hide(); launcher.popup=popup; launcher.slots={}
        SecureHandlerSetFrameRef(launcher,'popup',popup); SecureHandlerSetFrameRef(root,'popup'..index,popup)
        for slot=1,SLOTS do
            local child=CreateFrame('Button',launcher:GetName() .. 'Slot' .. slot,popup,'SecureActionButtonTemplate')
            launcher.slots[slot]=child; child.index=index; child.slot=slot
            IconButton(child,true)
            child:RegisterForClicks('LeftButtonUp','RightButtonUp'); child:RegisterForDrag('LeftButton')
            child:SetAttribute('useOnKeyDown',false)
            child.ReceiveLunaAction=function() DF:ReceiveFlyoutAction(index,slot) end
            SecureHandlerWrapScript(child,'OnClick',popup,receiveSnippet,closeSnippet)
            child:SetScript('OnReceiveDrag',function() DF:ReceiveFlyoutAction(index,slot) end)
            child:SetScript('OnDragStart',function()
                if IsShiftKeyDown and IsShiftKeyDown() then DF:PickupFlyoutAction(index,slot) end
            end)
            child:HookScript('OnClick',function(_,button)
                if button=='RightButton' and IsAltKeyDown and IsAltKeyDown() then DF:SetFlyoutAction(index,slot,nil) end
            end)
            child:SetScript('OnEnter',function(self) DF:FlyoutActionTooltip(self,self.action) end)
            child:SetScript('OnLeave',function() GameTooltip:Hide() end)
        end
        launcher:HookScript('OnClick',function(_,button)
            if button=='RightButton' and not InCombatLockdown() then DF:ToggleFlyoutEditor(index) end
        end)
        launcher:SetScript('OnEnter',function(self)
            GameTooltip:SetOwner(self,'ANCHOR_RIGHT')
            GameTooltip:SetText(DF.flyoutData.bars[index].name)
            GameTooltip:AddLine(T('Left click: open · Right click: configure',
                'Linksklick: öffnen · Rechtsklick: konfigurieren'),1,1,1,true)
            GameTooltip:Show()
        end)
        launcher:SetScript('OnLeave',function() GameTooltip:Hide() end)
        local mover=CreateFrame('Frame',nil,UIParent,'BackdropTemplate')
        launcher.mover=mover; mover:SetAllPoints(launcher); mover:SetFrameStrata('DIALOG'); mover:SetFrameLevel(200)
        mover:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
        mover:SetBackdropColor(0.65,0.8,1,0.35); mover:SetBackdropBorderColor(1,1,1,1)
        mover:EnableMouse(true); mover:RegisterForDrag('LeftButton'); mover:Hide()
        mover:SetScript('OnDragStart',function() if not InCombatLockdown() then launcher:StartMoving() end end)
        mover:SetScript('OnDragStop',function()
            if InCombatLockdown() then launcher.pendingStop=true; DF.pendingFlyouts=true; return end
            DF:SaveFlyoutPosition(launcher)
        end)
        mover:SetScript('OnMouseUp',function(_,button)
            if button=='RightButton' then DF:ToggleFlyoutEditor(index) end
        end)
    end
    self.flyoutFramesReady=true
    return true
end

function DF:SaveFlyoutPosition(launcher)
    if InCombatLockdown() then return end
    launcher:StopMovingOrSizing(); launcher.pendingStop=false
    local point,_,relativePoint,x,y=launcher:GetPoint(1)
    local bar=self.flyoutData.bars[launcher.index]
    bar.point,bar.relativePoint,bar.x,bar.y=point,relativePoint,x,y
end

function DF:FlyoutActionTooltip(button,action)
    GameTooltip:SetOwner(button,'ANCHOR_RIGHT')
    if action and action.type=='spell' and GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(action.value)
    elseif action and (action.type=='item' or action.type=='toy') and GameTooltip.SetItemByID then GameTooltip:SetItemByID(action.value)
    else GameTooltip:SetText(action and self:GetFlyoutActionInfo(action) or T('Empty slot','Leerer Platz')) end
    GameTooltip:AddLine(T('Drag an action here · Alt+right click to clear',
        'Aktion hierher ziehen · Alt+Rechtsklick zum Leeren'),0.8,0.8,0.8,true)
    GameTooltip:Show()
end

function DF:PaintFlyoutAction(button,action)
    local name,icon=self:GetFlyoutActionInfo(action)
    button.icon:SetTexture(icon)
    button.action=action
    button.Count:SetText('')
    if not action then if button.cooldown then button.cooldown:Clear() end; return end
    if action.type=='spell' and C_Spell then
        if C_Spell.GetSpellDisplayCount then button.Count:SetText(C_Spell.GetSpellDisplayCount(action.value)) end
        if button.cooldown and C_Spell.GetSpellCooldownDuration and button.cooldown.SetCooldownFromDurationObject then
            local duration=C_Spell.GetSpellCooldownDuration(action.value)
            if not self.IsSecretValue(duration) and duration then button.cooldown:SetCooldownFromDurationObject(duration)
            else button.cooldown:Clear() end
        end
    elseif (action.type=='item' or action.type=='toy') and C_Item then
        if C_Item.GetItemCount then button.Count:SetText(C_Item.GetItemCount(action.value)) end
        if button.cooldown and C_Item.GetItemCooldown then
            local start,duration=C_Item.GetItemCooldown(action.value)
            if not self.IsSecretValue(start) and not self.IsSecretValue(duration) and
                type(start)=='number' and type(duration)=='number' then button.cooldown:SetCooldown(start,duration)
            else button.cooldown:Clear() end
        end
    elseif button.cooldown then button.cooldown:Clear() end
    return name
end

function DF:RefreshFlyoutDisplays()
    if not self.flyoutFramesReady or not self.flyoutButtons or not self.flyoutData then return end
    for _,launcher in ipairs(self.flyoutButtons) do
        if launcher.popup and launcher.popup:IsShown() then
            for slot,child in ipairs(launcher.slots or {}) do self:PaintFlyoutAction(child,self.flyoutData.bars[launcher.index].entries[slot]) end
        end
    end
    if self.flyoutEditor and self.flyoutEditor:IsShown() then self:RefreshFlyoutEditorSlots() end
end

function DF:QueueFlyoutDisplays()
    if self.flyoutDisplayQueued then return end
    self.flyoutDisplayQueued=true
    C_Timer.After(0,function() self.flyoutDisplayQueued=false; self:RefreshFlyoutDisplays() end)
end

function DF:RefreshFlyouts()
    if InCombatLockdown() then self.pendingFlyouts=true; return end
    self.pendingFlyouts=false
    if not self.active or not self.settings.enabled or not self.settings.flyouts then
        self.moduleStatus.Flyouts={enabled=false,setupCompleted=self.flyoutFramesReady==true,native=false}
        if self.flyoutRoot then
            if ClearOverrideBindings then ClearOverrideBindings(self.flyoutRoot) end
            self.flyoutRoot:Hide()
            for _,launcher in ipairs(self.flyoutButtons or {}) do
                if launcher.popup then launcher.popup:Hide() end
                if launcher.mover then launcher.mover:Hide() end
            end
        end
        return
    end
    if not self:InitializeFlyouts() then return end
    self:RefreshFlyoutPresets()
    if not self:CreateFlyoutFrames() then
        self.moduleStatus.Flyouts={enabled=false,setupCompleted=false,native=false}
        return
    end
    if ClearOverrideBindings then ClearOverrideBindings(self.flyoutRoot) end
    self.flyoutRoot:Show()
    local editing=self.editModeSession~=nil
    for index,launcher in ipairs(self.flyoutButtons) do
        local bar=self.flyoutData.bars[index]
        if launcher.pendingStop then self:SaveFlyoutPosition(launcher) end
        launcher.popup:Hide()
        launcher:ClearAllPoints(); launcher:SetPoint(bar.point,UIParent,bar.relativePoint,bar.x,bar.y)
        launcher:SetScale(bar.scale); launcher:SetShown(bar.enabled)
        launcher.Label:SetText(bar.name); launcher.HotKey:SetText(bar.binding)
        launcher.icon:SetTexture(bar.icon)
        launcher.mover:SetShown(editing and bar.enabled)
        local rotations={UP=0,RIGHT=-math.pi/2,DOWN=math.pi,LEFT=math.pi/2}
        launcher.Arrow:SetRotation(rotations[bar.direction])
        local horizontal=bar.direction=='LEFT' or bar.direction=='RIGHT'
        local columns=bar.columns>1 and bar.columns or (horizontal and SLOTS or 1)
        local rows=math.ceil(SLOTS/columns)
        local popup=launcher.popup
        popup:ClearAllPoints(); popup:SetSize(columns*49+12,rows*49+12)
        if bar.direction=='DOWN' then popup:SetPoint('TOP',launcher,'BOTTOM',0,-7)
        elseif bar.direction=='LEFT' then popup:SetPoint('RIGHT',launcher,'LEFT',-7,0)
        elseif bar.direction=='RIGHT' then popup:SetPoint('LEFT',launcher,'RIGHT',7,0)
        else popup:SetPoint('BOTTOM',launcher,'TOP',0,7) end
        for slot,child in ipairs(launcher.slots) do
            local action=bar.entries[slot]
            for _,attribute in ipairs({'type1','spell','item','toy','macro','equipmentset'}) do child:SetAttribute(attribute,nil) end
            child:SetAttribute('closeAfterClick',bar.closeAfterClick)
            local _,_,value=self:GetFlyoutActionInfo(action)
            if value and action then
                child:SetAttribute('type1',action.type)
                child:SetAttribute(action.type,action.type=='item' and ('item:' .. value) or value)
            end
            child:ClearAllPoints(); child:SetPoint('TOPLEFT',popup,'TOPLEFT',6+((slot-1)%columns)*49,-6-math.floor((slot-1)/columns)*49)
            self:PaintFlyoutAction(child,action)
            self:StyleActionButton(child,true)
        end
        self:StyleActionButton(launcher,true)
        if bar.enabled and not editing and bar.binding~='' and SetOverrideBindingClick and bar.binding:match('^[A-Z0-9%-]+$') then
            local ok=pcall(SetOverrideBindingClick,self.flyoutRoot,false,bar.binding,launcher:GetName(),'LeftButton')
            if not ok then
                self:Print(T('Invalid flyout shortcut: ','Ungültiges Flyout-Tastenkürzel: ') .. bar.binding)
                bar.binding=''; launcher.HotKey:SetText('')
            end
        end
    end
    self.moduleStatus.Flyouts={enabled=true,setupCompleted=true,buttons=COUNT,native=false}
end

function DF:RefreshFlyoutMovers()
    for _,launcher in ipairs(self.flyoutButtons or {}) do
        if launcher.mover then
            local bar=self.flyoutData and self.flyoutData.bars[launcher.index]
            launcher.mover:SetShown(self.flyoutFramesReady and self.active and self.settings.enabled and self.settings.flyouts and
                self.editModeSession~=nil and not InCombatLockdown() and bar and bar.enabled or false)
        end
    end
end

function DF:ToggleFlyoutEditor(index)
    if InCombatLockdown() then self:Print(T('Configure flyouts outside combat.','Flyouts außerhalb des Kampfes konfigurieren.')); return end
    if not self:InitializeFlyouts() then return end
    if self.flyoutEditor then
        self:SaveFlyoutEditor(true)
        if index then self.flyoutEditor.index=math.floor(Number(index,1,COUNT,1)); self.flyoutEditor:Show(); self:RefreshFlyoutEditor()
        else self.flyoutEditor:SetShown(not self.flyoutEditor:IsShown()) end
        return
    end
    local frame=CreateFrame('Frame','DragonflightUIForeverFlyoutEditor',UIParent,'BackdropTemplate')
    self.flyoutEditor=frame
    frame.index=math.floor(Number(index,1,COUNT,1)); frame.selectedSlot=1
    frame:SetSize(760,610); frame:SetPoint('CENTER')
    frame:SetScale(math.min(1,math.max(0.5,(UIParent:GetHeight()-40)/610)))
    frame:SetFrameStrata('DIALOG'); frame:SetFrameLevel(350); frame:SetClampedToScreen(true); frame:EnableMouse(true)
    frame:SetMovable(true); frame:RegisterForDrag('LeftButton')
    frame:SetScript('OnDragStart',frame.StartMoving); frame:SetScript('OnDragStop',frame.StopMovingOrSizing)
    frame:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
    frame:SetBackdropColor(0.035,0.03,0.055,0.98); frame:SetBackdropBorderColor(0.42,0.32,0.6,1)
    Text(frame,T('Luna extra flyouts','Luna Extra-Flyouts'),22,-20,650,'GameFontNormalLarge')
    local close=Button(frame,'×',28,function() frame:Hide() end); close:SetPoint('TOPRIGHT',-12,-12)
    frame.choices={}
    for i=1,COUNT do
        local choice=Button(frame,'Flyout '..i,145,function()
            if InCombatLockdown() then return end
            self:SaveFlyoutEditor(true); frame.index=i; self:RefreshFlyoutEditor()
        end)
        choice:SetPoint('TOPLEFT',18,-69-(i-1)*36); frame.choices[i]=choice
    end
    Text(frame,T('Name','Name'),190,-68,180)
    frame.name=Edit(frame,295,195,-90)
    Text(frame,T('Icon ID','Symbol-ID'),512,-68,150)
    frame.icon=Edit(frame,195,517,-90)
    local enabled=CreateFrame('CheckButton',nil,frame)
    frame.enabled=enabled; enabled:SetSize(24,24); enabled:SetPoint('TOPLEFT',190,-127)
    enabled:SetNormalTexture('Interface\\Buttons\\UI-CheckBox-Up'); enabled:SetCheckedTexture('Interface\\Buttons\\UI-CheckBox-Check')
    Text(frame,T('Enabled','Aktiv'),220,-132,145)
    local autoclose=CreateFrame('CheckButton',nil,frame)
    frame.autoclose=autoclose; autoclose:SetSize(24,24); autoclose:SetPoint('TOPLEFT',380,-127)
    autoclose:SetNormalTexture('Interface\\Buttons\\UI-CheckBox-Up'); autoclose:SetCheckedTexture('Interface\\Buttons\\UI-CheckBox-Check')
    Text(frame,T('Close after use','Nach Benutzung schließen'),410,-132,290)
    Text(frame,T('Direction','Richtung'),190,-172,140)
    frame.directions={}
    for i,direction in ipairs({'UP','RIGHT','DOWN','LEFT'}) do
        local captions={UP=T('Up','Oben'),RIGHT=T('Right','Rechts'),DOWN=T('Down','Unten'),LEFT=T('Left','Links')}
        local button=Button(frame,captions[direction],100,function()
            if InCombatLockdown() then return end
            self:SaveFlyoutEditor(true)
            self.flyoutData.bars[frame.index].direction=direction; self:RefreshFlyouts(); self:RefreshFlyoutEditor()
        end)
        button:SetPoint('TOPLEFT',190+(i-1)*130,-194); frame.directions[direction]=button
    end
    Text(frame,T('Scale (0.5–1.5)','Größe (0.5–1.5)'),190,-238,160)
    frame.scale=Edit(frame,135,195,-260)
    Text(frame,T('Columns (1–12)','Spalten (1–12)'),365,-238,160)
    frame.columns=Edit(frame,135,370,-260)
    Text(frame,T('Shortcut, e.g. CTRL-F','Tastenkürzel, z.B. CTRL-F'),540,-238,195)
    frame.binding=Edit(frame,168,545,-260)
    frame.slotButtons={}
    for slot=1,SLOTS do
        local button=Button(frame,'',44,function(_,mouseButton)
            if InCombatLockdown() then return end
            frame.selectedSlot=slot
            if not self:ReceiveFlyoutAction(frame.index,slot) and mouseButton=='RightButton' then self:SetFlyoutAction(frame.index,slot,nil) end
            self:RefreshFlyoutEditor()
        end)
        button:RegisterForClicks('LeftButtonUp','RightButtonUp'); button:RegisterForDrag('LeftButton')
        button:SetSize(44,44); button:SetPoint('TOPLEFT',190+((slot-1)%6)*86,-310-math.floor((slot-1)/6)*74)
        button.icon=button:CreateTexture(nil,'ARTWORK'); button.icon:SetAllPoints(); button.icon:SetTexCoord(0.06,0.94,0.06,0.94)
        button.Caption=Text(frame,tostring(slot),190+((slot-1)%6)*86,-357-math.floor((slot-1)/6)*74,78,'GameFontHighlightSmall')
        button:SetScript('OnReceiveDrag',function() frame.selectedSlot=slot; self:ReceiveFlyoutAction(frame.index,slot) end)
        button:SetScript('OnDragStart',function() self:PickupFlyoutAction(frame.index,slot) end)
        button:SetScript('OnEnter',function(selfButton) self:FlyoutActionTooltip(selfButton,self.flyoutData.bars[frame.index].entries[slot]) end)
        button:SetScript('OnLeave',function() GameTooltip:Hide() end)
        frame.slotButtons[slot]=button
    end
    Text(frame,T('Drop actions onto the slots above. Right click an editor slot to clear it.',
        'Aktionen auf die Plätze oben ziehen. Rechtsklick auf einen Editor-Platz leert ihn.'),190,-466,530,'GameFontHighlightSmall')
    frame.action=Edit(frame,350,195,-498)
    local assign=Button(frame,T('Assign slot','Platz belegen'),160,function()
        if InCombatLockdown() then return end
        local kind,value=frame.action:GetText():match('^%s*(%a+)%s*:%s*(.-)%s*$')
        if kind then
            kind=kind:lower()
            self:SetFlyoutAction(frame.index,frame.selectedSlot,{type=kind,value=tonumber(value) or value})
        end
    end); assign:SetPoint('TOPLEFT',560,-497)
    Text(frame,T('Optional: spell:123 / item:6948 / macro:Name / equipmentset:Name',
        'Optional: spell:123 / item:6948 / macro:Name / equipmentset:Name'),190,-530,530,'GameFontHighlightSmall')
    local save=Button(frame,T('Save settings','Einstellungen speichern'),200,function() self:SaveFlyoutEditor() end)
    save:SetPoint('BOTTOMRIGHT',-24,22)
    local editMode=Button(frame,T('Move in Edit Mode','Im Edit Mode verschieben'),260,function()
        if InCombatLockdown() then return end
        self:SaveFlyoutEditor(); frame:Hide(); self:OpenLunaEditMode()
    end); editMode:SetPoint('BOTTOMLEFT',190,22)
    Text(frame,T('Twelve slots per flyout. Changes are saved per character.',
        'Zwölf Plätze pro Flyout. Änderungen gelten für diesen Charakter.'),20,-455,145,'GameFontHighlightSmall'):SetWordWrap(true)
    frame:SetScript('OnShow',function() self:RefreshFlyoutEditor() end)
    frame:SetScript('OnHide',function()
        for _,field in ipairs({frame.name,frame.icon,frame.scale,frame.columns,frame.binding,frame.action}) do field:ClearFocus() end
    end)
    for _,field in ipairs({frame.name,frame.icon,frame.scale,frame.columns,frame.binding}) do
        field:SetScript('OnEditFocusLost',function() self:SaveFlyoutEditor(true) end)
        field:SetScript('OnEnterPressed',function(box) self:SaveFlyoutEditor(); box:ClearFocus() end)
    end
    UISpecialFrames[#UISpecialFrames+1]='DragonflightUIForeverFlyoutEditor'
    self:RefreshFlyoutEditor()
end

function DF:RefreshFlyoutEditor()
    local frame=self.flyoutEditor
    if not frame or not self.flyoutData then return end
    local bar=self.flyoutData.bars[frame.index]
    frame.name:SetText(bar.name); frame.icon:SetText(tostring(bar.icon))
    frame.scale:SetText(tostring(bar.scale)); frame.columns:SetText(tostring(bar.columns)); frame.binding:SetText(bar.binding)
    frame.enabled:SetChecked(bar.enabled); frame.autoclose:SetChecked(bar.closeAfterClick)
    for i,choice in ipairs(frame.choices) do choice.Label:SetText(i .. ' · ' .. self.flyoutData.bars[i].name) end
    for direction,button in pairs(frame.directions) do
        button:SetBackdropBorderColor(direction==bar.direction and 1 or 0.4,0.5,0.8,1)
    end
    self:RefreshFlyoutEditorSlots()
    local action=bar.entries[frame.selectedSlot]
    frame.action:SetText(action and (action.type .. ':' .. action.value) or '')
end

function DF:RefreshFlyoutEditorSlots()
    local frame=self.flyoutEditor
    if not frame or not self.flyoutData then return end
    local bar=self.flyoutData.bars[frame.index]
    for slot,button in ipairs(frame.slotButtons) do
        local action=bar.entries[slot]
        local name,icon=self:GetFlyoutActionInfo(action)
        button.icon:SetTexture(icon); button.Caption:SetText(name~='' and name or tostring(slot))
        button:SetBackdropBorderColor(slot==frame.selectedSlot and 1 or 0.35,0.5,0.8,1)
    end
end

function DF:SaveFlyoutEditor(skipRefresh)
    if InCombatLockdown() then self:Print(T('Save outside combat.','Außerhalb des Kampfes speichern.')); return end
    local frame=self.flyoutEditor
    if not frame then return end
    local bar=self.flyoutData.bars[frame.index]
    bar.name=frame.name:GetText():sub(1,40)
    bar.icon=Number(tonumber(frame.icon:GetText()),1,2147483647,QUESTION)
    bar.scale=Number(tonumber(frame.scale:GetText()),0.5,1.5,0.8)
    bar.columns=math.floor(Number(tonumber(frame.columns:GetText()),1,SLOTS,1))
    bar.binding=frame.binding:GetText():upper():gsub('%s+',''):sub(1,40)
    if not bar.binding:match('^[A-Z0-9%-]*$') then bar.binding='' end
    bar.enabled=frame.enabled:GetChecked()==true; bar.closeAfterClick=frame.autoclose:GetChecked()==true
    self:RefreshFlyouts()
    if not skipRefresh then self:RefreshFlyoutEditor() end
end
