-----------------------------------------------------------------------------------------------
-- CarbineCanNotUI - Challanges
-- alias CCNUIc
--
-- This addon was made to fix major UI/UX issues with the default
-- Carbine Studios interface.
--
-----------------------------------------------------------------------------------------------
require "Window"

-----------------------------------------------------------------------------------------------
-- CCNUIc Module Definition
-----------------------------------------------------------------------------------------------
local CCNUIc = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local ColorWhite      = ApolloColor.new("white")
local ColorDarkgray   = ApolloColor.new("darkgray")
local ColorGreen      = ApolloColor.new("green")
local ColorApple      = ApolloColor.new("xkcdApple")
local ColorBlue       = ApolloColor.new("blue")
local ColorYellow     = ApolloColor.new("yellow")
local ColorRed        = ApolloColor.new("red")

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function CCNUIc:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  -- initialize variables here
  self.tNodes = {}
  self.config = {
    fTimerInterval = 3.0,
    -- showMedal = false,
    -- showCompleted = true,
    -- showUndiscoverd = true,
    -- showSummerize = true,
    -- showInfoText = false,
    -- showDistance = true,
  }

  return o
end

function CCNUIc:Init()
  local tDependencies = {
    -- empty
  }

  -- register the addon
  Apollo.RegisterAddon(
    self,                                 -- addon table
    false,                                -- has config
    "Config",                             -- name of config file
    tDependencies                         -- table of dependencies
  )

  -- set timer
  self.tUpdateTimer = ApolloTimer.Create(
    self.config.fTimerInterval,           -- 3.0 seconds
    true,                                 -- repeating
    "OnUpdate",                           -- callback
    self                                  -- table that contains the callback
  )
  -- until everthings loaded, dont do anything
  self.tUpdateTimer:Stop()

  -- set values
  self.player = GameLib.GetPlayerUnit();  -- current player table
end

-----------------------------------------------------------------------------------------------
-- CCNUIc OnLoad
-----------------------------------------------------------------------------------------------
function CCNUIc:OnLoad()
  -- load form files and assotiated assets
  self.xmlDoc = XmlDoc.CreateFromFile("CCNUIc.xml")
  -- assets have to be loaded after the parent file, while they are
  -- included in the parent they will not be loaded inside the game
  -- they are also cached after the initial loaded, no asset hotswapping...
  Apollo.LoadSprites("./CCNUIc_Assets.xml", "CCNUIc_Assets")
  self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- CCNUIc OnDocLoaded
-----------------------------------------------------------------------------------------------
function CCNUIc:OnDocLoaded()

  -- only a loaded file can be processed, same for elements ... duh ༼ つ ◕_◕ ༽つ
  if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then

    -- root window, main
    self.wndMain = Apollo.LoadForm(self.xmlDoc, "CCNUIcForm", nil, self)
    if self.wndMain == nil then
      Apollo.AddAddonErrorText(self, "Could not load the main window")
      return
    end

    -- child of main, dataContainer
    self.wndDataContainer = self.wndMain:FindChild("DataContainer")
    if self.wndDataContainer == nil then
      Apollo.AddAddonErrorText(self, "Could not find the data container in main window")
      return
    end

    -- child of main, footer
    self.wndFooter = self.wndMain:FindChild("Footer")
    if self.wndFooter == nil then
      Apollo.AddAddonErrorText(self, "Could not find the footer in main window")
      return
    end

    -- Todo: Settings window
    -- root window, settings
    -- child of settings dataContainer
    -- child of settings footer

    -- register slash commands
    Apollo.RegisterSlashCommand("ccnuic",   "OnSlashCCNUIc", self)
    -- Apollo.RegisterSlashCommand("ccnui c",  "OnSlashCCNUIc", self)

    -- display the main window
    self.wndMain:Show(false, true)
  end
end

-----------------------------------------------------------------------------------------------
-- CCNUIc Functions
-----------------------------------------------------------------------------------------------

-- on SlashCommand "/completer"
function CCNUIc:OnSlashCCNUIc()
  Print("Thank you for using CCNUIc v0.0.8-beta")

  -- reset the dataContainer content
  self.wndDataContainer:DestroyChildren();
  self.tNodes = {};

  -- render into dataContainer
  self:BuildTree()    -- fetch all informations
  self:DrawTree()     -- traverse through the result and draw

  -- show the main window
  self.wndMain:Invoke()

  -- start timer
  self.tUpdateTimer:Start()
end

-----------------------------------------------------------------------------------------------
-- CCNUIc Render
-----------------------------------------------------------------------------------------------

function CCNUIc:BuildTree()
  -- challange and zone information
  -- alias clg = challange
  local clgAll               = ChallengesLib.GetActiveChallengeList();
  local currentZoneId        = GameLib.GetCurrentZoneMap().id; -- 342
  local currentZoneName      = GameLib.GetCurrentZoneMap().strName; -- Ellevar
  local currentZoneNWorldId  = GameLib.GetCurrentZoneMap().nworldId; -- 22
  local currentParentZone    = GameLib.GetCurrentZoneMap().parentZoneId; --7
  local currentZoneFolder    = GameLib.GetCurrentZoneMap().strFolder; -- EllevarBioMech2

  -- initialize counters
  local countChallenges = 0
  local countChallengesCompleated = 0

  -- traverse through all challange results
  -- note: Carbine your API design is very "raw" why not provide some usefull
  -- slices of information instead of the whole thing.
  for idx, clgCurrent in pairs( clgAll ) do
    local clgId         = clgCurrent:GetId()
    local clgZoneName   = clgCurrent:GetZoneInfo()["strZoneName"]; -- Ellevar
    local clgZoneId     = clgCurrent:GetZoneInfo()["id"]; -- 37
    local clgName       = clgCurrent:GetName();
    local clgDistance   = clgCurrent:GetDistance();
    local clgCompleted  = false
    local clgIsLocal    = false

    -- since the API is not telling us which challanges are in the current
    -- players zone, we have to check it ourselfes

    -- first check
    if ( string.find( currentZoneFolder, clgZoneName ) ) or ( string.find( currentZoneName, clgZoneName ) ) then
      clgIsLocal = true
    end

    -- second check
    if ( clgCurrent:GetCompletionCount() > 0 ) then
      clgCompleted = true
    end

    -- note: sadly only discovered challanges are listed
    -- archivements are needed to check for the missing ones
    -- or i am a complete morron and have not seen the obvious

    if ( clgIsLocal == true ) then
      -- count the local challanges, table.getN() has been not accurate
      -- in the past, and this naming does deserved to be ignored.
      -- common getN srsly? Names, Nulls, Networth ... lazy developers.
      countChallenges = countChallenges + 1
      if ( clgCompleted == true ) then
        countChallengesCompleated = countChallengesCompleated + 1
      end

      -- initialize table data for each challange
      table.insert(self.tNodes, {
        id           = clgId,
        distance     = clgDistance,
        name         = clgName,
        completed    = clgCompleted,
        data         = clgCurrent
      })

    end

    -- set the footer text
    -- this maybe needs to be shifted to a geneal draw function but for now it
    -- is fine.
    self.wndFooter:SetText(countChallengesCompleated .."/"..countChallenges)
  end

end

function CCNUIc:DrawTree()

  -- no nodes or container no draw, simple as that
  if (self.tNodes[1] ~= nil) and (self.wndDataContainer ~= nil) then

    -- clear the datacontainer from the previous draw
    self.wndDataContainer:DestroyChildren();

    -- traverse each node from CCNUI:BuildTree()
    for idx, val in pairs(self.tNodes) do
      -- if the node has been generated without data we ignore it.
      if (self.tNodes[idx].data ~= nil) then
        -- update/reset values
        self.tNodes[idx].id         = self.tNodes[idx].data:GetId();
        self.tNodes[idx].name       = self.tNodes[idx].data:GetName();
        self.tNodes[idx].distance   = self.tNodes[idx].data:GetDistance();

        -- only challanges that have been compleated at least once
        -- are to be marked as that.
        if ( self.tNodes[idx].data:GetCompletionCount() > 0 ) then
          self.tNodes[idx].completed = true
        end
      end
    end

    -- sort nodes by distance
    local sort_func = function( a,b ) return a.distance < b.distance end
    table.sort( self.tNodes, sort_func )

    -- populate new tree
    for idx, val in pairs(self.tNodes) do
      local name       = self.tNodes[idx].name;
      local distance   = self.tNodes[idx].distance;
      local id         = self.tNodes[idx].id;
      local completed  = self.tNodes[idx].completed;

      -- load row element from form
      self.row = Apollo.LoadForm(self.xmlDoc, "Row", self.wndDataContainer, self)

      -- check if the loaded form is parsed correctly
      if self.row == nil then
        Print("-- CCNUIc ERROR // Could not load the row ui for some reason.")
        Apollo.AddAddonErrorText(self, "Could not load the row ui for some reason.")
        return
      end

      -- set the ancor offset as table
      -- [1]left [2]top [3]right [4]bottom
      local AnchorOffsets = {self.row:GetAnchorOffsets()};
      local offset = ((idx-1)*25)

      -- shift the offset by one row hight
      AnchorOffsets[2] = AnchorOffsets[2] + offset ;
      AnchorOffsets[4] = AnchorOffsets[4] + offset ;

      -- get the data of the text containing pixie
      local pixieData     = self.row:GetPixieInfo(2)
      pixieData.strText   = "[" .. math.floor(distance).. "m]" .. name

      -- color the text depended on the compleation status and
      -- if it is activable
      if ( completed ) then
        pixieData.crText = ColorDarkgray
        if ( ChallengesLib.AtChallengeStartLocation(id) ) then
          pixieData.crText = ColorApple
        end
      else
        pixieData.strText   = "[" .. math.floor(distance).. "m]" .. name
        if ( ChallengesLib.AtChallengeStartLocation(id) ) then
          pixieData.crText = ColorGreen
        end
      end

      -- refresh the pixi with the new data, destroying and reapplying
      -- is more efficent then the carbine provided function
      self.row:DestroyPixie(2)
      self.row:AddPixie(pixieData)

      -- Set the row to the precalculated position
      self.row:SetAnchorOffsets(
        AnchorOffsets[1],
        AnchorOffsets[2],
        AnchorOffsets[3],
        AnchorOffsets[4]
      );

      -- persist the data on the node
      self.row:SetData(self.tNodes[idx]);
    end

  end

end

-----------------------------------------------------------------------------------------------
-- CCNUIcForm Functions
-----------------------------------------------------------------------------------------------

-- when self.config.timeInterval (default 3) seconds have passed
function CCNUIc:OnUpdate()

  -- Optimization to reduce the API calls, we only redraw the list if we really
  -- need to, this mean you are changing XYZ positions, also happening if you
  -- are changing zones.
  if (self.player ~= nil) and (self.player:GetPosition() ~= nil) then
    self.pos    = self.player:GetPosition()
  else
    self.player = GameLib.GetPlayerUnit()
    -- GetPlayerUnit takes too long, therefore we wait for the next iteration.
  end

  if (self.pos) then
    if (self.oldPos == nil) then
      self.oldPos = self.pos
    end

    if (self.oldPos.x ~= self.pos.x) or (self.oldPos.y ~= self.pos.y) or (self.oldPos.z ~= self.pos.z) then
      self.oldPos = self.pos
      self.wndDataContainer:DestroyChildren()
      self.tNodes = {}
      self:BuildTree()
      self:DrawTree()
    end

  end
end

-- when the Cancel button is clicked
function CCNUIc:OnBtnCancel()
  -- close the window and stopp the timer we could also reset the state
  -- but this is also happening when opening the window
  self.tUpdateTimer:Stop()
  self.wndMain:Close()
end

-- when the Reload button is clicked
function CCNUIc:OnBtnReload()
  -- addition hint that the challanges have been reloaded, in case
  -- that nothing has changed.
  Print("CCNUIc has been reloaded")

  -- stop the timer and reset to initial state
  self.tUpdateTimer:Stop()

  -- reload player clea table
  self.player = GameLib.GetPlayerUnit()
  self.wndDataContainer:DestroyChildren();
  self.tNodes = {};

  -- render
  self:BuildTree()
  self:DrawTree()

  -- start timer
  self.tUpdateTimer:Start()
end

-- when a node item is doubleclicked
function CCNUIc:OnDoubleClick( wndHandler, wndControl, hNode )
  if (self.tNodes[hNode] ~= nil) then
    ChallengesLib.ShowHintArrow(self.tNodes[hNode].id);
  end
end

---------------------------------------------------------------------------------------------------
-- Row Functions
---------------------------------------------------------------------------------------------------

function CCNUIc:OnMouseButtonDown( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
  -- show some fancy arrow to the location of the challange
  ChallengesLib.ShowHintArrow(wndHandler:GetData().id);

  -- if the challange can be started, do so
  if ( ChallengesLib.AtChallengeStartLocation( wndHandler:GetData().id ) ) then
    ChallengesLib.ActivateChallenge(wndHandler:GetData().id)
  end
end

-- change the sprite on Mouse hover since pixies do no provide
-- any function for that, and i do not want to use the button API for a simple
-- clickable sprite
function CCNUIc:OnMouseEnter( wndHandler, wndControl, x, y )
  local pixieData = wndHandler:GetPixieInfo(1)

  pixieData.strSprite =  "sprActionBarFrame_VehicleIconBG"
  wndHandler:UpdatePixie(1, pixieData)
end

-- see above, reset part of the hover effext
function CCNUIc:OnMouseExit( wndHandler, wndControl, x, y )
  local pixieData = wndHandler:GetPixieInfo(1)

  pixieData.strSprite = ""
  wndHandler:UpdatePixie(1, pixieData)
end

-----------------------------------------------------------------------------------------------
-- CCNUIc Instance
-----------------------------------------------------------------------------------------------
local CCNUIcInst = CCNUIc:new()
CCNUIcInst:Init()
