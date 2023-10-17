::Hooks.QueuedFunction <- class
{
	ID = null;
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
		this.setupID();
	}

	function setFunction( _function )
	{
		this.Function = _function;
	}

	function setLoadOrderData( _data )
	{
		foreach (string in _data)
		{
			if (string[0] == 60)
				this.LoadBefore.push(string.slice(1));
			if (string[0] == 62)
				this.LoadAfter.push(string.slice(1));
		}
	}

	function getID()
	{
		return this.ID;
	}

	function setupID()
	{
		this.ID = this.getModID();

		if (this.LoadBefore.len() != 0 || this.LoadAfter.len() != 0)
		{
			this.ID += " ["
			if (this.LoadBefore.len() != 0)
			{
				this.ID += "Before: " + this.LoadBefore.reduce(@(a, b) a + ", " + b);
				if (this.LoadAfter.len() != 0)
				{
					this.ID += " | ";
				}
			}
			if (this.LoadAfter.len() != 0)
			{
				this.ID += "After: " + this.LoadAfter.reduce(@(a, b) a + ", " + b);
			}
			this.ID += "]";
		}
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

	function loadsBefore( _qFunc )
	{
		if (this.getLoadBefore().find(_qFunc.getModID()) != null)
		{
			foreach (id in this.getLoadAfter())
			{
				if (_qFunc.getLoadBefore().find(id) != null)
					return false;
			}

			return true;
		}

		return false;
	}

	function loadsAfter( _qFunc )
	{
		if (this.getLoadBefore().find(_qFunc.getModID()) != null)
			return false;

		if (this.getLoadAfter().find(_qFunc.getModID()) != null)
			return true;

		return false;
	}
}
