this.js_connection <- {
	m = {
		JSHandle = null,
		Visible = false,
		Animating = false,
		TextCache = "",
		ForceQuit = false
	},

	function connect()
	{
		this.m.JSHandle = ::UI.connect("ModernHooksConnection", this);
		if (this.m.TextCache != "")
		{
			this.showRawText(this.m.TextCache, this.m.ForceQuit)
			this.m.TextCache = "";
		}
	}

	function destroy()
	{
		this.m.JSHandle = ::UI.disconnect(this.m.JSHandle);
	}

	function isVisible()
	{
		return this.m.Visible;
	}

	function isAnimating()
	{
		return false;
	}

	function isConnected()
	{
		return this.m.JSHandle != null;
	}

	function show()
	{
		this.m.JSHandle.asyncCall("show", null);
	}

	function hide()
	{
		this.m.JSHandle.asyncCall("hide", null);
	}

	function onScreenShown()
	{
		this.m.Visible = true;
	}

	function onScreenHidden()
	{
		this.m.Visible = false;
	}

	function quitGame()
	{

	}

	function forceQuit( _bool = true )
	{
		if (this.isConnected())
			this.m.JSHandle.asyncCall("forceQuit", _bool);
		else
			this.m.ForceQuit = _bool;
	}

	function isForceQuitting()
	{
		return this.m.ForceQuit;
	}

	function showRawText( _text, _forceQuit = false )
	{
		if (_forceQuit)
			this.forceQuit(true);
		if (this.isConnected())
			this.m.JSHandle.asyncCall("showRawText", _text)
		else
			this.m.TextCache += _text + "<br><br>"
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
	}
}
