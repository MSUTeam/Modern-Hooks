::Hooks.__Mod.hook("scripts/states/world_state", function(q){
	q.onInit = @(__original) function() {
		__original();
		if (::Hooks.FirstWorldInitBucket == null)
			return;
		::Hooks.inform(format("-----------------Running queue bucket [emph]%s[/emph]-----------------", ::Hooks.__getNameForQueueBucket(::Hooks.QueueBucket.FirstWorldInit)));
		::Hooks.__executeQueuedFunctions(::Hooks.FirstWorldInitBucket);
		::Hooks.FirstWorldInitBucket = null;
	}
});
