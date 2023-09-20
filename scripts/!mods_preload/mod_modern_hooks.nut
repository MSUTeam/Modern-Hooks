::Hooks.__Mod <- ::Hooks.register(::Hooks.ID, ::Hooks.Version, ::Hooks.Name);
::Hooks.__Mod.queue(function (){
	::include("modern_hooks/hooks/main_menu_state");
	::include("modern_hooks/hooks/root_state");
}, ::Hooks.QueueBucket.Last);

::Hooks.__Mod.queue(function() {
	::include("modern_hooks/hooks/world_state");
})
