::Hooks.rawHook("scripts/states/main_menu_state", function(o)
{
	o.ModernHooks_resumeOnInit <- o.onInit;
	o.onInit = function()
	{
		::Hooks.MainMenuState = this;
	}
});
