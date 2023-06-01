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
	}
	JSFiles = [],
	CSSFiles = [],
	RootState = null,
	MainMenuState = null,
	DebugMode = true

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

	function wrapFunctions( _modID, _src, _funcWrappers )
	{
		this.rawHook(_modID, _src, this.__getFunctionWrappersHook(_modID, _src, _funcWrappers));
	}

	function wrapLeafFunctions( _modID, _src, _funcWrappers )
	{
		this.rawLeafHook(_modID, _src, this.__getFunctionWrappersHook(_modID, _src, _funcWrappers));
	}

	function setFields( _modID, _src, _fieldsToSet )
	{
		this.rawHook(_modID, _src, this.__getSetFieldsHook(_modID, _src, _fieldsToSet));
	}

	function setLeafFields( _modID, _src, _fieldsToSet )
	{
		this.rawLeafHook(_modID, _src, this.__getSetFieldsHook(_modID, _src, _fieldsToSet));
	}

	function addNewFunctions( _modID, _src, _newFunctions )
	{
		this.rawHook(_modID, _src, this.__getAddNewFunctionsHook( _modID, _src, _newFunctions))
	}

	function addNewLeafFunctions( _modID, _src, _newFunctions )
	{
		this.rawLeafHook(_modID, _src, this.__getAddNewFunctionsHook( _modID, _src, _newFunctions))
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

	function __getSetFieldsHook( _modID, _src, _fieldsToSet )
	{
		return function(_prototype)
		{
			foreach (key, value in _fieldsToSet)
			{
				local fieldTable = _prototype.m;
				for (local p = _prototype; "SuperName" in p; p = p[p.SuperName])
				{
					if (!(key in p.m))
						continue;
					fieldTable = p.m;
					break;
				}
				fieldTable[key] <- value;
			}
		}
	}

	function __getAddNewFunctionsHook( _modID, _src, _newFunctions )
	{
		return function(prototype)
		{
			foreach (key, func in _newFunctions)
			{
				for (local p = prototype; "SuperName" in p; p = p[p.SuperName])
				{
					if (!(key in p))
						continue;
					this.__warn(format("%s is adding a new function %s to %s, but that function already exists in %s, which is either the class itself or an ancestor", _modID,  key, _src, p == prototype ? _src : ::IO.scriptFilenameByHash(p.ClassNameHash)));
					break;
				}
				prototype[key] <- func;
			}
		};
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

	function __error(_text)
	{
		if ("MSU" in this.getroottable())
			::MSU.Popup.showRawText(_text);
		::logError(_text);
	}

	function __warn( _text )
	{
		if (this.DebugMode && "MSU" in this.getroottable())
			::MSU.Popup.showRawText(_text);
		::logWarning(_text);
	}

	function __inform( _text )
	{
		// if ("MSU" in this.getroottable())
		// 	::MSU.Popup.showRawText(_text);
		::logInfo(_text);
	}
}
::logInfo("=================Initialized Hooks=================");

::setdebughook(::Hooks.__debughook.bindenv(::Hooks));

foreach (file in ::IO.enumerateFiles("modern_hooks/hooks")) // these should run after !mods_preload
{
	::include(file);
}
