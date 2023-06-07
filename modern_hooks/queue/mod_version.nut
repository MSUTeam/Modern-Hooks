// ported MSU functions
local msu_regexMatch = function( _capture, _string, _group )
{
	return _capture[_group].end > 0 && _capture[_group].begin < _string.len() ? _string.slice(_capture[_group].begin, _capture[_group].end) : null;
}

local msu_String_isInteger = function( _string )
{
	foreach (char in _string)
	{
		if (char < 48 || char > 57) return false;
	}
	return true;
}

::Hooks.ModVersion <- class
{
	MAJOR = null;
	MINOR = null;
	PATCH = null;
	PreRelease = null;
	MetaData = null;

	constructor( _semverString )
	{
		if (typeof _semverString != "string")
		{
			::Hooks.__error(format("_semverString must be of type string, it is currently a %s", typeof _semverString));
			throw "SemVer error";
		}
		local capture = ::Hooks.__SemVerRegex.capture(_semverString);
		if (capture == null)
		{
			::Hooks.__error(format("Given version '%s' is not formatted according to Semantic Versioning guidelines (see https://semver.org/)", _semverString));
			throw "SemVer error";
		}
		local version = split(msu_regexMatch(capture, _semverString, 1), ".").map(@(_v) _v.tointeger());
		this.MAJOR = version[0];
		this.MINOR = version[1];
		this.PATCH = version[2];
		local prerelease = msu_regexMatch(capture, _semverString, 2);
		if (prerelease != null)
			this.PreRelease = split(prerelease, ".")
		local metadata = msu_regexMatch(capture, _semverString, 3);
		if (metadata != null)
			this.MetaData = split(metadata, ".");
	}

	function getShortVersionString()
	{
		return this.MAJOR + "." + this.MINOR + "." + this.PATCH;
	}

	function getVersionString()
	{
		local ret = this.getShortVersionString();

		if (this.PreRelease != null)
		{
			ret += "-" + this.PreRelease.reduce(@(_a, _b) _a + "." + _b);
		}

		if (this.MetaData != null)
		{
			ret += "+" + this.MetaData.reduce(@(_a, _b) _a + "." + _b);
		}

		return ret;
	}

	function _cmp( _other )
	{
		if (!(_other instanceof ::Hooks.ModVersion))
		{
			::Hooks._error("Trying to compare semver version to something that isn't one");
			throw "SemVer error";
		}

		if (this.MAJOR > _other.MAJOR)
			return 1;
		if (this.MAJOR < _other.MAJOR)
			return -1;

		if (this.MINOR > _other.MINOR)
			return 1;
		if (this.MINOR < _other.MINOR)
			return -1;

		if (this.PATCH > _other.PATCH)
			return 1;
		if (this.PATCH < _other.PATCH)
			return -1;

		if (this.PreRelease == null || _other.PreRelease == null)
		{
			if (this.PreRelease == null && _other.PreRelease != null)
				return 1;
			else if (this.PreRelease != null && _other.PreRelease == null)
				return -1;
			return 0;
		}

		for (local i = 0; i < ::Math.min(_other.PreRelease.len(), this.PreRelease.len()); ++i)
		{
			local isInt1 = msu_String_isInteger(this.PreRelease[i]);
			local isInt2 = msu_String_isInteger(_other.PreRelease[i]);

			if (isInt1 || isInt2)
			{
				if (isInt1 && isInt2)
				{
					local int1 = this.PreRelease[i].tointeger();
					local int2 = _other.PreRelease[i].tointeger();
					if (int1 < int2) return -1;
					else if (int1 > int2) return 1;
				}
				else
				{
					if (isInt1) return -1;
					else return 1;
				}
			}
			else
			{
				if (this.PreRelease[i] > _other.PreRelease[i]) return 1;
				else if (this.PreRelease[i] < _other.PreRelease[i]) return -1;
			}
		}

		if (this.PreRelease.len() > _other.PreRelease.len()) return 1;
		else if (this.PreRelease.len() < _other.PreRelease.len()) return -1;
		return 0;
	}
}
