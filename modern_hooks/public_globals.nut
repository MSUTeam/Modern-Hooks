::Hooks.register <- function( _modID, _version, _modName, _metaData = null )
{
	if (_metaData == null)
		_metaData = {};
	if (_modID in this.Mods)
	{
		this.__errorAndThrow(format("Mod %s (%s) version %s is trying to register twice", _modID, _modName, _version.tostring()))
	}
	this.Mods[_modID] <- ::Hooks.Mod(_modID, _version, _modName, _metaData);
	this.__inform(format("Modern Hooks registered [emph]%s[/emph] (%s) version [emph]%s[/emph]", this.Mods[_modID].getName(), this.Mods[_modID].getID(), this.Mods[_modID].getVersion().tostring()))
	return this.Mods[_modID];
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

::Hooks.rawHook <- function( _modID, _src, _rawHook ) // _modID gets ignored for now ig
{
	if (!::Hooks.hasMod(_modID))
	{
		::Hooks.__error("To hook using modern hooks, you must first register your mod with ::Hooks.register");
		return;
	}
	this.__initClass(_src);
	this.Classes[_src].RawHooks.Hooks.push(_rawHook);
}

::Hooks.rawLeafHook <- function( _modID, _src, _rawLeafHook ) // _modID gets ignored for now ig
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

::Hooks.registerCSS <- function( _filePath )
{
	if (typeof _filePath != "string" || _filePath.slice(0,3) != "ui/")
	{
		this.__error("registerCSS requires a file path starting with ui/");
		return;
	}
	this.CSSFiles.push(_filePath);
}

::Hooks.addNewFunctions <- function( _modID, _src, _newFunctions )
{
	this.rawHook(_modID, _src, this.__getAddNewFunctionsHook( _modID, _src, _newFunctions))
}

::Hooks.addNewLeafFunctions <- function( _modID, _src, _newFunctions )
{
	this.rawLeafHook(_modID, _src, this.__getAddNewFunctionsHook( _modID, _src, _newFunctions))
}

::Hooks.wrapFunctions <- function( _modID, _src, _funcWrappers )
{
	this.rawHook(_modID, _src, this.__getFunctionWrappersHook(_modID, _src, _funcWrappers));
}

::Hooks.wrapLeafFunctions <- function( _modID, _src, _funcWrappers )
{
	this.rawLeafHook(_modID, _src, this.__getFunctionWrappersHook(_modID, _src, _funcWrappers));
}

::Hooks.addFields <- function( _modID, _src, _fieldsToAdd )
{
	this.rawHook(_modID, _src, this.__getAddFieldsHook(_modID, _src, _fieldsToAdd));
}

::Hooks.addLeafFields <- function( _modID, _src, _fieldsToAdd )
{
	this.rawLeafHook(_modID, _src, this.__getAddFieldsHook(_modID, _src, _fieldsToSet));
}

::Hooks.setFields <- function( _modID, _src, _fieldsToSet )
{
	this.rawHook(_modID, _src, this.__getSetFieldsHook(_modID, _src, _fieldsToSet));
}

::Hooks.setLeafFields <- function( _modID, _src, _fieldsToSet )
{
	this.rawLeafHook(_modID, _src, this.__getSetFieldsHook(_modID, _src, _fieldsToSet));
}
