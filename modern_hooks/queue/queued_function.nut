::Hooks.QueuedFunction <- class
{
	LoadBefore = null;
	LoadAfter = null;
	ID = null;
	Function = null;
	Mod = null;

	constructor(_id, _mod)
	{
		this.LoadBefore = [];
		this.LoadAfter = [];
		this.ID = _id;
		this.Mod = _mod;
	}

	function setFunction( _function )
	{
		this.Function = _function;
	}

	function getFunction()
	{
		return this.Function;
	}

	function clear()
	{
		this.Mod = null; // circular reference otherwise, technically gets cleaned
	}

	function getID()
	{
		return this.ID;
	}

	function getFullID()
	{
		if (this.getID() == null)
			return this.Mod.getID();
		return this.Mod.getID() + "|" + this.getID() ;
	}

	function getLoadAfter()
	{
		return this.LoadAfter;
	}

	function getLoadBefore()
	{
		return this.LoadBefore;
	}
}
