/*
 *  @Project:		Battle Brothers
 *	@Company:		Overhype Studios
 *
 *	@Copyright:		(c) Overhype Studios | 2013 - 2020
 *
 *  @Author:		Overhype Studios
 *  @Date:			14.02.2017
 *  @Description:	FPS Module JS
 */
"use strict";


var RootScreenFPSModule = function()
{
	this.mSQHandle = null;

	// container & label
	this.mContainer = null;
	this.mFPSLabel = null;
};


RootScreenFPSModule.prototype.isConnected = function ()
{
    return this.mSQHandle !== null;
};

RootScreenFPSModule.prototype.onConnection = function (_handle)
{
    //if (typeof(_handle) == 'string')
    {
        this.mSQHandle = _handle;
    }
};

RootScreenFPSModule.prototype.onDisconnection = function ()
{
    this.mSQHandle = null;
};


RootScreenFPSModule.prototype.createDIV = function (_parentDiv)
{
	this.mContainer = $('<div class="fps-container ui-control.panel-embossed"></div>');
    _parentDiv.append(this.mContainer);

	var fpsLabel = $('<div class="label default-font-normal ui-control-fps-label">FPS:</div>');
	this.mFPSLabel = $('<div class="value default-font-normal ui-control-fps-label">60</div>');
	this.mContainer.append(fpsLabel);
	this.mContainer.append(this.mFPSLabel);
};

RootScreenFPSModule.prototype.destroyDIV = function ()
{
    this.mFPSLabel.remove();
    this.mFPSLabel = null;

    this.mContainer.empty();
    this.mContainer.remove();
    this.mContainer = null;
};


RootScreenFPSModule.prototype.create = function(_parentDiv)
{
    this.createDIV(_parentDiv);
};

RootScreenFPSModule.prototype.destroy = function()
{
    this.destroyDIV();
};


RootScreenFPSModule.prototype.register = function (_parentDiv)
{
    console.log('RootScreenFPSModule::REGISTER');

    if (this.mContainer !== null)
    {
        console.error('ERROR: Failed to register FPS Module. Reason: FPS Module is already initialized.');
        return;
    }

    if (_parentDiv !== null && typeof(_parentDiv) == 'object')
    {
        this.create(_parentDiv);
    }
};

RootScreenFPSModule.prototype.unregister = function ()
{
    console.log('RootScreenFPSModule::UNREGISTER');

    if (this.mContainer === null)
    {
        console.error('ERROR: Failed to unregister FPS Module. Reason: FPS Module is not initialized.');
        return;
    }

    this.destroy();
};


RootScreenFPSModule.prototype.setFPS = function (_value)
{
	this.mFPSLabel.html(_value);
};

var Hooks = {
	registerScreens : registerScreens,
}

var ModernHooksConnection = function()
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
		for (var i = 0; i < jsFiles.length-1; ++i) // the last one has an onload action appended to it
		{
			var js = document.createElement("script");
			js.src = jsFiles[i].slice(3);
			document.body.appendChild(js);
		}
		var cssFiles = _data.CSS;
		for (var i = 0; i < cssFiles.length; ++i)
		{
			var link = document.createElement("link");
			link.rel = "stylesheet";
			link.type = "text/css";
			link.href = cssFiles[i].slice(3);
			document.body.appendChild(link);
		}

		var resumeInit = function()
		{
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
			SQ.call(self.mSQHandle, "resumeOnInit", null);

			var lateJsFiles = _data.LateJS;
			for (var i = 0; i < lateJsFiles.length; i++)
			{
				var js = document.createElement("script");
				js.src = lateJsFiles[i].slice(3);
				document.body.appendChild(js);
			}
		}

		if (jsFiles.length == 0)
			resumeInit();
		else
		{
			var js = document.createElement("script");
			js.src = jsFiles[jsFiles.length-1].slice(3);
			js.onload = function()
			{
				resumeInit();
			}
			document.body.appendChild(js);
		}
	});
}

registerScreens = function(){}; // need to do this so the document.ready in main.html does nothing
$(document).ready(function(){
	registerScreen("ModernHooksConnection", new ModernHooksConnection())
	registerScreen("RootScreen", new RootScreen()); // RootScreen needs to be init, main menu screen never shows otherwise
	engine.call("registrationFinished");
})

