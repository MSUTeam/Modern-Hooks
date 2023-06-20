::Hooks.getNameForQueueBucket <- function( _queueBucketID )
{
	foreach (key, val in ::Hooks.QueueBucket)
	{
		if (_queueBucketID == val)
			return key;
	}
}


::Hooks.__validateModCompatibility <- function()
{
	local compatErrors = [];
	foreach (mod in this.getMods())
	{
		foreach (compatibilityData in mod.getCompatibilityData())
		{
			local result = compatibilityData.validate(this.getMods());
			if (result == ::Hooks.CompatibilityCheckResult.Success)
				continue;
			compatErrors.push({
				Source = mod,
				Target = compatibilityData,
				Reason = result
			});
		}
	}
	if (compatErrors.len() == 0)
		return true;
	foreach (error in compatErrors)
	{
		switch (error.Reason)
		{
			case ::Hooks.CompatibilityCheckResult.ModMissing:
				local name = error.Target.getModID() in ::Hooks.CachedModNames ? ::Hooks.CachedModNames[error.Target.getModID()] : error.Target.getModName();
				this.__error(format("%s (%s) requires %s (%s)", error.Source.getID(), error.Source.getName(), error.Target.getModID(), name));
				break;
			case ::Hooks.CompatibilityCheckResult.ModPresent:
				local mod = ::Hooks.getMod(error.Target.getModID());
				this.__error(format("%s (%s) is incompatible with %s (%s)", error.Source.getID(), error.Source.getName(), mod.getID(), mod.getName()));
				break;
			case ::Hooks.CompatibilityCheckResult.TooSmall:
				local mod = ::Hooks.getMod(error.Target.getModID());
				this.__error(format("%s (%s) version %s is outdated for %s (%s), which requires versions %s", mod.getID(), mod.getName(), mod.getVersionString(), error.Source.getID(), error.Source.getName(), error.Target.getErrorString()))
				break;
			case ::Hooks.CompatibilityCheckResult.TooBig:
				local mod = ::Hooks.getMod(error.Target.getModID());
				this.__error(format("%s (%s) version %s is too new for %s (%s), which requires versions %s", mod.getID(), mod.getName(), mod.getVersionString(), error.Source.getID(), error.Source.getName(), error.Target.getErrorString()))
				break;
			case ::Hooks.CompatibilityCheckResult.Incorrect:
				local mod = ::Hooks.getMod(error.Target.getModID());
				this.__error(format("%s (%s) version %s is wrong for %s (%s), which requires (a) version %s", mod.getID(), mod.getName(), mod.getVersionString(), error.Source.getID(), error.Source.getName(), error.Target.getErrorString()))
				break;
		}
	}
	this.__errorAndQuit("Errors occured when validating mod compatibility, the game was therefore not loaded correctly");
	return false;
}

::Hooks.__sortQueue <- function( _queuedFunctions )
{
	local graph = ::Hooks.QueueGraph();
	foreach (func in _queuedFunctions)
	{
		foreach (before, table in func.getLoadBefore())
			graph.addEdge(before + "_end", func);
		foreach (after, table in func.getLoadAfter())
			graph.addEdge(func, after + "_start");
		graph.addEdge(func.getModID() + "_start", func)
		graph.addEdge(func, func.getModID() + "_end")
	};
	local sortedNodes = graph.topologicalSort();
	return sortedNodes.filter(@(_i, _e) _e instanceof ::Hooks.QueuedFunction);
}

::Hooks.__executeQueuedFunctions <- function( _queuedFunctions )
{
	foreach (queued::Hooks.in <- function _queuedFunctions)
	{
		local mod = queuedFunction.getMod();
		local versionString = typeof mod.getVersion() == "float" ? mod.getVersion().tostring() : mod.getVersion().getVersionString();
		this.__inform(format("Executing queued function [emph]%i[/emph] for [emph]%s[/emph] (%s) version %s.", queuedFunction.getFunctionID(), mod.getName(), mod.getID(), versionString));
		queuedFunction.getFunction()();
	}
}

::Hooks.__runQueue <- function()
{
	if (!this.__validateModCompatibility())
		return;

	local buckets = {}; // I hate how I've had to do these buckets without MSU enums
	foreach (mod in this.getMods())
	{
		foreach (func in mod.getQueuedFunctions())
		{
			if (!(func.getBucket() in buckets))
				buckets[func.getBucket()] <- [];
			buckets[func.getBucket()].push(func);
		}
	}
	local bucketTypes = [];
	foreach (bucketType in ::Hooks.QueueBucket)
		bucketTypes.push(bucketType);
	bucketTypes.sort();
	foreach (bucketType in bucketTypes)
	{
		if (!(bucketType in buckets))
			continue;
		local funcs = this.__sortQueue(buckets[bucketType]);
		::Hooks.__inform(format("-----------------Running queue bucket [emph]%s[/emph]-----------------", ::Hooks.getNameForQueueBucket(bucketType)));
		this.__executeQueuedFunctions(funcs);
	}
}

::Hooks.__processClass <- function( _src, _prototype )
{
	if (this.DebugMode)
	{
		if (!(_src in this.Classes))
			this.__initClass(_src);
		this.Classes[_src].Prototype <- _prototype;
	}
	if (!(_src in this.Classes)) // this
		return;
	this.__processHooks(_prototype, this.Classes[_src].RawHooks.Hooks);
	this.__registerForAncestorLeafHooks(_prototype, _src); // needs adjsutment, relies on debugmode rn
	this.Classes[_src].Processed = true;
}

::Hooks.__initClass <- function( _src )
{
	if (_src in this.Classes)
		return;
	this.Classes[_src] <- {
		RawHooks = {
			Hooks = [], // maybe add some metadata to each hook?
		},
		LeafHooks = {
			Hooks = [],
			Descendants = [],
		},
		Processed = false
	}
}

::Hooks.__processHooks <- function( _prototype, _hooks )
{
	foreach (hook in _hooks)
		hook(_prototype);
}

::Hooks.__registerForAncestorLeafHooks <- function( _prototype, _src )
{
	local src = _src;
	local p = _prototype;
	do
	{
		if (src in this.Classes && this.Classes[src].LeafHooks.Hooks.len() != 0)
			this.Classes[src].LeafHooks.Descendants.push(_prototype);
	}
	while ("SuperName" in p && (p = p[p.SuperName]) && (src = ::IO.scriptFilenameByHash(p.ClassNameHash)))
}

::Hooks.__getAddNewFunctionsHook <- function( _modID, _src, _newFunctions )
{
	return function(_prototype)
	{
		foreach (key, func in _newFunctions)
		{
			local p = _prototype;
			do
			{
				if (!(key in p))
					continue;
				this.__warn(format("%s is adding a new function %s to %s, but that ::Hooks.already <- function exists in %s, which is either the class itself or an ancestor", _modID, key, _src, p == _prototype ? _src : ::IO.scriptFilenameByHash(p.ClassNameHash)));
				break;
			}
			while ("SuperName" in p && (p = p[p.SuperName]))
			_prototype[key] <- func;
		}
	};
}

::Hooks.__getFunctionWrappersHook <- function( _modID, _src, _funcWrappers)
{
	return function(_prototype)
	{
		foreach (funcName, funcWrapper in _funcWrappers)
		{
			local originalFunction = null;
			local ancestorCounter = 0;
			local p = _prototype;
			do
			{
				if (!(funcName in p))
				{
					++ancestorCounter;
					continue;
				}
				originalFunction = p[funcName];
				break;
			}
			while ("SuperName" in p && (p = p[p.SuperName]))
			if (ancestorCounter > 1 && originalFunction != null) // patch to fix weirdness with grandparent or greater level inheritance described here https://discord.com/channels/965324395851694140/1052648104815513670
			{
				local funcNameCache = funcName;
				originalFunction = function(...) {
					vargv.insert(0, this);
					return this[_prototype.SuperName][funcNameCache].acall(vargv);
				}
			}

			if (originalFunction == null)
			{
				local src = "ClassNameHash" in _prototype ? ::IO.scriptFilenameByHash(_prototype.ClassNameHash) : _src;
				this.__warn(format("Mod %s failed to wrap function %s in bb class %s: there is no ::Hooks.to <- function wrap in the class or any of its ancestors", _modID,  funcName, src));
				// should we instead pass a `@(...)null`? this would allow mods to use this with each others functions, but they'd have to handle nulls returns... not sure which approach is best
				continue;
			}
			_prototype[funcName] <- funcWrapper(originalFunction);
		}
	}
}

::Hooks.__getAddFieldsHook <- function( _modID, _src, _fieldsToAdd )
{
	return function(_prototype)
	{
		foreach (fieldName, value in _prototype)
		{
			local p = _prototype;
			do
			{
				if (!(fieldName in p.m))
					continue;
				this.__warn(format("Mod %s is adding a new field %s to bb class %s, but that field already exists in %s which is either the class itself or an ancestor", _modID, fieldName, _src, p == _prototype ? _src : ::IO.scriptFilenameByHash(p.ClassNameHash)))
				break;
			}
			while ("SuperName" in p && (p = p[p.SuperName]))
			_prototype.m[fieldName] <- value;
		}
	}
}

::Hooks.__getSetFieldsHook <- function( _modID, _src, _fieldsToSet )
{
	return function(_prototype)
	{
		foreach (key, value in _fieldsToSet)
		{
			local fieldTable = null;
			local p = _prototype;
			do
			{
				if (!(key in p.m))
					continue;
				fieldTable = p.m;
				break;
			}
			while ("SuperName" in p && (p = p[p.SuperName]))
			if (fieldTable == null)
			{
				this.__warn(format("Mod %s tried to set field %s in bb class %s, but the file doesn't exist in the class or any of its ancestors", _modID, key, _src));
				continue;
			}
			fieldTable[key] = value;
		}
	}
}

::Hooks.__finalizeLeafHooks <- function()
{
	foreach (src, bbclass in this.Classes)
	{
		foreach (prototype in bbclass.LeafHooks.Descendants)
			foreach (hook in bbclass.LeafHooks.Hooks)
				hook(prototype);
		if (!bbclass.Processed)
		{
			this.__error(format("%s was never proceessed for hooks", src));
		}
	}
}

::Hooks.__debughook <- function( _eventType, _src, _line, _funcName )
{
	if (_eventType == 'r' && _funcName == "main")
	{
		try
		{
			// fix path
			_src = ::String.replace(_src.slice(0, -4), "\\", "/");
			local i = -8;
			for (local j; (j = _src.find("scripts/", i+8)) != null; i = j) { }
			if (i > 0) _src = _src.slice(i);

			// check if bb class
			local className = split(_src, "/").pop();
			local fileScope = ::getstackinfos(2).locals["this"];
			if (!(className in fileScope))
				return;

			// actually run hooks
			this.__processClass(_src, fileScope[className]);
		}
		catch (error)
		{
			this.__error(error);
		}
	}
}

::Hooks.__errorAndThrow <- function( _text )
{
	if ("MSU" in this.getroottable())
		::MSU.Popup.showRawText(_text);
	throw _text;
}

::Hooks.__errorAndQuit <- function( _text )
{
	::logError(_text);
	if ("MSU" in this.getroottable())
		::MSU.Popup.showRawText(_text, true);
}

::Hooks.__error <- function(_text)
{
	::logError(_text);
	if ("MSU" in this.getroottable())
		::MSU.Popup.showRawText(_text);
}

::Hooks.__warn <- function( _text )
{
	::logWarning(_text);
	if (this.DebugMode && "MSU" in this.getroottable())
		::MSU.Popup.showRawText(_text);
}

::Hooks.__inform <- function( _text )
{
	_text = ::String.replace(_text, "[emph]", "<span style=\"color:#FFFFFF\">")
	_text = ::String.replace(_text, "[/emph]", "</span>")
	::logInfo("<span style=\"color:#9932CC;\">" + _text + "</span>");
}
