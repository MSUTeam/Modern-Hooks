::Hooks.register(::Hooks.ID, ::Hooks.Version, ::Hooks.Name)
	.queueFunction(null, function (){
		foreach (file in ::IO.enumerateFiles("modern_hooks/hooks"))
			::include(file);
	}, ::Hooks.QueueBucket.Last);
