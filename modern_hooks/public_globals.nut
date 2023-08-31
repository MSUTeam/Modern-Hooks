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

::Hooks.rawHook <- function( _modID, _src, _rawHook )
{
	if (!::Hooks.hasMod(_modID))
	{
		::Hooks.__error("To hook using modern hooks, you must first register your mod with ::Hooks.register");
		return;
	}
	this.__initClass(_src);
	this.Classes[_src].RawHooks.Hooks.push(_rawHook);
}

::Hooks.rawLeafHook <- function( _modID, _src, _rawLeafHook )
{
	if (!::Hooks.hasMod(_modID))
	{
		::Hooks.__error("To hook using modern hooks, you must first register your mod with ::Hooks.register");
		return;
	}
	this.__initClass(_src);
	this.Classes[_src].LeafHooks.Hooks.push(_rawLeafHook);
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

::Hooks.addFunctions <- function( _modID, _src, _newFunctions )
{
	local error = this.__validateNewFunctions(_newFunctions);
	if (error != null)
	{
		this.__error(format("Failed to validate the _newFunctions table for %s, BB Class %s. Reason: \"%s\", check <a href=\"https://bbmodding.enduriel.com/docs/modern-hooks/basic-hooks/#adding-functions\">documentation</a> if in doubt.", _modID, _src, error));
		return;
	}
	this.rawHook(_modID, _src, this.__getAddNewFunctionsHook( _modID, _src, _newFunctions))
}

::Hooks.addLeafFunctions <- function( _modID, _src, _newFunctions )
{
	local error = this.__validateNewFunctions(_newFunctions);
	if (error != null)
	{
		this.__error(format("Failed to validate the _newFunctions table for %s, BB Class %s. Reason: \"%s\", check <a href=\"https://bbmodding.enduriel.com/docs/modern-hooks/basic-hooks/#adding-functions\">documentation</a> if in doubt.", _modID, _src, error));
		return;
	}
	this.rawLeafHook(_modID, _src, this.__getAddNewFunctionsHook( _modID, _src, _newFunctions))
}

::Hooks.wrapFunctions <- function( _modID, _src, _funcWrappers )
{
	local error = this.__validateWrapFunctions(_funcWrappers);
	if (error != null)
	{
		this.__error(format("Failed to validate the _funcWrappers table for %s, BB Class %s. Reason: \"%s\", check <a href=\"https://bbmodding.enduriel.com/docs/modern-hooks/basic-hooks/#wrapping-functions\">documentation</a> if in doubt.", _modID, _src, error));
		return;
	}
	this.rawHook(_modID, _src, this.__getFunctionWrappersHook(_modID, _src, _funcWrappers));
}

::Hooks.wrapLeafFunctions <- function( _modID, _src, _funcWrappers )
{
	local error = this.__validateWrapFunctions(_funcWrappers);
	if (error != null)
	{
		this.__error(format("Failed to validate the _funcWrappers table for %s, BB Class %s. Reason: \"%s\", check <a href=\"https://bbmodding.enduriel.com/docs/modern-hooks/basic-hooks/#wrapping-functions\">documentation</a> if in doubt.", _modID, _src, error));
		return;
	}
	this.rawLeafHook(_modID, _src, this.__getFunctionWrappersHook(_modID, _src, _funcWrappers));
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

::Hooks.addFields <- function( _modID, _src, _fieldsToAdd )
{
	local error = this.__validateFields(_fieldsToAdd);
	if (error != null)
	{
		this.__error(format("Failed to validate the _fieldsToAdd table for %s, BB Class %s. Reason: \"%s\", check <a href=\"https://bbmodding.enduriel.com/docs/modern-hooks/basic-hooks/#adding-fields\">documentation</a> if in doubt.", _modID, _src, error));
		return;
	}
	this.rawHook(_modID, _src, this.__getAddFieldsHook(_modID, _src, _fieldsToAdd));
}

::Hooks.addLeafFields <- function( _modID, _src, _fieldsToAdd )
{
	local error = this.__validateFields(_fieldsToAdd);
	if (error != null)
	{
		this.__error(format("Failed to validate the _fieldsToAdd table for %s, BB Class %s. Reason: \"%s\", check <a href=\"https://bbmodding.enduriel.com/docs/modern-hooks/basic-hooks/#adding-fields\">documentation</a> if in doubt.", _modID, _src, error));
		return;
	}
	this.rawLeafHook(_modID, _src, this.__getAddFieldsHook(_modID, _src, _fieldsToSet));
}

::Hooks.setFields <- function( _modID, _src, _fieldsToSet )
{
	local error = this.__validateFields(_fieldsToSet);
	if (error != null)
	{
		this.__error(format("Failed to validate the _fieldsToSet table for %s, BB Class %s. Reason: \"%s\", check <a href=\"https://bbmodding.enduriel.com/docs/modern-hooks/basic-hooks/#setting-fields\">documentation</a> if in doubt.", _modID, _src, error));
		return;
	}
	this.rawHook(_modID, _src, this.__getSetFieldsHook(_modID, _src, _fieldsToSet));
}

::Hooks.setLeafFields <- function( _modID, _src, _fieldsToSet )
{
	local error = this.__validateFields(_fieldsToSet);
	if (error != null)
	{
		this.__error(format("Failed to validate the _fieldsToSet table for %s, BB Class %s. Reason: \"%s\", check <a href=\"https://bbmodding.enduriel.com/docs/modern-hooks/basic-hooks/#setting-fields\">documentation</a> if in doubt.", _modID, _src, error));
		return;
	}
	this.rawLeafHook(_modID, _src, this.__getSetFieldsHook(_modID, _src, _fieldsToSet));
}
