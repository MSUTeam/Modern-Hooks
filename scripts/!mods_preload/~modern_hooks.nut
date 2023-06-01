foreach (file in ::IO.enumerateFiles("modern_hooks/hooks")) // these should run after !mods_preload
{
	::include(file);
}
