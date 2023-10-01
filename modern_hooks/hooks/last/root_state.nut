::Hooks.__Mod.hook("scripts/root_state", function(q)
{
	local onInit = q.onInit;
	q.onInit = @() function()
	{
		::Hooks.RootState = this;
		::Hooks.JSConnection.connect();
		this.add("MainMenuState", "scripts/states/main_menu_state");
	}

	q.ModernHooks_resumeOnInit <- function()
	{
		local add = this.add;
		this.add = function(...){};
		onInit();
		this.add = add;
	}
});
