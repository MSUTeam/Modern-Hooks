if (!("mods_hookExactClass" in this.getroottable()))
	return;
::Hooks.__inform("=================Patching Modding Script Hooks=================")
::mods_hookExactClass = function( name, func )
{
	::Hooks.rawHook("mod_hooks", "scripts/" + name, func)
}

local lastRegistered = null;
::mods_registerMod = function( codeName, version, friendlyName = null, extra = null )
{
	lastRegistered = codeName;
	::Hooks.register(codeName, version, friendlyName == null ? codeName : friendlyName, extra);
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
		Requirements = {},
		Incompatibilities = {}
	};
	local loadOrderData = {
		After = [],
		Before = []
	}
	// now convert into modern_hooks
	foreach (expression in expr)
	{
		local invert = false;
		local requirement = null;
		switch (expression.op)
		{
			case null:
				requirement = true;
				compatibilityData.Requirements[expression.modName] <- {};
				loadOrderData.After.push({ID = expression.modName});
				break;
			case '!':
				requirement = false;
				compatibilityData.Incompatibilities[expression.modName] <- {};
				break;
			case '<':
				invert = true;
				loadOrderData.Before.push({ID = expression.modName});
				break;
			case '>':
				invert = true;
				loadOrderData.After.push(expression.modName); // TODO adjust to be as above, currently only this way for testing purposes
				break;
		}
		if (expression.version == null)
			continue;
		if (invert)
		{
			compatibilityData.Incompatibilities[expression.modName] <- {}
			requirement = false;
			expression.verOp = inverter(expression.verOp)
		}
		local currentMod = compatibilityData[requirement ? "Requirements" : "Incompatibilities"][expression.modName];
		if (expression.verOp == null)
			expression.verOp = "=";
		currentMod.Version <- expression.verOp + expression.version;
	}
	mod.declareCompatibilityData(compatibilityData);
	mod.queueFunction(loadOrderData, func);
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
