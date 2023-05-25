var Hooks = {
	registerScreens : registerScreens
}

ModernHooksConnection = function()
{
	this.mSQHandle = null;
}

ModernHooksConnection.prototype.onConnection = function( _handle )
{
	this.mSQHandle = _handle;
	var self = this;
	SQ.call(this.mSQHandle, "queryData", null, function (_data)
	{
		var jsFiles = _data.JS;
		for (var i = 0; i < jsFiles.length; ++i)
		{
			var js = document.createElement("script");
			js.src = jsFiles[i];
			document.body.appendChild(js);
		}
		var cssFiles = _data.CSS;
		for (var i = 0; i < cssFiles.length; ++i)
		{
			var link = document.createElement("link");
			link.rel = "stylesheet";
			link.type = "text/css";
			link.href = cssFiles[i];
			document.body.appendChild(link);
		}

		var resumeInit = function()
		{
			console.error("resumeInit")
			var engineCall = engine.call;
			engine.call = function(_functionName, _target, _arg1, _arg2)
			{
				if (_functionName == "registrationFinished")
					return;
				if (_functionName == "registerScreen" && _target == "RootScreen")
					return;
				return engineCall.call(this, _functionName, _target, _arg1, _arg2);
			}
			Hooks.registerScreens();
			engine.call = engineCall;
			console.error("resumeOnInit")
			SQ.call(self.mSQHandle, "resumeOnInit", null);
		}
		console.error("onConnection")

		if (jsFiles.length == 0)
			resumeInit();
		else
		{
			var js = document.createElement("script");
			js.src = jsFiles[jsFiles.length-1];
			js.onload = function()
			{
				resumeInit();
			}
			document.body.appendChild(js);
		}
	});
}

registerScreens = function(){}; // need to do this so the document.ready in main.html does nothing
$(document).ready(function() // we instead replace that handler with this
{
	registerScreen("ModernHooksConnection", new ModernHooksConnection())
	registerScreen("RootScreen", new RootScreen()); // RootScreen needs to be init, main menu screen never shows otherwise
	engine.call("registrationFinished");
});
