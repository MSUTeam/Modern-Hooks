::logInfo("=========Running Queue=========");
::Hooks.__runQueue();
foreach (file in ::IO.enumerateFiles("modern_hooks/hooks"))
	::include(file);
