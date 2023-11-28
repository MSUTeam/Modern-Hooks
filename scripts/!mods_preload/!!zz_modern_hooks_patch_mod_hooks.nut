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

::mods_queue = function( codeName, _expr, func )
{
	if (codeName == null)
		codeName = lastRegistered;
	if (!::Hooks.hasMod(codeName))
		::Hooks.errorAndThrow(format("Mod %s is trying to queue without registering first", codeName));
	local mod = ::Hooks.getMod(codeName);
	local exprStrings = (_expr == "" || _expr == null) ? [] : split(_expr, ",");
	local expr = [];
	foreach (rawExprString in exprStrings)
	{
		local exprString = strip(rawExprString);
		local expression = {
			op = null,
			modName = null,
			verOp = null,
			version = null
		};
		// this stuff is a pain because of how buggy regexp is
		local capture = ::Hooks.__OldHooksRequirementOperatorRegex.capture(exprString);
		if (capture == null)
			expression.op = null;
		else
		{
			expression.op = ::Hooks.__msu_regexMatch(capture, exprString, 0);
			exprString = strip(exprString.slice(capture[0].end - capture[0].begin));
		}

		capture = ::Hooks.__ModIDRegex.capture(exprString);
		if (capture == null)
			::Hooks.errorAndThrow(format("Queue information %s wasn't formatted correctly by mod %s (%s): error at %s", _expr, mod.getID(), mod.getName(), rawExprString));
		else
		{
			expression.modName = ::Hooks.__msu_regexMatch(capture, exprString, 0);
			exprString = strip(exprString.slice(capture[0].end - capture[0].begin));
		}

		capture = ::Hooks.__OldHooksOperatorAndVersionRegex.capture(exprString);
		if (capture != null)
		{
			expression.verOp = ::Hooks.__msu_regexMatch(capture, exprString, 1);
			expression.version = ::Hooks.__msu_regexMatch(capture, exprString, 2);
			exprString = strip(exprString.slice(capture[0].end - capture[0].begin));
		}

		if (exprString.len() != 0)
			::Hooks.errorAndThrow(format("Queue information %s wasn't formatted correctly by mod %s (%s): error at %s", _expr, mod.getID(), mod.getName(), rawExprString));
		if ((expression.op == '>' || expression.op == '<') && expression.verOp != null)
		{
			expr.push({
				op = expression.op,
				modName = expression.modName,
				verOp = null,
				version = null,
			});
			expr.push({
				op = null,
				modName = expression.modName,
				verOp = expression.verOp,
				version = expression.version
			});
		}
		else
			expr.push(expression);
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
		local expressionInfo = expression.modName;
		if (expression.verOp != null)
			expressionInfo += format(" %s %s",expression.verOp.tostring(), expression.version);
		local invert = false;
		local requirement = null;
		switch (expression.op)
		{
			case null:
				requirement = true;
				compatibilityData.Require.push(expressionInfo);
				loadOrderData.push(">" + expression.modName);
				break;
			case '!':
				requirement = false;
				compatibilityData.ConflictWith.push(expressionInfo);
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
	mod.require.acall(compatibilityData.Require);
	mod.conflictWith.acall(compatibilityData.ConflictWith);
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
