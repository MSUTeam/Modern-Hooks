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

		return {
			JS = ::Hooks.JSFiles,
			CSS = ::Hooks.CSSFiles,
			LateJS = ::Hooks.LateJSFiles
		}
	}

	function resumeOnInit()
	{
		::Hooks.RootState.ModernHooks_resumeOnInit();
		::Hooks.MainMenuState.ModernHooks_resumeOnInit();
		// delete self?
	}
}
