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
		this.CompatibilityData = {};
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

	function require( _modID )
	{
		this.CachedModID = _modID;
		this.CompatibilityData[_modID] <- ::Hooks.CompatibilityData(_modID, ::Hooks.CompatibilityType.Requirement);
		this.loadAfter(_modID);
		return this;
	}

	function incompatibleWith( _modID )
	{
		this.CachedModID = _modID;
		this.CompatibilityData[_modID] <- ::Hooks.CompatibilityData(_modID, ::Hooks.CompatibilityType.Incompatibility);
		return this;
	}

	function __validateCachedID()
	{
		if (this.CachedModID in this.CompatibilityData)
			return;
		::Hooks.__errorAndThrow("You must first declare a requirement/incompatibility relationship with a mod before specifying the versions that relationship applies to");
	}

	function setVersionRequirements( _version, _operator )
	{
		this.__validateCachedID();
		this.CompatibilityData[this.CachedModID].setVersionRequirements(_version, _operator);
		this.CachedModID = null;
		return this;
	}

	function minVersion( _version )
	{
		return this.setVersionRequirements(_version, ::Hooks.Operator.GE);
	}

	function greaterThanVersion( _version )
	{
		return this.setVersionRequirements(_version, ::Hooks.Operator.GT);
	}

	function maxVersion( _version )
	{
		return this.setVersionRequirements(_version, ::Hooks.Operator.LE);
	}

	function lessThanVersion( _version )
	{
		return this.setVersionRequirements(_version, ::Hooks.Operator.LT);
	}

	function version( _version )
	{
		return this.setVersionRequirements(_version, ::Hooks.Operator.EQ);
	}

	function notVersion( _version )
	{
		return this.setVersionRequirements(_version, ::Hooks.Operator.NE);
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
		return typeof this.Version == "float" ? this.Version.tostring() : this.Version.getVersionString();
	}
}
