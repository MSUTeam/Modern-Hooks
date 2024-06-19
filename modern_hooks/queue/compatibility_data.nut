local function msu_String_isInteger( _string )
{
	foreach (char in _string)
	{
		if (char < 48 || char > 57) return false;
	}
	return true;
}

::Hooks.SQClass.CompatibilityData <- class
{
	ModID = null;
	Version = null;
	Operator = null;
	CompatibilityType = null;
	ModName = null;
	Details = null;

	constructor( _modID, _compatibilityType, _version, _operator, _details = null, _modName = null )
	{
		if (_modName == null)
			_modName = _modID;
		this.ModID = _modID;
		this.CompatibilityType = _compatibilityType;
		if (_version == null)
			this.Version = _version;
		else if (::Hooks.__msu_SemVer_isSemVer(_version))
			this.Version = ::Hooks.SQClass.ModVersion(_version);
		else
			this.Version = _version.tofloat(); // purely for backwards compatibility with Adam's Hooks
		this.Operator = _operator;
		this.ModName = _modName;
		this.Details = _details;
	}

	function getModID()
	{
		return this.ModID;
	}

	function getModName()
	{
		return this.ModName;
	}

	function getDetails()
	{
		return this.Details;
	}

	function getFormattedDetails()
	{
		return this.getDetails() == null ? "" : ": " + this.getDetails();
	}

	function __processCmpResult( _cmpResult )
	{
		if (this.CompatibilityType == ::Hooks.CompatibilityType.Requirement)
		{
			if (_cmpResult < 0)
			{
				if (this.Operator == ::Hooks.Operator.EQ)
					return ::Hooks.CompatibilityCheckResult.Incorrect;
				if (this.Operator <= ::Hooks.Operator.LE || this.Operator == ::Hooks.Operator.NE)
					return ::Hooks.CompatibilityCheckResult.Success;
				return ::Hooks.CompatibilityCheckResult.TooSmall;
			}
			if (_cmpResult == 0)
			{
				if ([::Hooks.Operator.LE, ::Hooks.Operator.EQ, ::Hooks.Operator.GE].find(this.Operator) != null)
					return ::Hooks.CompatibilityCheckResult.Success;
				if (this.Operator == ::Hooks.Operator.LT)
					return ::Hooks.CompatibilityCheckResult.TooBig;
				if (this.Operator == ::Hooks.Operator.GT)
					return ::Hooks.CompatibilityCheckResult.TooSmall;
				return ::Hooks.CompatibilityCheckResult.Incorrect;
			}
			if (this.Operator == ::Hooks.Operator.EQ)
				return ::Hooks.CompatibilityCheckResult.Incorrect;
			if (this.Operator >= ::Hooks.Operator.NE)
				return ::Hooks.CompatibilityCheckResult.Success;
			return ::Hooks.CompatibilityCheckResult.TooBig;
		}
		if (_cmpResult < 0)
		{
			if (this.Operator == ::Hooks.Operator.NE)
				return ::Hooks.CompatibilityCheckResult.Incorrect;
			if ([::Hooks.Operator.EQ, ::Hooks.Operator.GT, ::Hooks.Operator.GE].find(this.Operator) != null)
				return ::Hooks.CompatibilityCheckResult.Success;
			return ::Hooks.CompatibilityCheckResult.TooSmall;
		}
		if (_cmpResult == 0)
		{
			if ([::Hooks.Operator.LT, ::Hooks.Operator.NE, ::Hooks.Operator.GT].find(this.Operator) != null)
				return ::Hooks.CompatibilityCheckResult.Success;
			if (this.Operator == ::Hooks.Operator.LE)
				return ::Hooks.CompatibilityCheckResult.TooSmall;
			if (this.Operator == ::Hooks.Operator.GE)
				return ::Hooks.CompatibilityCheckResult.TooBig;
			return ::Hooks.CompatibilityCheckResult.Incorrect;
		}
		if (this.Operator == ::Hooks.Operator.NE)
			return ::Hooks.CompatibilityCheckResult.Incorrect;
		if ([::Hooks.Operator.EQ, ::Hooks.Operator.LT, ::Hooks.Operator.LE].find(this.Operator) != null)
			return ::Hooks.CompatibilityCheckResult.Success;
		return ::Hooks.CompatibilityCheckResult.TooBig;
	}

	function validateModVersion( _mod )
	{
		if (typeof _mod.getVersion() == "float" && typeof this.Version == "instance")
			return this.__processCmpResult(1);
		if (typeof _mod.getVersion() == "instance" && typeof this.Version == "float")
			return this.__processCmpResult(-1);
		return this.__processCmpResult(_mod.getVersion() <=> this.Version);
	}

	function getErrorString()
	{
		local ret = "";
		switch (this.Operator)
		{
			case ::Hooks.Operator.EQ:
				break;
			case ::Hooks.Operator.NE:
				ret += "not equal to "
				break;
			case ::Hooks.Operator.LT:
				ret += "older than ";
				break;
			case ::Hooks.Operator.LE:
				ret += "older than or equal to ";
				break;
			case ::Hooks.Operator.GT:
				ret += "greater than ";
				break;
			case ::Hooks.Operator.GE:
				ret += "greater than or equal to ";
				break;
		}
		ret += typeof this.Version == "float" ? this.Version.tostring() : this.Version.getVersionString();
		ret += this.getFormattedDetails();

		return ret;
	}

	function validate( _mods )
	{
		if (this.CompatibilityType == ::Hooks.CompatibilityType.Requirement)
		{
			if (!(this.ModID in _mods))
				return ::Hooks.CompatibilityCheckResult.ModMissing;
			if (this.Version == null)
				return ::Hooks.CompatibilityCheckResult.Success;
			return this.validateModVersion(_mods[this.ModID]);
		}
		if (!(this.ModID in _mods))
			return ::Hooks.CompatibilityCheckResult.Success;
		if (this.Version == null)
			return ::Hooks.CompatibilityCheckResult.ModPresent;
		return this.validateModVersion(_mods[this.ModID]);
	}
}
