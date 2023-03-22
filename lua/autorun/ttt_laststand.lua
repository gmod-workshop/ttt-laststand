-- author "Doctor Jew"
-- contact "http://steamcommunity.com/DoctorJew"

AddCSLuaFile()

CreateConVar("ttt_laststand_enable", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Is the Last Stand feature enabled?")
CreateConVar("ttt_laststand_chance", 1.0, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Chance the last Innocent will become a Detective. (0.0 - 1.0)")
CreateConVar("ttt_laststand_chance_multiplier", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Multiplier per Traitors alive. For example 1.1 will increase the chance by 10% per Traitor alive.")
CreateConVar("ttt_laststand_time", 60, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Time (seconds) the Innocent must wait before becoming a Detective.")
CreateConVar("ttt_laststand_time_multiplier", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Multiplier per Traitors alive. For example 1.1 will reduce the time by 10% per Traitor alive.")
CreateConVar("ttt_laststand_credits", 2, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Number of credits the Innocent will receive upon becoming a Detective.")
CreateConVar("ttt_laststand_multiple", 0, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Can more than one Innocent be turned into a Detective? (Ex: If a new Detective revives somebody.)")
CreateConVar("ttt_laststand_strict", 0, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Do Innocents become a Detective if they killed an Innocent last?")

if SERVER then
  resource.AddFile("materials/vgui/ttt/laststand_hud.png")

  local LastStandTriggered = false

  --[[Addon logic]]
  --
  hook.Add("PlayerDeath", "LastStandPlayerDeath", function(victim, inflictor, attacker)
    if not GetConVar("ttt_laststand_strict"):GetBool() then return end
    if attacker:IsSpecial() then return end

    local count = 0

    for k, v in pairs(util.GetAlivePlayers()) do
      if not v:IsSpecial() or v:IsDetective() then
        count = count + 1
      end
    end

    if not victim:IsTraitor() and count <= 2 then
      attacker.LastStandBlock = true
    end
  end)

  hook.Add("PostPlayerDeath", "LastStandPostPlayerDeath", function(ply)
    if engine.ActiveGamemode() ~= "terrortown" then return end
    if not GetConVar("ttt_laststand_enable"):GetBool() then return end
    if GetRoundState() ~= ROUND_ACTIVE then return end
    if NumberOfInnocents() > 1 or DetectiveExists() then return end

    local chance = GetConVar("ttt_laststand_chance"):GetFloat()
    local chance_multiplier = GetConVar("ttt_laststand_chance_multiplier"):GetFloat()

    if chance_multiplier > 0 then
      chance = chance + (chance * (NumberOfTraitors() * (chance_multiplier - 1)))
    end

    if chance < math.random() then return end

    local time = GetConVar("ttt_laststand_time"):GetInt()
    local multiplier = GetConVar("ttt_laststand_time_multiplier"):GetFloat()

    if multiplier > 0 then
      time = time - (time * (NumberOfTraitors() * (multiplier - 1)))
    end

    if CurTime() + time > GetGlobalFloat("ttt_round_end", 0) then return end

    local innocent = nil

    for k, v in pairs(util.GetAlivePlayers()) do
      if not v:IsSpecial() and v:IsActive() then
        innocent = v
        break
      end
    end

    if not IsValid(innocent) then return end

    if IsValid(innocent) and innocent.LastStandBlock then
      LANG.MsgAll("laststand_block", {name = innocent:Nick()})
      return
    end

    LANG.MsgAll("laststand_alert", {name = innocent:Nick(), time = time})

    if TTT2 then
      STATUS:AddTimedStatus(innocent, "ttt_laststand_timer", time, true)
    end

    timer.Create("LastStandTimer", time, 1, function()
      if GetRoundState() ~= ROUND_ACTIVE then return end
      if NumberOfInnocents() > 1 or DetectiveExists() then return end
      if not IsValid(innocent) then return end

      innocent:SetRole(ROLE_DETECTIVE)
      innocent:AddCredits(GetConVar("ttt_laststand_credits"):GetInt())
      SendFullStateUpdate()
      LastStandTriggered = true

      LANG.MsgAll("laststand_survived", {name = innocent:Nick()})
    end)
  end)

  hook.Add("PlayerSpawn", "LastStandPlayerSpawn", function(ply)
    if (NumberOfInnocents() > 1 or DetectiveExists()) and timer.Exists("LastStandTimer") then
      timer.Remove("LastStandTimer")
      LANG.MsgAll("laststand_cancel")

      if TTT2 then
        STATUS:RemoveStatus(player.GetAll(), "ttt_laststand_timer")
      end
    end
  end)

  hook.Add("TTTEndRound", "LastStandTTTRoundEnd", function(result)
    if timer.Exists("LastStandTimer") then
      timer.Remove("LastStandTimer")

      if TTT2 then
        STATUS:RemoveStatus(player.GetAll(), "ttt_laststand_timer")
      end
    end

    LastStandTriggered = false

    for k, v in pairs(player.GetAll()) do
      v.LastStandBlock = false
    end
  end)

  function NumberOfInnocents()
    local total = 0

    for k, v in pairs(util.GetAlivePlayers()) do
      if v:IsActiveRole(ROLE_INNOCENT) then
        total = total + 1
      end
    end

    return total
  end

  function DetectiveExists()
    if LastStandTriggered and not GetConVar("ttt_laststand_multiple"):GetBool() then return true end
    for k, v in pairs(util.GetAlivePlayers()) do
      if v:IsActiveDetective() then
        return true
      end
    end

    return false
  end
else
  -- LANG is not defined until the gamemode has loaded...
  hook.Add("InitPostEntity", "LastStandInitPostEntity", function()
    LANG.AddToLanguage("english", "laststand_name", "Last Stand")
    LANG.AddToLanguage("english", "laststand_alert", "{name} will become a Detective if they survive for {time} seconds.")
    LANG.AddToLanguage("english", "laststand_block", "{name} recently killed an Innocent and will not become a Detective.")
    LANG.AddToLanguage("english", "laststand_update", "{name} will become a Detective in {time} seconds.")
    LANG.AddToLanguage("english", "laststand_survived", "{name} managed to survive and has become a Detective.")
    LANG.AddToLanguage("english", "laststand_cancel", "An Innocent was respawned, preventing a new Detective.")

    -- Custom notification styling
    LANG.Styles.color_red = LANG.Styles.color_red or function(text)
      MSTACK:AddColoredBgMessage(text, Color(150, 0, 0, 200))
    end

    LANG.Styles.color_blue = LANG.Styles.color_blue or function(text)
      MSTACK:AddColoredBgMessage(text, Color(0, 0, 150, 200))
    end

    LANG.SetStyle("laststand_cancel", LANG.Styles.color_red)
    LANG.SetStyle("laststand_survived", LANG.Styles.color_blue)
  end)

  hook.Add("Initialize", "LastStandInitialize", function()
    if not TTT2 then return end

    STATUS:RegisterStatus("ttt_laststand_timer", {
      hud = Material("vgui/ttt/laststand_hud.png"),
      type = "default"
    })
  end)
end

hook.Add("TTTUlxInitCustomCVar", "LastStandTTTUlxInitCustomCVar", function(name)
  ULib.replicatedWritableCvar("ttt_laststand_enable", "rep_ttt_laststand_enable", GetConVar("ttt_laststand_enable"):GetBool(), true, false, name)
  ULib.replicatedWritableCvar("ttt_laststand_chance", "rep_ttt_laststand_chance", GetConVar("ttt_laststand_chance"):GetFloat(), true, false, name)
  ULib.replicatedWritableCvar("ttt_laststand_chance_multiplier", "rep_ttt_laststand_chance_multiplier", GetConVar("ttt_laststand_chance_multiplier"):GetFloat(), true, false, name)
  ULib.replicatedWritableCvar("ttt_laststand_time", "rep_ttt_laststand_time", GetConVar("ttt_laststand_time"):GetInt(), true, false, name)
  ULib.replicatedWritableCvar("ttt_laststand_time_multiplier", "rep_ttt_laststand_time_multiplier", GetConVar("ttt_laststand_time_multiplier"):GetFloat(), true, false, name)
  ULib.replicatedWritableCvar("ttt_laststand_credits", "rep_ttt_laststand_credits", GetConVar("ttt_laststand_credits"):GetInt(), true, false, name)
  ULib.replicatedWritableCvar("ttt_laststand_multiple", "rep_ttt_laststand_multiple", GetConVar("ttt_laststand_multiple"):GetBool(), true, false, name)
  ULib.replicatedWritableCvar("ttt_laststand_strict", "rep_ttt_laststand_strict", GetConVar("ttt_laststand_strict"):GetBool(), true, false, name)
end)

if CLIENT then
  hook.Add("TTTUlxModifyAddonSettings", "LastStandTTTUlxModifyAddonSettings", function(name)
    local tttrspnl = xlib.makelistlayout{w = 415, h = 318, parent = xgui.null}

    -- Basic Settings 
    local tttrsclp1 = vgui.Create("DCollapsibleCategory", tttrspnl)
    tttrsclp1:SetSize(390, 50)
    tttrsclp1:SetExpanded(1)
    tttrsclp1:SetLabel("Basic Settings")

    local tttrslst1 = vgui.Create("DPanelList", tttrsclp1)
    tttrslst1:SetPos(5, 25)
    tttrslst1:SetSize(390, 150)
    tttrslst1:SetSpacing(5)

    local tttrsdh11 = xlib.makecheckbox{label = "ttt_laststand_enable (Def. 1)", repconvar = "rep_ttt_laststand_enable", parent = tttrslst1}
    tttrslst1:AddItem(tttrsdh11)

    local tttrsdh12 = xlib.makeslider{label = "ttt_laststand_chance (Def. 1)", repconvar = "rep_ttt_laststand_chance", min = 0, max = 1, decimal = 2, parent = tttrslst1}
    tttrslst1:AddItem(tttrsdh12)

    local chance_multiplier = xlib.makeslider{label = "ttt_laststand_chance_multiplier (Def. 1)", repconvar = "rep_ttt_laststand_chance_multiplier", min = 1, max = 5, decimal = 2, parent = tttrslst1}
    tttrslst1:AddItem(chance_multiplier)

    local tttrsdh13 = xlib.makeslider{label = "ttt_laststand_time (Def. 60)", repconvar = "rep_ttt_laststand_time", min = 1, max = 120, decimal = 0, parent = tttrslst1}
    tttrslst1:AddItem(tttrsdh13)

    local time_multiplier = xlib.makeslider{label = "ttt_laststand_time_multiplier (Def. 1)", repconvar = "rep_ttt_laststand_time_multiplier", min = 1, max = 5, decimal = 2, parent = tttrslst1}
    tttrslst1:AddItem(time_multiplier)

    local tttrsdh14 = xlib.makeslider{label = "ttt_laststand_credits (Def. 2)", repconvar = "rep_ttt_laststand_credits", min = 0, max = 10, decimal = 0, parent = tttrslst1}
    tttrslst1:AddItem(tttrsdh14)

    local tttrsdh15 = xlib.makecheckbox{label = "ttt_laststand_multiple (Def. 0)", repconvar = "rep_ttt_laststand_multiple", parent = tttrslst1}
    tttrslst1:AddItem(tttrsdh15)

    local tttrsdh16 = xlib.makecheckbox{label = "ttt_laststand_strict (Def. 0)", repconvar = "rep_ttt_laststand_strict", parent = tttrslst1}
    tttrslst1:AddItem(tttrsdh16)

    xgui.hookEvent("onProcessModules", nil, tttrspnl.processModules)
    xgui.addSubModule("Last Stand", tttrspnl, nil, name)
  end)
end
