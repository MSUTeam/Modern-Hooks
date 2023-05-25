// I need to include this patch
// because for some reason when I call this function from modern_hooks.js
// the mod_hooks.js file would error due to it trying to call this.onConnection
// rather than the global onConnection Adam added,
// resulting in infinite recursion and a crash
"use strict";
Hooks.MainMenuScreen_onConnection = MainMenuScreen.prototype.onConnection;
MainMenuScreen.prototype.onConnection = function(handle)
{
  Hooks.MainMenuScreen_onConnection.call(this, handle);

  SQ.call(this.mSQHandle, "getRegisteredCSSHooks", null, function(a) {
    for(var i=0; i<a.length; i++)
    {
      var link = document.createElement("link");
      link.rel = "stylesheet";
      link.type = "text/css";
      link.href = a[i];
      document.body.appendChild(link);
    }
  }.bind(this));

  SQ.call(this.mSQHandle, "getRegisteredJSHooks", null, function(a) {
    for(var i=0; i<a.length; i++)
    {
      var js = document.createElement("script");
      js.src = a[i];
      document.body.appendChild(js);
    }
  }.bind(this));
}
