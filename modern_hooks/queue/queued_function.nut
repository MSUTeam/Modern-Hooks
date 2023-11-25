::Hooks.QueuedFunction <- class
{
	LoadBefore = null;
	LoadAfter = null;
	Function = null;
	Mod = null;
	Bucket = null;

	constructor(_mod, _function, _loadOrderData = null, _bucket = null)
	{
		if (_bucket == null)
			_bucket = ::Hooks.QueueBucket.Normal;
		this.LoadBefore = [];
		this.LoadAfter = [];
		this.Mod = _mod.weakref();
		this.Function = _function;
		this.Bucket = _bucket;
		if (_loadOrderData != null)
			this.setLoadOrderData(_loadOrderData);
	}

	function setFunction( _function )
	{
		this.Function = _function;
	}

	function setLoadOrderData( _data )
	{
		foreach (string in _data)
		{
			switch (string[0])
			{
				case 60:
					this.LoadBefore.push(string.slice(1));
					break;

				case 62:
					this.LoadAfter.push(string.slice(1));
					break;

				default:
					throw "load order information must start with < or > followed by the mod id";
			}
		}
	}

	function getDetailsString()
	{
		local ret = "";

		if (this.LoadBefore.len() != 0 || this.LoadAfter.len() != 0)
		{
			ret += " ["
			if (this.LoadBefore.len() != 0)
			{
				ret += "Before: " + this.LoadBefore.reduce(@(a, b) a + ", " + b);
				if (this.LoadAfter.len() != 0)
				{
					ret += " | ";
				}
			}
			if (this.LoadAfter.len() != 0)
			{
				ret += "After: " + this.LoadAfter.reduce(@(a, b) a + ", " + b);
			}
			ret += "]";
		}
		return ret;
	}

	function getFunction()
	{
		return this.Function;
	}

	function getModID()
	{
		return this.Mod.getID();
	}

	function getLoadAfter()
	{
		return this.LoadAfter;
	}

	function getLoadBefore()
	{
		return this.LoadBefore;
	}

	function getFunctionID()
	{
		return this.Mod.getQueuedFunctions().find(this) + 1;
	}

	function getBucket()
	{
		return this.Bucket;
	}

	function getMod()
	{
		return this.Mod;
	}
}
