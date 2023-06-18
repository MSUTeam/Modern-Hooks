::Hooks <- {
	Classes = {
		/*"path/to/file" : {
			RawHooks = {
				Hooks = []
			},
			LeafHooks = {
				Hooks = [],
				Descendants = []
			},
		}*/
	},
	Mods = {},
	JSFiles = [],
	CSSFiles = [],
	RootState = null,
	MainMenuState = null,
	DebugMode = true,
	__SemVerRegex = regexp("^((?:(?:0|[1-9]\\d*)\\.){2}(?:0|[1-9]\\d*))(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$"),
	__VersionOperatorRegex = regexp("^((?:!|=|<|>)?=?)"),
	function register( _modID, _version, _modName, _metaData = null )
	{
		if (_metaData == null)
			_metaData = {};
		if (_modID in this.Mods)
		{
			this.__errorAndThrow(format("Mod %s (%s) version %s is trying to register twice", _modID, _modName, _version.tostring()))
		}
		this.Mods[_modID] <- ::Hooks.Mod(_modID, _version, _modName, _metaData);
		return this.Mods[_modID];
	}

	function getMods()
	{
		return this.Mods;
	}

	function isModRegistered( _modID )
	{
		return _modID in this.Mods;
	}

	function getRegisteredMod( _modID )
	{
		return this.Mods[_modID];
	}

	function __validateModCompatibility()
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
					Target = compatibilityData.getModID(),
					Reason = result
				});
			}
		}
		if (compatErrors.len() == 0)
			return;
		foreach (error in compatErrors)
		{
			::MSU.Log.printData(error)
			this.__error(format("Source: %s, Target: %s, Reason: %i", error.Source.getID(), error.Target, error.Reason)) // for now
		}
		this.__errorAndThrow("Errors occured when validating mod compatibility, the game was therefore not loaded correctly");
	}

	function __sortQueue( _queuedFunctions )
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

	function __executeQueuedFunctions( _queuedFunctions )
	{
		foreach (queuedFunction in _queuedFunctions)
		{
			local mod = queuedFunction.getMod();
			local versionString = typeof mod.getVersion() == "float" ? mod.getVersion().tostring() : mod.getVersion().getVersionString();
			this.__inform(format("Executing queued function %i for %s (%s) version %s.", queuedFunction.getFunctionID(), mod.getID(), mod.getName(), versionString));
			queuedFunction.getFunction()();
		}
	}

	function __runQueue()
	{
		this.__validateModCompatibility();
		// Adapted from mod_hooks with Adam's permission

		local buckets = {}; // I hate how I've had to do these buckets with MSU enums
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
			::Hooks.__inform(format("Running queue bucket %s", ::Hooks.getNameForQueueBucket(bucketType)));
			this.__executeQueuedFunctions(funcs);
		}
	}

	function hasMod( _modID )
	{
		return _modID in this.Mods;
	}

	function getMod( _modID )
	{
		return this.Mods[_modID];
	}

	function rawHook( _modID, _src, _rawHook ) // _modID gets ignored for now ig
	{
		this.__initClass(_src);
		this.Classes[_src].RawHooks.Hooks.push(_rawHook);
	}

	function rawLeafHook( _modID, _src, _rawLeafHook ) // _modID gets ignored for now ig
	{
		this.__initClass(_src);
		this.Classes[_src].LeafHooks.Hooks.push(_rawLeafHook);
	}

	function registerJS( _filePath )
	{
		if (typeof _filePath != "string" || _filePath.slice(0,3) != "ui/")
		{
			this.__error("registerJS requires a file path starting with ui/");
			return;
		}
		this.JSFiles.push(_filePath);
	}

	function registerCSS( _filePath )
	{
		if (typeof _filePath != "string" || _filePath.slice(0,3) != "ui/")
		{
			this.__error("registerCSS requires a file path starting with ui/");
			return;
		}
		this.CSSFiles.push(_filePath);
	}

	function addNewFunctions( _modID, _src, _newFunctions )
	{
		this.rawHook(_modID, _src, this.__getAddNewFunctionsHook( _modID, _src, _newFunctions))
	}

	function addNewLeafFunctions( _modID, _src, _newFunctions )
	{
		this.rawLeafHook(_modID, _src, this.__getAddNewFunctionsHook( _modID, _src, _newFunctions))
	}

	function wrapFunctions( _modID, _src, _funcWrappers )
	{
		this.rawHook(_modID, _src, this.__getFunctionWrappersHook(_modID, _src, _funcWrappers));
	}

	function wrapLeafFunctions( _modID, _src, _funcWrappers )
	{
		this.rawLeafHook(_modID, _src, this.__getFunctionWrappersHook(_modID, _src, _funcWrappers));
	}

	function addFields( _modID, _src, _fieldsToAdd )
	{
		this.rawHook(_modID, _src, this.__getAddFieldsHook(_modID, _src, _fieldsToAdd));
	}

	function addLeafFields( _modID, _src, _fieldsToAdd )
	{
		this.rawLeafHook(_modID, _src, this.__getAddFieldsHook(_modID, _src, _fieldsToSet));
	}

	function setFields( _modID, _src, _fieldsToSet )
	{
		this.rawHook(_modID, _src, this.__getSetFieldsHook(_modID, _src, _fieldsToSet));
	}

	function setLeafFields( _modID, _src, _fieldsToSet )
	{
		this.rawLeafHook(_modID, _src, this.__getSetFieldsHook(_modID, _src, _fieldsToSet));
	}

	function __processClass( _src, _prototype )
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
		this.__registerForAncestorLeafHooks(_prototype); // needs adjsutment, relies on debugmode rn
		this.Classes[_src].Processed = true;
	}

	function __initClass( _src )
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

	function __processHooks( _prototype, _hooks )
	{
		foreach (hook in _hooks)
			hook(_prototype);
	}

	function __registerForAncestorLeafHooks( _prototype )
	{
		if (!("SuperName" in _prototype))
			return;
		for (local p = _prototype[_prototype.SuperName]; "SuperName" in p; p = p[p.SuperName])
		{
			local parentsrc = ::IO.scriptFilenameByHash(p.ClassNameHash);
			if (parentsrc in this.Classes && this.Classes[parentsrc].LeafHooks.Hooks.len() != 0)
				this.Classes[parentsrc].LeafHooks.Descendants.push(_prototype);
		}
	}

	function __getAddNewFunctionsHook( _modID, _src, _newFunctions )
	{
		return function(_prototype)
		{
			foreach (key, func in _newFunctions)
			{
				for (local p = _prototype; "SuperName" in p; p = p[p.SuperName])
				{
					if (!(key in p))
						continue;
					this.__warn(format("%s is adding a new function %s to %s, but that function already exists in %s, which is either the class itself or an ancestor", _modID, key, _src, p == _prototype ? _src : ::IO.scriptFilenameByHash(p.ClassNameHash)));
					break;
				}
				_prototype[key] <- func;
			}
		};
	}

	function __getFunctionWrappersHook( _modID, _src, _funcWrappers)
	{
		return function(_prototype)
		{
			foreach (funcName, funcWrapper in _funcWrappers)
			{
				local originalFunction = null;
				local ancestorCounter = 0;
				for (local p = _prototype; "SuperName" in p; p = p[p.SuperName])
				{
					if (!(funcName in p))
					{
						++ancestorCounter;
						continue;
					}
					originalFunction = p[funcName];
					break;
				}
				if (ancestorCounter > 1 && originalFunction != null) // patch to fix weirdness with grandparent or greater level inheritance described here https://discord.com/channels/965324395851694140/1052648104815513670
				{
					originalFunction = function(...) {
						vargv.insert(0, this);
						return this[_prototype.SuperName][funcName].acall(vargv);
					}
				}

				if (originalFunction == null)
				{
					this.__warn(format("Mod %s failed to wrap function %s in bb class %s: there is no function to wrap in the class or any of its ancestors", _modID,  funcName, _src));
					// should we instead pass a `@(...)null`? this would allow mods to use this with each others functions, but they'd have to handle nulls returns... not sure which approach is best
					continue;
				}
				_prototype[funcName] <- funcWrapper(originalFunction);
			}
		}
	}

	function __getAddFieldsHook( _modID, _src, _fieldsToAdd )
	{
		return function(_prototype)
		{
			foreach (fieldName, value in _prototype)
			{
				for (local p = _prototype; "SuperName" in p; p = p[p.SuperName])
				{
					if (!(fieldName in p.m))
						continue;
					this.__warn(format("Mod %s is adding a new field %s to bb class %s, but that field already exists in %s which is either the class itself or an ancestor", _modID, fieldName, _src, p == _prototype ? _src : ::IO.scriptFilenameByHash(p.ClassNameHash)))
					break;
				}
				_prototype.m[fieldName] <- value;
			}
		}
	}

	function __getSetFieldsHook( _modID, _src, _fieldsToSet )
	{
		return function(_prototype)
		{
			foreach (key, value in _fieldsToSet)
			{
				local fieldTable = null;
				for (local p = _prototype; "SuperName" in p; p = p[p.SuperName])
				{
					if (!(key in p.m))
						continue;
					fieldTable = p.m;
					break;
				}
				if (fieldTable == null)
				{
					this.__warn(format("Mod %s tried to set field %s in bb class %s, but the file doesn't exist in the class or any of its ancestors", _modID, key, _src));
					continue;
				}
				fieldTable[key] = value;
			}
		}
	}

	function __finalizeLeafHooks()
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

	function __debughook( _eventType, _src, _line, _funcName )
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

	function __errorAndThrow( _text )
	{
		if ("MSU" in this.getroottable())
			::MSU.Popup.showRawText(_text);
		throw _text;
	}

	function __error(_text)
	{
		::logError(_text);
		if ("MSU" in this.getroottable())
			::MSU.Popup.showRawText(_text);
	}

	function __warn( _text )
	{
		::logWarning(_text);
		if (this.DebugMode && "MSU" in this.getroottable())
			::MSU.Popup.showRawText(_text);
	}

	function __inform( _text )
	{
		// if ("MSU" in this.getroottable())
		// 	::MSU.Popup.showRawText(_text);
		::logInfo(_text);
	}
}
// init semver regexes

::logInfo("=================Initialized Hooks=================");
foreach (file in ::IO.enumerateFiles("modern_hooks/queue"))
	::include(file);

::setdebughook(::Hooks.__debughook.bindenv(::Hooks));
