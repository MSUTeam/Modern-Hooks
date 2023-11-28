::Hooks.__Mod.hook("scripts/root_state", function(q)
{
	local onInit = q.onInit;
	q.onInit = @() function()
	{
		::Hooks.RootState = this;
		::Hooks.JSConnection.connect();
		if ("mods_callHook" in ::getroottable())
			::mods_callHook("root_state.onInit", this);

		this.add("MainMenuState", "scripts/states/main_menu_state");
	}

	q.ModernHooks_resumeOnInit <- function()
	{
		local add = this.add;
		this.add = function(...){};
		local mods_callHook = "mods_callHook" in ::getroottable() ? ::mods_callHook : null;
		if (mods_callHook != null)
		{
			::mods_callHook = function(...) {
				if (vargv[0] == "root_state.onInit")
					return;
				vargv.insert(0, ::getroottable());
				return mods_callHook.acall(vargv);
			}
		}

		onInit();
		if ("mods_callHook" in ::getroottable())
			::mods_callHook = mods_callHook;
		this.add = add;
	}
});
