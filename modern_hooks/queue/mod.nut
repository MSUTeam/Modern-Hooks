::Hooks.SQClass.Mod <- class
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
		if (::Hooks.__msu_SemVer_isSemVer(_version))
			this.Version = ::Hooks.SQClass.ModVersion(_version);
		else
			this.Version = _version.tofloat(); // purely for backwards compatibility with Adam's Hooks

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
			case null:
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

	function getQueuedFunctions()
	{
		return this.QueuedFunctions;
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

	function __parseCompatibilityModInfo( _modInfo )
	{
		local capture = ::Hooks.__CompatibilityRegex.capture(_modInfo);
		if (capture == null)
			::Hooks.errorAndThrow(format("Queue information %s wasn't formatted correctly by mod %s (%s)", _modInfo, this.getID(), this.getName()));
		local ret = {
			ID = ::Hooks.__msu_regexMatch(capture, _modInfo, 1),
			Version = ::Hooks.__msu_regexMatch(capture, _modInfo, 3),
			Operator = null,
			Name = ::Hooks.__msu_regexMatch(capture, _modInfo, 4)
		}
		if (ret.Version != null)
			ret.Operator = this.__parseOperatorString(::Hooks.__msu_regexMatch(capture, _modInfo, 2))
		return ret;
	}

	function require( ... )
	{
		foreach (modInfo in vargv)
		{
			local parsed = this.__parseCompatibilityModInfo(modInfo);
			this.CompatibilityData.push(::Hooks.SQClass.CompatibilityData(
				parsed.ID,
				::Hooks.CompatibilityType.Requirement,
				parsed.Version,
				parsed.Operator,
				parsed.Name));
		}
	}

	function conflictWith( ... )
	{
		foreach (modInfo in vargv)
		{
			local parsed = this.__parseCompatibilityModInfo(modInfo);
			this.CompatibilityData.push(::Hooks.SQClass.CompatibilityData(
				parsed.ID,
				::Hooks.CompatibilityType.Incompatibility,
				parsed.Version,
				parsed.Operator,
				parsed.Name));
		}
	}

	function queue( ... )
	{
		local bucket;
		if (typeof vargv[vargv.len()-1] == "integer")
			bucket = vargv.pop();
		if (typeof vargv[vargv.len()-1] != "function")
			::Hooks.errorAndThrow(format("Mod %s (%s) did not pass a function as the last parameter for queue", this.getID(), this.getName()));
		local func = vargv.pop();
		this.QueuedFunctions.push(::Hooks.QueuedFunction(this, func, vargv, bucket));
	}

	function hook( _src, _func )
	{
		local params = _func.getinfos().parameters;
		if (params.len() != 2 || params[1] != "q")
			::Hooks.errorAndThrow(format("Modern Hooks requires that the function being used accepts a single parameter q for basic hooks"))
		::Hooks.__hook(this, _src, _func);
	}

	function hookTree( _src, _func )
	{
		local params = _func.getinfos().parameters;
		if (params.len() != 2 || params[1] != "q")
			::Hooks.errorAndThrow(format("Modern Hooks requires that the function being used accepts a single parameter q for basic leaf hooks"))
		::Hooks.__hookTree(this, _src, _func);
	}

	function rawHook( _src, _func )
	{
		local params = _func.getinfos().parameters;
		if (params.len() != 2 || params[1] != "p")
			::Hooks.errorAndThrow(format("Modern Hooks requires that the function being used accepts a single parameter p for raw hooks"))
		::Hooks.__rawHook(this, _src, _func);
	}

	function rawHookTree( _src, _func )
	{
		local params = _func.getinfos().parameters;
		if (params.len() != 2 || params[1] != "p")
			::Hooks.errorAndThrow(format("Modern Hooks requires that the function being used accepts a single parameter p for raw leaf hooks"))
		::Hooks.__rawHookTree(this, _src, _func);
	}
}
