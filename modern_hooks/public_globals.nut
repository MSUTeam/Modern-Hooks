::Hooks.register <- function( _modID, _version, _modName, _metaData = null )
{
	if (typeof _version != "string")
		::Hooks.errorAndThrow(format("Modern Hooks requires that mods registering with it have a Semantic Version, see https://semver.org. Mod %s version %s doesn't follow this format", _modID, _version + ""))
	return this.__unverifiedRegister(_modID, _version, _modName, _metaData);
}

::Hooks.getMods <- function()
{
	return this.Mods;
}

::Hooks.hasMod <- function( _modID )
{
	return _modID in this.Mods;
}

::Hooks.getMod <- function( _modID )
{
	return this.Mods[_modID];
}

::Hooks.registerJS <- function( _filePath )
{
	if (typeof _filePath != "string" || _filePath.slice(0,3) != "ui/")
	{
		::Hooks.error("registerJS requires a file path starting with ui/");
		return;
	}
	this.JSFiles.push(_filePath);
}

::Hooks.registerLateJS <- function( _filePath )
{
	if (typeof _filePath != "string" || _filePath.slice(0,3) != "ui/")
	{
		::Hooks.error("registerJS requires a file path starting with ui/");
		return;
	}
	this.LateJSFiles.push(_filePath);
}

::Hooks.registerCSS <- function( _filePath )
{
	if (typeof _filePath != "string" || _filePath.slice(0,3) != "ui/")
	{
		::Hooks.error("registerCSS requires a file path starting with ui/");
		return;
	}
	this.CSSFiles.push(_filePath);
}

::Hooks.errorAndThrow <- function( _text )
{
	::Hooks.Popup.showRawText(_text);
	throw _text;
}

::Hooks.errorAndQuit <- function( _text )
{
	::logError(_text);
	::Hooks.Popup.showRawText(_text, true);
}

::Hooks.error <- function(_text)
{
	::logError(_text);
	::Hooks.Popup.showRawText(_text);
}

::Hooks.warn <- function( _text )
{
	::logWarning(_text);
	if (this.DebugMode)
		::Hooks.Popup.showRawText(_text);
}

::Hooks.inform <- function( _text )
{
	_text = ::String.replace(_text, "[emph]", "<span style=\"color:#FFFFFF\">")
	_text = ::String.replace(_text, "[/emph]", "</span>")
	::logInfo("<span style=\"color:#9932CC;\">" + _text + "</span>");
}
