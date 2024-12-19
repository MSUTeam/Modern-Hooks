if (!("mods_hookExactClass" in this.getroottable()))
	return;
::Hooks.inform("=================Patching Modding Script Hooks=================")
::mods_hookExactClass = function( name, func )
{
	::Hooks.__rawHook(::Hooks.getMod("mod_hooks"), "scripts/" + name, func);
}

local lastRegistered = null;
::mods_registerMod = function( codeName, version, friendlyName = null, extra = null )
{
	lastRegistered = codeName;
	::Hooks.__unverifiedRegister(codeName, version, friendlyName == null ? codeName : friendlyName, extra);
}

::mods_registerJS = function( path ) {
	::Hooks.registerLateJS("ui/mods/" + path);
}

::mods_registerCSS = function( path ) {
	::Hooks.registerCSS("ui/mods/" + path);
}

foreach (mod in ::mods_getRegisteredMods())
{
	local meta = clone mod;
	delete meta.Name;
	delete meta.Version;
	delete meta.FriendlyName;
	::mods_registerMod(mod.Name, mod.Version, mod.FriendlyName, meta);
}

local g_exprRe = regexp("^([!<>])?(\\w+)(?:\\(([<>]=?|=|!=)?([\\w\\.\\+\\-]+)\\))?$");
local function inverter(_operator)
{
	switch (_operator)
	{
		case "=":
		case null:
			return "!";
		case "!":
			return "=";
		case ">=":
			return "<";
		case ">":
			return "<=";
		case "<=":
			return ">";
		case "<":
			return ">=";
	}
}

::mods_queue = function( _modID, _rawExpression, _function )
{
	if (_modID == null)
		_modID = lastRegistered;
	if (!::Hooks.hasMod(_modID))
		::Hooks.errorAndThrow(format("Mod %s is trying to queue without registering first", _modID));
	::Hooks.__executeOldHooksExpressions(::Hooks.getMod(_modID), _rawExpression, _function);
}

::mods_getRegisteredMod = function( _modID )
{
	if (!::Hooks.hasMod(_modID))
		return null;

	local mod = ::Hooks.getMod(_modID);
	local meta = clone mod.getMetaData();
	meta.Name <- mod.getID();
	if (typeof mod.getVersion() == "float")
	{
		meta.Version <- mod.getVersion();
	}
	else
	{
		meta.Version <- 2147483647;
		if ("MSU" in this.getroottable()) // patch for old MSU, might remove later
		{
			meta.SemVer <- ::MSU.SemVer.getTable(mod.getVersionString());
		}
	}
	meta.FriendlyName <- mod.getName();
	return meta;
}

::mods_getRegisteredMods = function()
{
	local mods = [];
	foreach (mod in ::Hooks.getMods())
	{
		mods.push(::mods_getRegisteredMod(mod.getID()));
	}
	return mods;
}

::_mods_runQueue = @()null; // fix syntax highlighter bug here
