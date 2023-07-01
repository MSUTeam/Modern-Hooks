local function msu_SemVer_isSemVer( _string )
{
	if (typeof _string != "string") return false;
	return ::Hooks.__SemVerRegex.capture(_string) != null;
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
		switch (_operatorString)
		{
			case "==":
			case "=":
			case "":
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
		if (typeof version != "string" && version != null)
			version = version.tostring();
		local operator = null;
		if (version != null)
		{
			local capture = ::Hooks.__VersionOperatorRegex.capture(version);
			if (capture == null)
				::Hooks.__errorAndThrow(format("Mod version information needs to be prefixed with =/==/!/!=/</<=/>/>=, for example \">=1.0.0\" or \"!1.12421\" (for non SemVer mods), currently : \"%s\"", version));
			operator = ::Hooks.__msu_regexMatch(capture, version, 0);
			if (operator == null)
				operator = "";
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

	function getQueuedFunctions()
	{
		return this.QueuedFunctions;
	}

	function queueFunction( _loadOrderData, _function, _bucket = null )
	{
		this.QueuedFunctions.push(::Hooks.QueuedFunction(this, _function, _loadOrderData, _bucket));
	}

	function getMetaData()
	{
		return this.MetaData;
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
