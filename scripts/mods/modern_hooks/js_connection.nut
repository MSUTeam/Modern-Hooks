this.js_connection <- {
	m = {
		JSHandle = null
	},

	function connect()
	{
		this.m.JSHandle = ::UI.connect("ModernHooksConnection", this);
	}

	function destroy()
	{
		this.m.JSHandle = ::UI.disconnect(this.m.JSHandle);
	}

	function isVisible()
	{
		return false
	}

	function isAnimating()
	{
		return false
	}

	function isConnected()
	{
		return this.m.JSHandle != null;
	}

	function queryData()
	{
		if (::IO.enumerateFiles("ui").find("ui/mod_hooks") != null)
		{
			::logInfo("Script Hooks present, loading patch");
			::Hooks.registerJS("ui/mod_hooks.js");
		}
		return {
			JS = ::Hooks.JSFiles,
			CSS = ::Hooks.CSSFiles
		}
	}

	function resumeOnInit()
	{
		::Hooks.RootState.ModernHooks_resumeOnInit();
		::Hooks.MainMenuState.ModernHooks_resumeOnInit();
		// delete self?
	}
}
