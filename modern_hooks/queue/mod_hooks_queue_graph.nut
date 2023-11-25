// Sorts mods using the same algorithm as Adam's mod hooks
::Hooks.ModHooksQueueGraph <- class
{
	Deps = null;
	Sets = null;
	Heights = null;
	Chain = null;
	QueuedFunctions = null;

	constructor( _queuedFunctions )
	{
		this.Deps = {};
		this.Sets = [];
		this.Heights = {};
		this.Chain = [];
		this.QueuedFunctions = _queuedFunctions;

		foreach (q in _queuedFunctions)
		{
			local order = clone q.getLoadBefore();
			order.extend(q.getLoadAfter());

			foreach (id in order)
			{
				local qFuncs = this.getQueuedFunctionsByModID(id);
				foreach (qFunc in qFuncs)
				{
					local before = qFunc;
					local after = q;

					if (this.loadsBefore(q, qFunc))
					{
						before = after;
						after = qFunc;
					}

					if (!(after in this.Deps)) 
						this.Deps[after] <- [];
					this.Deps[after].push(before);
				}				
			}
		}

		foreach (func in _queuedFunctions)
		{
			this.visit(func, []);
		}
	}

	function getQueuedFunctionsByModID( _modID )
	{
		return this.QueuedFunctions.filter(@(_i, _func) _func.getModID() == _modID);
	}

	function getSorted()
	{
		local ret = [];
		foreach (height in this.Sets)
			ret.extend(height);
		return ret;
	}

	function visit( _queuedFunction, _chain )
	{
		_chain.push(_queuedFunction);
		local height;
		if (_queuedFunction in this.Heights)
		{
			height = this.Heights[_queuedFunction];
			if (height == 0)
			{
				local mods = _chain.map(@(_a) _a.getModID() + " function " + _a.getFunctionID()).reduce(@(_a, _b) _a + " -> " + _b);
				::Hooks.errorAndThrow("Dependency conflict involving mod(s) " + mods + ".");
			}
		}
		else
		{
			this.Heights[_queuedFunction] <- 0;
			height = 0;
			if (_queuedFunction in this.Deps)
				foreach (dep in this.Deps[_queuedFunction])
					height = ::Math.max(height, this.visit(dep, _chain));

			if (height == this.Sets.len())
				this.Sets.append([]);

			this.Sets[height].append(_queuedFunction);
			++height;
			this.Heights[_queuedFunction] = height;
		}
		_chain.pop();
		return height;
	}

	function loadsBefore( _qFunc1, _qFunc2 )
	{
		if (_qFunc1.getLoadBefore().find(_qFunc2.getModID()) != null)
		{
			foreach (id in _qFunc1.getLoadAfter())
			{
				if (_qFunc2.getLoadBefore().find(id) != null)
					return false;
			}
			return true;
		}

		return false;
	}
}
