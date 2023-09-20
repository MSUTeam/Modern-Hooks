::Hooks.__Mod.hook("scripts/states/main_menu_state", function(q)
{
	q.ModernHooks_resumeOnInit <- q.onInit;
	q.onInit = @(__original) function()
	{
		::Hooks.MainMenuState = this;
	}
});
