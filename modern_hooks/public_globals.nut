::Hooks.register <- function( _modID, _version, _modName, _metaData = null )
{
	if (typeof _version != "string")
		this.__errorAndThrow(format("Modern Hooks requires that mods registering with it have a Semantic Version, see https://semver.org. Mod %s version %s doesn't follow this format", _modID, _version + ""))
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
		this.__error("registerJS requires a file path starting with ui/");
		return;
	}
	this.JSFiles.push(_filePath);
}

::Hooks.registerLateJS <- function( _filePath )
{
	if (typeof _filePath != "string" || _filePath.slice(0,3) != "ui/")
	{
		this.__error("registerJS requires a file path starting with ui/");
		return;
	}
	this.LateJSFiles.push(_filePath);
}

::Hooks.registerCSS <- function( _filePath )
{
	if (typeof _filePath != "string" || _filePath.slice(0,3) != "ui/")
	{
		this.__error("registerCSS requires a file path starting with ui/");
		return;
	}
	this.CSSFiles.push(_filePath);
}

::Hooks.wrapNativeEntityFunctions <- function( _modID, _src, _funcWrappers )
{
	local error = this.__validateWrapFunctions(_funcWrappers);
	if (error != null)
	{
		this.__error(format("Failed to validate the _funcWrappers table for %s, BB Class %s. Reason: \"%s\", check <a href=\"https://bbmodding.enduriel.com/docs/modern-hooks/basic-hooks/#wrapping-functions\">documentation</a> if in doubt.", _modID, _src, error));
		return;
	}
	this.rawHook(_modID, _src, this.__getNativeFunctionWrapper(_modID, _src, _funcWrappers));
}

::Hooks.wrapLeafNativeEntityFunctions <- function( _modID, _src, _funcWrappers )
{
	local error = this.__validateWrapFunctions(_funcWrappers);
	if (error != null)
	{
		this.__error(format("Failed to validate the _funcWrappers table for %s, BB Class %s. Reason: \"%s\", check <a href=\"https://bbmodding.enduriel.com/docs/modern-hooks/basic-hooks/#wrapping-functions\">documentation</a> if in doubt.", _modID, _src, error));
		return;
	}
	this.rawLeafHook(_modID, _src, this.__getNativeFunctionWrapper(_modID, _src, _funcWrappers));
}
