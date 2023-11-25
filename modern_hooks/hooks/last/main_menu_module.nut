::Hooks.__Mod.hook("scripts/ui/screens/menu/modules/main_menu_module", function(q)
{
	q.create = @(__original) function()
	{
		__original();
		::Hooks.Popup.quitGame = this.onQuitButtonPressed.bindenv(this);
	}
});
