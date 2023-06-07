if (!("mods_hookExactClass" in this.getroottable()))
	return;

::mods_hookExactClass = function( name, func )
{
	::Hooks.rawHook("mod_hooks_patch", "scripts/" + name, func)
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
	local match = @(s,m,i) m[i].end > 0 && m[i].begin < s.len() ? s.slice(m[i].begin, m[i].end) : null;
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
	mod.queueFunction(func);
	// now convert into modern_hooks
	foreach (expression in expr)
	{
		local invert = false;
		switch (expression.op)
		{
			case null:
				mod.require(expression.modName);
				break;
			case '!':
				mod.incompatibleWith(expression.modName);
				break;
			case '<':
				invert = true;
				mod.loadAfter(expression.modName);
				break;
			case '>':
				invert = true;
				mod.loadBefore(expression.modName);
				break;
		}
		if (expression.version == null)
			continue;
		if (invert)
		{
			mod.incompatibleWith(expression.modName);
			expression.verOp = inverter(expression.verOp)
		}

		switch (expression.verOp)
		{
			case null:
			case "=":
				mod.version(expression.version);
				break;
			case "!=":
				mod.notVersion(expression.version);
				break;
			case "<=":
				mod.maxVersion(expression.version);
				break;
			case "<":
				mod.greaterThanVersion(expression.version);
				break;
			case ">=":
				mod.minVersion(expression.version);
				break;
			case ">":
				mod.lessThanVersion(expression.version);
				break;
		}
	}
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
	if (mod.getVersion())
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
