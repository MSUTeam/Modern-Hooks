::mods_hookExactClass = function(name, func)
{
	::Hooks.rawHook("mod_hooks_patch", "scripts/" + name, func)
}
