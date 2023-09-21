local versionArray = split(::GameInfo.getVersionNumber(), ".");
local preRelease = versionArray.pop();
local version = versionArray.reduce(@(_a, _b) _a + "." + _b) + "-" + preRelease;
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
	::Hooks.register(string, "1.0.0", ::Hooks.__getCachedNameForID(string));
}

::Hooks.__Mod <- ::Hooks.register(::Hooks.ID, ::Hooks.Version, ::Hooks.Name);
::Hooks.__Mod.queue(function (){
	::include("modern_hooks/hooks/main_menu_state");
	::include("modern_hooks/hooks/root_state");
}, ::Hooks.QueueBucket.Last);

::Hooks.__Mod.queue(function() {
	::include("modern_hooks/hooks/world_state");
})
