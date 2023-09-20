::Hooks.__Mod <- ::Hooks.register(::Hooks.ID, ::Hooks.Version, ::Hooks.Name);
::Hooks.__Mod.queue(function (){
		foreach (file in ::IO.enumerateFiles("modern_hooks/hooks"))
			::include(file);
	}, ::Hooks.QueueBucket.Last);
