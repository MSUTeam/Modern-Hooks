local function msu_String_isInteger( _string )
{
	foreach (char in _string)
	{
		if (char < 48 || char > 57) return false;
	}
	return true;
}

local function msu_SemVer_isSemVer( _string )
{
	if (typeof _string != "string") return false;
	return ::Hooks.__SemVerRegex.capture(_string) != null;
}

::Hooks.Operator <- {
	LT = 1, // <
	LE = 2, // <=
	EQ = 3, // ==
	NE = 4 // !=
	GE = 5 // >=
	GT = 6, // >
} // non MSU ghetto enum

::Hooks.CompatibilityCheckResult <- {
	Success = 0,
	TooSmall = 1,
	TooBig = 2,
	Incorrect = 3,
	ModMissing = 4,
	ModPresent = 5
}

::Hooks.CompatibilityType <- {
	Requirement = 1,
	Incompatibility = 2
}

::Hooks.CompatibilityData <- class
{
	ModID = null;
	Version = null;
	Operator = null;
	CompatibilityType = null;

	constructor( _modID, _compatibilityType )
	{
		this.ModID = _modID;
		this.CompatibilityType = _compatibilityType;
	}

	function getModID()
	{
		return this.ModID;
	}

	function setVersionRequirements( _version, _operator )
	{
		if (msu_SemVer_isSemVer(_version))
		{
			this.Version = ::Hooks.ModVersion(_version);
		}
		else
		{
			this.Version = _version.tofloat(); // purely for backwards compatibility with Adam's Hooks
		}
		this.Operator = _operator;
	}

	function __processCmpResult( _cmpResult )
	{
		if (_cmpResult < 0)
		{
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
		if (this.Operator >= ::Hooks.Operator.NE)
			return ::Hooks.CompatibilityCheckResult.Success;
		return ::Hooks.CompatibilityCheckResult.TooBig;
	}

	function validateModVersion( _mod )
	{
		local cmpTypeModifier = this.CompatibilityType == ::Hooks.CompatibilityType.Requirement ? 1 : -1;
		if (typeof _mod.getVersion() == "float" && typeof this.Version == "instance")
			return this.__processCmpResult(1 * cmpTypeModifier);
		if (typeof _mod.getVersion() == "instance" && typeof this.Version == "float")
			return this.__processCmpResult(-1 * cmpTypeModifier);
		return this.__processCmpResult((_mod.getVersion() <=> this.Version) * cmpTypeModifier);
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
		if (!(this.ModID in _mods));
			return ::Hooks.CompatibilityCheckResult.Success;
		if (this.Version == null)
			return ::Hooks.CompatibilityCheckResult.ModPresent;
		return this.validateModVersion(_mods[this.ModID]);
	}
}
