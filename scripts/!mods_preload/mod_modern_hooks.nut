local versionArray = split(::GameInfo.getVersionNumber(), ".");
local preRelease = versionArray.pop();
local version = versionArray.reduce(@(_a, _b) _a + "." + _b) + "-" + preRelease;
// temporary patch for MSU 1.2 compatibility
if (!::Hooks.hasMod("vanilla") && !("MSU" in this.getroottable() && ::Hooks.SQClass.ModVersion(::MSU.Version) < ::Hooks.SQClass.ModVersion("1.3.0-a") ))
	::Hooks.register("vanilla", version, "Vanilla");
foreach (key, value in ::Const.DLC)
{
	if ((typeof value != "bool") || (value == false))
		continue;
	local string = "dlc";
	foreach (char in key)
	{
		if (char >= 65 && char <= 90)
			string += "_" + (char + 32).tochar();
		else
			string += char.tochar();
	}
	if (!::Hooks.hasMod(string))
		::Hooks.register(string, "1.0.0", ::Hooks.__getCachedNameForID(string));
}

::Hooks.__Mod <- ::Hooks.register(::Hooks.ID, ::Hooks.Version, ::Hooks.Name);
::Hooks.__Mod.queue(function (){
	foreach (file in ::IO.enumerateFiles("modern_hooks/hooks/last"))
		::include(file);
}, ::Hooks.QueueBucket.Last);

::Hooks.__Mod.queue(">mod_msu", function() {
	try
	{
		if (::Hooks.hasMod("mod_msu"))
		{
			local msu_mod = ::MSU.Class.Mod(::Hooks.ID, ::Hooks.Version, ::Hooks.Name);
			msu_mod.Registry.addModSource(::MSU.System.Registry.ModSourceDomain.GitHub, "https://github.com/MSUTeam/Modern-Hooks");
			msu_mod.Registry.setUpdateSource(::MSU.System.Registry.ModSourceDomain.GitHub);
			msu_mod.Registry.addModSource(::MSU.System.Registry.ModSourceDomain.NexusMods, "https://www.nexusmods.com/battlebrothers/mods/685");
		}
	}
	catch (error)
	{
		::logError("Something went wrong when trying to use MSU's update checker in modern hooks: " + error);
	}


	::Hooks.__Mod.hook("scripts/items/weapons/knife", function(q) {
		q.m.NewField <- 5;

		q.m.NewField = 6;

		q.getID = @(__original) function()
		{
			::logInfo("first hook");
			return __original();
		}

		q.getID = @(__original) function()
		{
			::logInfo("second hook")
			return __original();
		}

		q.MH_snipe("getID", 0);
	});
});

::Hooks.__Mod.queue(function() {
	local knife = ::new("scripts/items/weapons/knife");
	::logInfo(knife.getID());
	::logInfo(knife.m.NewField);
}, ::Hooks.QueueBucket.AfterHooks);
