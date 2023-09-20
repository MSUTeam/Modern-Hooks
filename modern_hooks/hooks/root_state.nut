::Hooks.__Mod.rawHook("scripts/root_state", function(o)
{
	local onInit = o.onInit;
	o.onInit = function()
	{
		::Hooks.RootState = this;
		::Hooks.JSConnection <- ::new("scripts/mods/modern_hooks/js_connection");
		::Hooks.JSConnection.connect();
		this.add("MainMenuState", "scripts/states/main_menu_state");
	}

	o.ModernHooks_resumeOnInit <- function()
	{
		local add = this.add;
		this.add = function(...){};
		onInit();
		this.add = add;
	}
});
