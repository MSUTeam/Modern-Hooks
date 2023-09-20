if (!("mods_hookExactClass" in this.getroottable()))
	return;
::Hooks.__inform("=================Patching Modding Script Hooks=================")
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

::mods_queue = function( codeName, expr, func )
{
	if (codeName == null)
		codeName = lastRegistered;
	if (!::Hooks.hasMod(codeName))
		::Hooks.__errorAndThrow(format("Mod %s is trying to queue without registering first", codeName));

	// parse expression using mod_hooks function
	local match = function(s,m,i) {
		return m[i].end > 0 && m[i].begin < s.len() ? s.slice(m[i].begin, m[i].end) : null
	};
	if (expr == "" || expr == null)
		expr = []
	else
		expr = split(expr, ",");
	for(local i = 0; i < expr.len(); ++i)
	{
		local e = strip(expr[i]), m = g_exprRe.capture(e);
		if (m == null)
			throw "Invalid queue expression '" + e + "'.";
		expr[i] = { op = m[1].end != 0 ? e[0] : null, modName = match(e, m, 2), verOp = match(e, m, 3), version = match(e, m, 4) };
	}

	local mod = ::Hooks.getMod(codeName);
	local compatibilityData = {
		Require = [mod],
		ConflictWith = [mod]
	};
	local loadOrderData = [mod];
	// now convert into modern_hooks
	foreach (expression in expr)
	{
		local invert = false;
		local requirement = null;
		switch (expression.op)
		{
			case null:
				requirement = true;
				compatibilityData.Require.push(expression.modName);
				loadOrderData.push(">" + expression.modName);
				break;
			case '!':
				requirement = false;
				compatibilityData.ConflictWith.push(expression.modName);
				break;
			case '<':
				invert = true;
				loadOrderData.push("<" + expression.modName);
				break;
			case '>':
				invert = true;
				loadOrderData.push(">" + expression.modName);
				break;
		}
		if (expression.version == null)
			continue;
		if (invert)
		{
			compatibilityData.ConflictWith.push(expression.modName);
			requirement = false;
			expression.verOp = inverter(expression.verOp)
		}
		local currentArray = compatibilityData[requirement ? "Require" : "ConflictWith"];
		local currentMod = currentArray[currentArray.len()-1];
		if (expression.verOp == null)
			expression.verOp = "=";
		currentMod += " " + expression.verOp + " " + expression.version;
	}
	mod.requires.acall(compatibilityData.Require);
	mod.conflictsWith.acall(compatibilityData.ConflictWith);
	loadOrderData.push(func);
	mod.queue.acall(loadOrderData);
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
