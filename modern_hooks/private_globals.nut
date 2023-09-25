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
	this.__registerForAncestorLeafHooks(_prototype, _src);
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
			LeafHooks = [],
			// MetaHooks = [] to do later
		};
}



::Hooks.__registerForAncestorLeafHooks <- function( _prototype, _src )
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

local q;
q = {
	__Src = null,
	__Prototype = null
	__Mod = null
	m = {}
}
local q_meta = {
	function _set( _key, _value )
	{
		local src = "ClassNameHash" in q.__Prototype ? ::IO.scriptFilenameByHash(q.__Prototype.ClassNameHash) : q.__Src;
		if (typeof _value != "function")
			::Hooks.errorAndThrow(format("todo error"));
		local wrapperParams = _value.getinfos().parameters;
		if (wrapperParams.len() != 2 || wrapperParams[1] != "__original")
			::Hooks.errorAndThrow(format("Mod %s (%s) failed to hook function %s in class %s. Use the q.<methodname> = @(__original) function (...) {...} syntax", q.__Mod.getID(), q.__Mod.getName(), _key, src));

		local originalFunction;
		local ancestorCounter = 0;
		local p = q.__Prototype;
		do
		{
			if (!(_key in p))
			{
				++ancestorCounter;
				continue;
			}
			originalFunction = p[_key];
			break;
		}
		while ("SuperName" in p && (p = p[p.SuperName]))

		if (originalFunction == null)
		{
			::Hooks.errorAndThrow(format("Mod %s (%s) failed to set function %s in bb class %s: there is no function to set in the class or any of its ancestors", q.__Mod.getID(), q.__Mod.getName(),  _key, src));
			return;
		}
		local oldInfos = originalFunction.getinfos();
		local oldParams = oldInfos.parameters;
		if (ancestorCounter > 1)
		{
			originalFunction = function(...) {
				vargv.insert(0, this);
				return this[q.__Prototype.SuperName][_key].acall(vargv);
			}
		}
		local newFunc
		try
		{
			newFunc = _value(originalFunction);
		}
		catch (error)
		{
			::Hooks.errorAndThrow(format("The overwrite attempt by mod %s (%s) for function %s in class %s failed because of error: %s", q.__Mod.getID(), q.__Mod.getName(), _key, src, error));
		}

		local newParams = newFunc.getinfos().parameters;
		if (newParams[newParams.len()-1] == "..." || oldParams[oldParams.len()-1] != "...")
		{
			// one of the functions uses vargv, do not perform validation
		}
		else if (oldInfos.native == false)
		{
			if (oldParams.len() != newParams.len())
			{
				::Hooks.warn(format("Mod %s (%s) is wrapping function %s in bb class %s with a different number of parameters (used to be %i, wrappper returned function with %i)", q.__Mod.getID(), q.__Mod.getName(), _key, src, oldParams.len()-1, newParams.len()-1))
			}
		}
		else
		{
			::Hookw.__errorAndThrow(format("Mod %s (%s) seems to be targetting a native function %s in bb class %s, which shouldn't be possible, please report this", q.__Mod.getID(), q.__Mod.getName(), _key, src))
		}

		q.__Prototype[_key] <- newFunc;
	}

	function _newslot( _key, _value )
	{
		local p = q.__Prototype;
		if (_key in p)
		{
			::Hooks.warn(format("Mod %s (%s) is adding a new function %s to %s, but that function already exists in the bb class", q.__Mod.getID(), q.__Mod.getName(), _key, q.__Src));
		}
		q.__Prototype[_key] <- _value;
	}

	function _get( _key )
	{
		// this needs special handling for ancestors (p = p[p.SuperName]) added
		// right now this will return the ancestor prototype directly
		// rather than a q wrapper for the prototype
		local value;
		local exists = false;
		local p = q.__Prototype;
		if ("SuperName" in  p && _key == p.SuperName)
			::Hooks.errorAndThrow("modern hooks currently disallows getting the parent prototype from a basic hook")
		do
		{
			if (_key in p)
			{
				value = p[_key];
				exists = true;
				break;
			}
		}
		while ("SuperName" in p && (p = p[p.SuperName]))

		if (exists)
			return value;
		throw null;
	}

	function _nexti()
	{
		// TODO
	}

	function _delslot()
	{
		// TODO
	}

	function contains( _key )
	{
		return _key in q.__Prototype;
	}
};
local m_meta = {
	function _set( _key, _value )
	{
		local fieldTable = null;
		local p = q.__Prototype;
		do
		{
			if (!(_key in p.m))
				continue;
			fieldTable = p.m;
			break;
		}
		while ("SuperName" in p && (p = p[p.SuperName]))
		if (fieldTable == null)
		{
			::Hooks.warn(format("Mod %s (%s) tried to set field %s in bb class %s, but the field doesn't exist in the class or any of its ancestors", q.__Mod.getID(), q.__Mod.getName(), _key, q.__Src));
		}
		fieldTable[_key] = _value;
	}

	function _newslot( _key, _value )
	{
		local p = q.__Prototype;
		do
		{
			if (!(_key in p.m))
				continue;
			::Hooks.warn(format("Mod %s (%s) is adding a new field %s to bb class %s, but that field already exists in %s which is either the class itself or an ancestor", q.__Mod.getID(), q.__Mod.getName(), fieldName, q.__Src, p == q.__Prototype ? q.__Src : ::IO.scriptFilenameByHash(p.ClassNameHash)))
			break;
		}
		while ("SuperName" in p && (p = p[p.SuperName]))
		q.__Prototype.m[_key] <- _value;
	}

	function _get( _key )
	{
		local value;
		local found = false;
		local p = q.__Prototype;
		do
		{
			if (!(_key in p.m))
				continue;
			found = true;
			value = p.m[_key];
			break;
		}
		while ("SuperName" in p && (p = p[p.SuperName]))
		if (!found)
			::Hooks.errorAndThrow(format("Mod %s (%s) is trying to get field %s for bb class %s, but that field doesn't exist in the class or any of its ancestors", q.__Mod.getID(), q.__Mod.getName(), _key, q.__Src));
		return value;
	}

	function _nexti()
	{
		// TODO
	}

	function _delslot()
	{
		// TODO
	}

	function contains( _key )
	{
		return _key in q.__Prototype.m;
	}
}

q.m.setdelegate(m_meta);
q.setdelegate(q_meta);

::Hooks.__rawHook <- function( _mod, _src, _func )
{
	this.__initClass(_src, _mod.getID());
	this.BBClass[_src].Mods[_mod.getID()].RawHooks.push(_func);
}

::Hooks.__hook <- function( _mod, _src, _func )
{
	::Hooks.__rawHook(_mod, _src, function(p) {
		q.__Prototype = p;
		q.__Mod = _mod;
		q.__Src = _src;
		_func(q);
	});
}

::Hooks.__rawLeafHook <- function( _mod, _src, _func )
{
	this.__initClass(_src, _mod.getID());
	this.BBClass[_src].Mods[_mod.getID()].LeafHooks.push(_func);
}

::Hooks.__leafHook <- function( _mod, _src, _func )
{
	::Hooks.__rawLeafHook(_mod, _src, function(p) {
		q.__Prototype = p;
		q.__Mod = _mod;
		q.__Src = _src;
		_func(q);
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

		// leaf hook logic
		foreach (prototype in bbclass.Descendants)
			foreach (mod in bbclass.Mods)
				foreach (hook in mod.LeafHooks)
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
