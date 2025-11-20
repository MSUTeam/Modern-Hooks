::setdebughook(null);
::Hooks.__finalizeHooks();
::Hooks.__runAfterHooksQueue();
::Hooks.inform("=================Finalized Hooks=================");
foreach (src, c in ::Hooks.BBClass)
{
	foreach (k, v in c.History)
	{
		// ::logInfo(src + "." + k);
		// foreach (v1 in v)
		// {
		// 	foreach (k2, v2 in v1)
		// 	{
		// 		::logInfo(k2 + ":" + v2);
		// 	}
		// }
		::logInfo(src + "." + k);
		::MSU.Log.printData(v, 2, false, 10);
	}
}
//::Hooks.clear()
