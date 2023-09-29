::Hooks.__getNameForQueueBucket <- function( _queueBucketID ) // not a fan of this function but without MSU enums this is a pain
{
	foreach (key, val in ::Hooks.QueueBucket)
	{
		if (_queueBucketID == val)
			return key;
	}
}

::Hooks.__msu_regexMatch <- function( _capture, _string, _group )
{
	return _capture[_group].end > 0 && _capture[_group].begin < _string.len() ? _string.slice(_capture[_group].begin, _capture[_group].end) : null;
}

::Hooks.__msu_SemVer_isSemVer <- function( _string )
{
	if (typeof _string != "string") return false;
	return ::Hooks.__SemVerRegex.capture(_string) != null;
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
				::Hooks.error(format("%s (%s) requires %s (%s)", error.Source.getID(), error.Source.getName(), error.Target.getModID(), name));
				break;
			case ::Hooks.CompatibilityCheckResult.ModPresent:
				local mod = ::Hooks.getMod(error.Target.getModID());
				::Hooks.error(format("%s (%s) is incompatible with %s (%s)", error.Source.getID(), error.Source.getName(), mod.getID(), mod.getName()));
				break;
			case ::Hooks.CompatibilityCheckResult.TooSmall:
				local mod = ::Hooks.getMod(error.Target.getModID());
				::Hooks.error(format("%s (%s) version %s is outdated for %s (%s), which requires versions %s", mod.getID(), mod.getName(), mod.getVersionString(), error.Source.getID(), error.Source.getName(), error.Target.getErrorString()))
				break;
			case ::Hooks.CompatibilityCheckResult.TooBig:
				local mod = ::Hooks.getMod(error.Target.getModID());
				::Hooks.error(format("%s (%s) version %s is too new for %s (%s), which requires versions %s", mod.getID(), mod.getName(), mod.getVersionString(), error.Source.getID(), error.Source.getName(), error.Target.getErrorString()))
				break;
			case ::Hooks.CompatibilityCheckResult.Incorrect:
				local mod = ::Hooks.getMod(error.Target.getModID());
				::Hooks.error(format("%s (%s) version %s is wrong for %s (%s), which requires (a) version %s", mod.getID(), mod.getName(), mod.getVersionString(), error.Source.getID(), error.Source.getName(), error.Target.getErrorString()))
				break;
		}
	}
	::Hooks.errorAndQuit("Errors occured when validating mod compatibility, the game was therefore not loaded correctly");
	return false;
}

::Hooks.__unverifiedRegister <- function( _modID, _version, _modName, _metaData = null )
{
	if (_metaData == null)
		_metaData = {};
	if (_modID in this.Mods)
	{
		::Hooks.errorAndThrow(format("Mod %s (%s) version %s is trying to register twice", _modID, _modName, _version.tostring()))
	}
	this.Mods[_modID] <- ::Hooks.SQClass.Mod(_modID, _version, _modName, _metaData);
	::Hooks.inform(format("Modern Hooks registered [emph]%s[/emph] (%s) version [emph]%s[/emph]", this.Mods[_modID].getName(), this.Mods[_modID].getID(), this.Mods[_modID].getVersion().tostring()))
	return this.Mods[_modID];
}

::Hooks.__sortQueue <- function( _queuedFunctions )
{
	local graph = ::Hooks.QueueGraph();
	foreach (func in _queuedFunctions)
	{
		foreach (modID in func.getLoadBefore())
			graph.addEdge(modID + "_end", func);
		foreach (modID in func.getLoadAfter())
			graph.addEdge(func, modID + "_start");
		graph.addEdge(func.getModID() + "_start", func)
		graph.addEdge(func, func.getModID() + "_end")
	};
	local sortedNodes = graph.topologicalSort();
	return sortedNodes.filter(@(_i, _e) _e instanceof ::Hooks.QueuedFunction);
}

::Hooks.__executeQueuedFunctions <- function( _queuedFunctions )
{
	foreach (queuedFunction in _queuedFunctions)
	{
		local mod = queuedFunction.getMod();
		local versionString = typeof mod.getVersion() == "float" ? mod.getVersion().tostring() : mod.getVersion().getVersionString();
		::Hooks.inform(format("Executing queued function [emph]%i[/emph] for [emph]%s[/emph] (%s) version %s.", queuedFunction.getFunctionID(), mod.getName(), mod.getID(), versionString));
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
	foreach (idx, bucketType in bucketTypes)
	{
		if (!(bucketType in buckets))
			continue;
		buckets[bucketType] = this.__sortQueue(buckets[bucketType]);
	}

	// by definition that bucket is handled later
	if (::Hooks.QueueBucket.AfterHooks in buckets)
	{
		::Hooks.AfterHooksBucket = buckets[::Hooks.QueueBucket.AfterHooks];
		delete buckets[::Hooks.QueueBucket.AfterHooks];
	}
	if (::Hooks.QueueBucket.FirstWorldInit in buckets)
	{
		::Hooks.FirstWorldInitBucket = buckets[::Hooks.QueueBucket.FirstWorldInit];
		delete buckets[::Hooks.QueueBucket.FirstWorldInit];
	}

	foreach (bucketType in bucketTypes)
	{
		if (!(bucketType in buckets))
			continue;
		::Hooks.inform(format("-----------------Running queue bucket [emph]%s[/emph]-----------------", ::Hooks.__getNameForQueueBucket(bucketType)));
		this.__executeQueuedFunctions(buckets[bucketType]);
	}
}

::Hooks.__runAfterHooksQueue <- function()
{
	if (::Hooks.AfterHooksBucket == null)
		return;
	::Hooks.inform(format("-----------------Running queue bucket [emph]%s[/emph]-----------------", ::Hooks.__getNameForQueueBucket(::Hooks.QueueBucket.AfterHooks)));
	this.__executeQueuedFunctions(::Hooks.AfterHooksBucket);
}

::Hooks.__registerClass <- function( _src, _prototype )
{
	this.__initClass(_src);
	this.BBClass[_src].Prototype = _prototype;
	this.__registerForAncestorTreeHooks(_prototype, _src);
}

::Hooks.__initClass <- function( _src, _modID = null )
{
	if (!(_src in this.BBClass))
		this.BBClass[_src] <- {
			Mods = {},
			Descendants = [],
			Prototype = null,
			Processed = false
		};
	if (_modID != null && !(_modID in this.BBClass[_src].Mods))
		this.BBClass[_src].Mods[_modID] <- {
			RawHooks = [],
			TreeHooks = [],
			// MetaHooks = [] to do later
		};
}



::Hooks.__registerForAncestorTreeHooks <- function( _prototype, _src )
{
	local src = _src;
	local p = _prototype;
	do
	{
		if (src in this.BBClass && this.BBClass[src].Mods.len() != 0)
			this.BBClass[src].Descendants.push(_prototype);
	}
	while ("SuperName" in p && (p = p[p.SuperName]) && (src = ::IO.scriptFilenameByHash(p.ClassNameHash)))
}

::Hooks.__getNativeFunctionWrapper <- function( _modID, _src, _funcWrappers )
{
	local hook = this.__getFunctionWrappersHook(_modID, _src, {
		function onInit( _originalFunction )
		{
			return function() {
				::Hooks.__getFunctionWrappersHook(_modID, _src, _funcWrappers)(this);
				_originalFunction();
			};
		}
	});
	return function( _prototype ) {
		// first verify that target is a tactical or world entity
		local p = _prototype;
		local src = _src;
		local notEntity = true;
		do
		{
			if (src == ::Hooks.__TacticalEntityPath || src == ::Hooks.__WorldEntityPath)
			{
				notEntity = false;
				break;
			}
		}
		while ("SuperName" in p && (p = p[p.SuperName]) && (src = ::IO.scriptFilenameByHash(p.ClassNameHash)))
		if (notEntity)
		{
			// error here because this hook won't work without an onInit function
			::Hooks.error(format("%s is using a native function wrapper on class %s which isn't a tactical or world entity", _modID, _src))
			return;
		}

		// then make sure the functions we are targetting don't exist in the BB class
		foreach (key, funcWrapper in _funcWrappers)
		{
			p = _prototype;
			src = _src;
			do
			{
				if (!(key in p))
					continue;
				// warn here because I can imagine a situation where some modder adds a function to player in a bad hook that is overwritten by C++
				::Hooks.warn(format("%s is using a native function wrapper on function %s in %s, but that function isn't a native function as it is defined in class %s, which is either the class itself or ancestor", _modID, key, _src, src));
			}
			while ("SuperName" in p && (p = p[p.SuperName]) && (src = ::IO.scriptFilenameByHash(p.ClassNameHash)))
		}
		// finally actually hook the target
		hook(_prototype);
	}
}

::Hooks.__rawHook <- function( _mod, _src, _func )
{
	this.__initClass(_src, _mod.getID());
	this.BBClass[_src].Mods[_mod.getID()].RawHooks.push(_func);
}

::Hooks.__hook <- function( _mod, _src, _func )
{
	::Hooks.__rawHook(_mod, _src, function(p) {
		::Hooks.__Q.Q.__Prototype = p;
		::Hooks.__Q.Q.__Mod = _mod;
		::Hooks.__Q.Q.__Src = _src;
		_func(::Hooks.__Q.Q);
	});
}

::Hooks.__rawHookTree <- function( _mod, _src, _func )
{
	this.__initClass(_src, _mod.getID());
	this.BBClass[_src].Mods[_mod.getID()].TreeHooks.push(_func);
}

::Hooks.__hookTree <- function( _mod, _src, _func )
{
	::Hooks.__rawHookTree(_mod, _src, function(p) {
		::Hooks.__Q.QTree.__Prototype = p;
		::Hooks.__Q.QTree.__Mod = _mod;
		::Hooks.__Q.QTree.__Src = _src;
		_func(::Hooks.__Q.QTree);
	});
}

::Hooks.__processRawHooks <- function( _src )
{
	local p = this.BBClass[_src].Prototype;
	foreach (mod in this.BBClass[_src].Mods)
		foreach (hook in mod.RawHooks)
			hook(p);
	this.BBClass[_src].Processed = true;
}

::Hooks.__finalizeHooks <- function()
{
	foreach (src, bbclass in this.BBClass)
	{
		// normal hook logic
		if (!bbclass.Processed)
		{
			if (bbclass.Prototype == null)
			{
				::Hooks.error(format("%s was never proceessed for hooks", src));
				continue;
			}
			this.__processRawHooks(src);
		}

		::Hooks.__Q.QTree.__Target = src
		// leaf hook logic
		foreach (prototype in bbclass.Descendants)
			foreach (mod in bbclass.Mods)
				foreach (hook in mod.TreeHooks)
					hook(prototype)
	}
}

::Hooks.__getCachedNameForID <- function( _id )
{
	return _id in ::Hooks.CachedModNames ? ::Hooks.CachedModNames[_id] : _id;
}

::Hooks.__debughook <- function( _eventType, _src, _line, _funcName )
{
	if (_eventType == 'r' && _funcName == "main")
	{
		// would be great if this block could be improved with something like ::seterrorhandler
		// but that doesn't seem to do anything in our squirrel build.
		// The issue right now is that the only information catch receives is the error code,
		// it doesn't get any information about where that error occured
		// this means that instead any code executed by hooks needs to use intensive validation
		// and maybe its own try/catch blocks to make it easier to identify the source of the error
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
			this.__registerClass(_src, fileScope[className]);
		}
		catch (error)
		{
			::Hooks.error(" src: " + _src + " " + error);
		}
	}
}
