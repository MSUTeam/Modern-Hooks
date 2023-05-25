::Hooks <- {
	Hooks = {
		//"path/to/file" : []
	},
	LeafHooks = {
		/*"path/to/file" : {
			Hooks = [],
			Descendants = []
		}*/
	},
	JSFiles = [],
	CSSFiles = [],
	RootState = null,
	MainMenuState = null

	function processObject( _src, _prototype )
	{
		if (_src in this.Hooks)
			foreach (hook in this.Hooks[_src])
				hook(_prototype);

		local prototype = _prototype;
		while ("SuperName" in prototype)
		{
			prototype = prototype[prototype.SuperName];
			local parentsrc = ::IO.scriptFilenameByHash(prototype.ClassNameHash);
			if (parentsrc in this.LeafHooks)
				this.LeafHooks[parentsrc].Descendants.push(_prototype);
		}
	}

	function finalizeLeafHooks()
	{
		foreach (table in this.LeafHooks)
		{
			foreach (prototype in table.Descendants)
				foreach (hook in table.Hooks)
					hook(prototype);
			table.Descendants.clear();
		}
	}

	function clear()
	{
		this.LeafHooks.clear();
		this.Hooks.clear();
	}

	function rawHook( _src, _rawHook )
	{
		if (!(_src in this.Hooks))
			this.Hooks[_src] <- [];
		this.Hooks[_src].push(_rawHook);
	}

	function rawLeafHook( _src, _rawLeafHook )
	{
		if (!(_src in this.LeafHooks))
			this.LeafHooks[_src] <- {
				Hooks = [],
				Descendants = []
			};
		this.LeafHooks[_src].Hooks.push(_rawLeafHook);
	}

	function __debughook(_eventType,_src,_line,_funcName)
	{
		if (_eventType == 'r' && _funcName == "main")
		{
			// fix path
			local src = ::String.replace(_src.slice(0, -4), "\\", "/");
			local i = -8;
			for (local j; (j = src.find("scripts/", i+8)) != null; i = j) { }
			if (i > 0) src = src.slice(i);

			// check if bb class
			local className = split(src, "/").pop();
			local fileScope = ::getstackinfos(2).locals["this"];
			if (!(className in fileScope))
				return;

			// actually run hooks
			::Hooks.processObject(src, fileScope[className]);
		}
	}

	function registerJS( _filePath )
	{
		this.JSFiles.push(_filePath);
	}

	function registerCSS( _filePath )
	{
		this.CSSFiles.push(_filePath);
	}
}
::logInfo("=================Initialized Hooks=================");

::setdebughook(::Hooks.__debughook);

foreach (file in ::IO.enumerateFiles("modern_hooks/hooks")) // these should run after !mods_preload
{
	::include(file);
}
