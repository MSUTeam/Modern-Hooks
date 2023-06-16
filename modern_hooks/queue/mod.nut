local function msu_SemVer_isSemVer( _string )
{
	if (typeof _string != "string") return false;
	return ::Hooks.__SemVerRegex.capture(_string) != null;
}

local msu_regexMatch = function( _capture, _string, _group )
{
	return _capture[_group].end > 0 && _capture[_group].begin < _string.len() ? _string.slice(_capture[_group].begin, _capture[_group].end) : null;
}

::Hooks.Mod <- class
{
	ID = null;
	Name = null;
	Version = null;
	CompatibilityData = null;
	QueuedFunctions = null;
	MetaData = null;
	CachedModID = null;

	constructor( _id, _version, _name, _metaData )
	{
		if (msu_SemVer_isSemVer(_version))
		{
			this.Version = ::Hooks.ModVersion(_version);
		}
		else
		{
			this.Version = _version.tofloat(); // purely for backwards compatibility with Adam's Hooks
		}

		this.ID = _id;
		this.Name = _name;
		this.MetaData = _metaData;
		this.CompatibilityData = [];
		this.QueuedFunctions = [];
		this.addQueuedFunction(null);
	}

	function getID()
	{
		return this.ID;
	}

	function getName()
	{
		return this.Name;
	}

	function __parseOperatorString( _operatorString )
	{
		switch (operator)
		{
			case "==":
			case "=":
				return ::Hooks.Operator.EQ;
			case "!":
			case "!=":
				return ::Hooks.Operator.NE;
			case ">":
				return ::Hooks.Operator.GT;
			case ">=":
				return ::Hooks.Operator.GE;
			case "<":
				return ::Hooks.Operator.LT;
			case "<=":
				return ::Hooks.Operator.LE;
		}
	}

	function __parseCompatibilityData( _id, _data, _compatibilityType )
	{
		local name = "Name" in _data ? _data.Name : null;
		local version = "Version" in _data ? _data.Version : null;
		local operator = null;
		if (version != null)
		{
			local capture = ::Hooks.__VersionOperatorRegex.capture(version);
			if (capture == null)
				::Hooks.__errorAndThrow("Mod version information needs to be prefixed with =/==/!/!=/</<=/>/>=, for example \">=1.0.0\"");
			local operator = msu_regexMatch(capture, version, 0);
			version = version.slice(operator.len());
			operator = this.__parseOperatorString(operator);
		}
		return ::Hooks.CompatibilityData(_id, _compatibilityType, version, operator, name);
	}

	function declareCompatibilityData( _data )
	{
		if ("Requirements" in _data)
		{
			foreach (modID, modInfo in _data.Requirements)
			{
				this.CompatibilityData.push(this.__parseCompatibilityData(modID, modInfo, ::Hooks.CompatibilityType.Requirement));
			}
		}
		if ("Incompatibilities" in _data)
		{
			foreach (modID, modInfo in _data.Incompatibilities)
			{
				this.CompatibilityData.push(this.__parseCompatibilityData(modID, modInfo, ::Hooks.CompatibilityType.Incompatibility));
			}
		}
	}

	function addQueuedFunction( _id )
	{
		this.QueuedFunctions.push(::Hooks.QueuedFunction(_id, this));
	}

	function getQueuedFunction( _id = null )
	{
		foreach (func in this.QueuedFunctions)
		{
			if (func.getID() == _id)
				return func;
		}
		return null;
	}

	function hasQueuedFunction( _id = null )
	{
		local maybeFunc = this.getQueuedFunction(_id);
		return maybeFunc != null && maybeFunc.getFunction() != null;
	}

	function getQueuedFunctions()
	{
		return this.QueuedFunctions;
	}

	function queueFunction( _function, _id = null )
	{
		this.getQueuedFunction(_id).setFunction(_function);
	}

	function getMetaData()
	{
		return this.MetaData;
	}

	function __validateCachedID()
	{
		if (this.CachedModID in this.CompatibilityData)
			return;
		::Hooks.__errorAndThrow("You must first declare a requirement/incompatibility relationship with a mod before specifying the versions that relationship applies to");
	}

	function loadAfter( _modID = null, _functionID = null )
	{
		if (_modID == null)
			_modID = this.CachedModID;
		else
			this.CachedModID = _modID;

		local func = this.getQueuedFunction(_functionID);
		local idx = func.LoadBefore.find(_modID)
		if (idx != null)
			func.LoadBefore.remove(idx);

		func.LoadAfter.push(_modID);
		return this;
	}

	function loadBefore( _modID = null, _functionID = null )
	{
		if (_modID == null)
			_modID = this.CachedModID;
		else
			this.CachedModID = _modID;

		local func = this.getQueuedFunction(_functionID);
		local idx = func.LoadAfter.find(_modID)
		if (idx != null)
			func.LoadAfter.remove(idx);

		func.LoadBefore.push(_modID);
		return this;
	}

	function getCompatibilityData()
	{
		return this.CompatibilityData;
	}

	function getVersion()
	{
		return this.Version;
	}

	function getVersionString()
	{
		return this.Version.tostring();
	}
}
