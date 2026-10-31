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

// Start Modern Hooks

var Hooks = {
	registerScreens : registerScreens,
	screenInit : false,
	errorMsg : null,
	__Mods : {}, // ID -> {ID, Name, Version}, filled from queryData before any mod JS loads
	// the same patterns as ::Hooks.__SemVerRegex, __ModOperatorAndVersionRegex and __IntFloatRegex
	__SemVerRegex : /^((?:(?:0|[1-9]\d*)\.){2}(?:0|[1-9]\d*))(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/,
	__OperatorAndVersionRegex : /^((?:!|>|<|=)=?) ([^ ]+)$/,
	__IntFloatRegex : /^\d+(?:\.\d+)?$/
}

Hooks.hasMod = function( _modID )
{
	return Object.prototype.hasOwnProperty.call(this.__Mods, _modID);
}

// True if the mod is registered and its version meets _requirement, an operator and a version as in
// mod.require(): "mod_x >= 1.2.0" is Hooks.hasModVersion("mod_x", ">= 1.2.0"). Operators: == (or =), !=
// (or !), <, <=, >, >=. Versions compare as semver, the same as ::Hooks.SQClass.ModVersion, never as strings.
Hooks.hasModVersion = function( _modID, _requirement )
{
	if (typeof _requirement != "string")
		throw new Error("Hooks.hasModVersion: _requirement must be a string like \">= 1.0.0\"");
	var match = this.__OperatorAndVersionRegex.exec(_requirement.trim());
	if (match === null)
		throw new Error("Hooks.hasModVersion: requirement '" + _requirement + "' isn't an operator and a version like \">= 1.0.0\"");
	var required = this.__parseVersion(match[2]);
	if (required === null)
		throw new Error("Hooks.hasModVersion: '" + match[2] + "' isn't a semantic version (see https://semver.org/)");
	if (!this.hasMod(_modID))
		return false;

	var version = this.__parseVersion(this.__Mods[_modID].Version);
	var cmp;
	// as in ::Hooks.SQClass.CompatibilityData.validateModVersion: a float version (Adam's hooks) counts as
	// newer than any semver requirement, and a semver version as older than any float requirement
	if (typeof version == "number" && typeof required != "number")
		cmp = 1;
	else if (typeof version != "number" && typeof required == "number")
		cmp = -1;
	else if (typeof version == "number")
		cmp = version > required ? 1 : version < required ? -1 : 0;
	else
		cmp = this.__compareSemVer(version, required);

	switch (match[1])
	{
		case "=": case "==": return cmp == 0;
		case "!": case "!=": return cmp != 0;
		case "<": return cmp < 0;
		case "<=": return cmp <= 0;
		case ">": return cmp > 0;
		case ">=": return cmp >= 0;
	}
}

// Returns {Major, Minor, Patch, PreRelease}, a number for a float version, or null if it's neither.
Hooks.__parseVersion = function( _string )
{
	var match = this.__SemVerRegex.exec(_string);
	if (match !== null)
	{
		var parts = match[1].split(".");
		return {
			Major : parseInt(parts[0], 10),
			Minor : parseInt(parts[1], 10),
			Patch : parseInt(parts[2], 10),
			PreRelease : match[2] === undefined ? null : match[2].split(".")
		};
	}
	if (this.__IntFloatRegex.test(_string))
		return parseFloat(_string);
	return null;
}

// A port of ::Hooks.SQClass.ModVersion._cmp. Returns -1, 0 or 1.
Hooks.__compareSemVer = function( _a, _b )
{
	var keys = ["Major", "Minor", "Patch"];
	for (var i = 0; i < keys.length; ++i)
	{
		if (_a[keys[i]] > _b[keys[i]]) return 1;
		if (_a[keys[i]] < _b[keys[i]]) return -1;
	}
	if (_a.PreRelease === null || _b.PreRelease === null)
	{
		if (_a.PreRelease === null && _b.PreRelease !== null) return 1;
		if (_a.PreRelease !== null && _b.PreRelease === null) return -1;
		return 0;
	}
	var isInteger = /^\d+$/;
	for (var i = 0; i < Math.min(_a.PreRelease.length, _b.PreRelease.length); ++i)
	{
		var x = _a.PreRelease[i], y = _b.PreRelease[i];
		var isInt1 = isInteger.test(x), isInt2 = isInteger.test(y);
		if (isInt1 && isInt2)
		{
			var int1 = parseInt(x, 10), int2 = parseInt(y, 10);
			if (int1 < int2) return -1;
			if (int1 > int2) return 1;
		}
		else if (isInt1 || isInt2)
		{
			return isInt1 ? -1 : 1;
		}
		else
		{
			if (x > y) return 1;
			if (x < y) return -1;
		}
	}
	if (_a.PreRelease.length > _b.PreRelease.length) return 1;
	if (_a.PreRelease.length < _b.PreRelease.length) return -1;
	return 0;
}

// Define ModernHooksConnection

var ModernHooksConnection = function()
{
	this.mSQHandle = null
	this.mContainer = null;

	this.mHeaderContainer = null;
	this.mContentContainer = null;
	this.mListScrollContainer = null;
	this.mFooterContainer = null;
	this.mTitle = null;
}

ModernHooksConnection.prototype.onConnection = function( _handle )
{
	this.mSQHandle = _handle;
	this.createDIV($('.root-screen'));
	var self = this;
	SQ.call(this.mSQHandle, "queryData", null, function (_data)
	{
		for (var i = 0; i < _data.Mods.length; ++i)
			Hooks.__Mods[_data.Mods[i].ID] = _data.Mods[i];

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
			SQ.call(self.mSQHandle, "resumeOnInit", null, function(_data){
				if (_data === true)
				{
					Hooks.screenInit = true;
					if (Hooks.errorMsg != null)
						Hooks.errorMsg.remove();
				}
			});
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

ModernHooksConnection.prototype.createDIV = function (_parentDiv)
{
	var self = this;
	this.mContainer = $('<div class="modern-hooks-popup ui-control dialog display-none opacity-none"/>');
	_parentDiv.append(this.mContainer);

	this.mHeaderContainer = $('<div class="header"/>');
	this.mContainer.append(this.mHeaderContainer);

	this.mTitle = $('<div class="title title-font-very-big font-bold font-bottom-shadow font-color-title">Mod Error</div>');
	this.mHeaderContainer.append(this.mTitle);

	this.mListContainer = this.mContainer.createList(1, 'content-container');
	this.mListScrollContainer = this.mListContainer.findListScrollContainer();
	this.mContainer.append(this.mContentContainer);


	this.mFooterContainer = $('<div class="footer"/>')
	this.mContainer.append(this.mFooterContainer);

	this.mFooterContainer.createTextButton("Ok", function()
	{
		self.hide();
	}, "ok-button", 1).on("force-quit", function()
	{
		$(this).findButtonText().html("Quit Game");
		$(this).on("click", function()
		{
			self.quitGame();
		});
	}).on("cancel-quit", function(){
		$(this).findButtonText().html("Ok");
		$(this).on("click", function()
		{
			self.hide();
		});
	});
}

ModernHooksConnection.prototype.show = function ()
{
	this.mContainer.removeClass('display-none').addClass('display-block');
	this.mContainer.css({ opacity: 1 });
	this.notifyBackendOnShown();
}

ModernHooksConnection.prototype.hide = function ()
{
	this.notifyBackendOnHidden();
	this.mContainer.css({ opacity: 0 });
	this.mContainer.removeClass('display-block').addClass('display-none')
}

ModernHooksConnection.prototype.isVisible = function ()
{
	return this.mContainer.hasClass('display-block');
}

ModernHooksConnection.prototype.forceQuit = function (_quit)
{
	if (_quit)
	{
		this.mTitle.text("Fatal Mod Error");
		this.mFooterContainer.find(".ok-button:first").trigger('force-quit')
	}
	else
	{
		this.mTitle.text("Mod Error");
		this.mFooterContainer.find(".ok-button:first").trigger('cancel-quit')
	}
}

ModernHooksConnection.prototype.showRawText = function (_data)
{
	this.mListScrollContainer.append($('<div class="mod-raw-text">' + _data + '</div>'));
	if (!this.isVisible())
	{
		this.show();
	}
}

ModernHooksConnection.prototype.notifyBackendOnShown = function ()
{
	if (this.mSQHandle !== null)
		SQ.call(this.mSQHandle, 'onScreenShown');
};

ModernHooksConnection.prototype.notifyBackendOnHidden = function ()
{
	if (this.mSQHandle !== null)
		SQ.call(this.mSQHandle, 'onScreenHidden');
};

ModernHooksConnection.prototype.quitGame = function ()
{
	SQ.call(this.mSQHandle, "quitGame");
}

registerScreens = function(){}; // need to do this so the document.ready in main.html does nothing
$(document).ready(function(){
	registerScreen("ModernHooksConnection", new ModernHooksConnection())
	registerScreen("RootScreen", new RootScreen()); // RootScreen needs to be init, main menu screen never shows otherwise
	engine.call("registrationFinished");
})

setTimeout(function(){
	if (Hooks.screenInit)
		return;
	Hooks.errorMsg = $('<div id="hooksErrorMessage">If you are seeing this screen and the game is not loading, that probably means something went wrong when loading your mods.<br><br> For more details, check your log; found in "Documents/Battle Brothers/log.html".<br><br> If you plan to look for help when debugging, be sure to provide the ENTIRE log.html file to those you ask for help.</div>');
	Hooks.errorMsg.css({
		'position' : 'absolute',
		'top' : '50%',
		'left' : '50%',
		'transform' : 'translate(-50%, -50%)',
		'color' : 'white',
		'width' : '80%',
		'text-align' : 'center',
		'font-size' : '72px',
		'font-family' : 'FreeUniversal-Regular'
	});
	$('.root-screen').append(Hooks.errorMsg);
}, 2000);

