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

					if (q.loadsBefore(qFunc))
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
		local ret = [];
		foreach (func in this.QueuedFunctions)
		{
			if (func.getModID() == _modID)
				ret.push(func);
		}
		return ret;
	}

	function getSorted()
	{
		local ret = [];
		foreach (height in this.Sets)
		{
			foreach (qFunc in height)
			{
				ret.push(qFunc);
			}
		}
		return ret;
	}

	function visit( _queuedFunction, _chain )
	{
		_chain.push(_queuedFunction.getID());
		local height;
		if (_queuedFunction in this.Heights)
		{
			height = this.Heights[_queuedFunction];
			if (height == 0)
			{
				local modList = "";
				for (local i = 0; i < _chain.len(); ++i)
				{
					modList = (i == 0 ? _chain[i] : modList + " -> " + _chain[i]);
				}
				throw "Dependency conflict involving mod(s) " + modList + ".";
			}
		}
		else
		{
			this.Heights[_queuedFunction] <- 0;
			height = 0;
			if (_queuedFunction in this.Deps)
			{
				foreach (dep in this.Deps[_queuedFunction])
				{
					height = ::Math.max(height, this.visit(dep, _chain));
				}
			}

			if (height == this.Sets.len())
				this.Sets.append([]);

			this.Sets[height].append(_queuedFunction);
			++height;
			this.Heights[_queuedFunction] = height;
		}
		_chain.pop();
		return height;
	}
}
