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
		this.LoadBefore = {};
		this.LoadAfter = {};
		this.Mod = _mod;
		this.Function = _function;
		this.Bucket = _bucket;
		if (_loadOrderData != null)
			this.setLoadOrderData(_loadOrderData);
	}

	function setFunction( _function )
	{
		this.Function = _function;
	}

	function __parseDataForLoadTable( _dataArray, _table, _otherTable )
	{
		foreach (modInfo in _dataArray)
		{
			if (typeof modInfo == "string")
				modInfo = {ID = modInfo};
			if (modInfo.ID in _otherTable)
				delete _otherTable[modInfo.ID];
			_table[modInfo.ID] <- {}; // can maybe add stuff like version info later?
		}
	}

	function setLoadOrderData( _data )
	{
		if ("After" in _data)
			this.__parseDataForLoadTable(_data.After, this.LoadAfter, this.LoadBefore);
		if ("Before" in _data)
			this.__parseDataForLoadTable(_data.Before, this.LoadBefore, this.LoadAfter);
	}

	function getFunction()
	{
		return this.Function;
	}

	function clear()
	{
		this.Mod = null; // circular reference otherwise, technically gets cleaned
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
