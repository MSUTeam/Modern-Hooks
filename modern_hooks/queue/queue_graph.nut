::Hooks.QueueGraph <- class
{
	AdjList = null;
	InDegree = null;
	Visited = null;
	constructor()
	{
		this.AdjList = {};
		this.InDegree = {};
		this.Visited = {};
	}

	function addEdge( _start, _end )
	{
		if (!(_start in this.AdjList))
			this.AdjList[_start] <- [];
		this.AdjList[_start].push(_end);

		if (!(_end in this.InDegree))
			this.InDegree[_end] <- 0;
		this.InDegree[_end] += 1;
	}

	function __dfsVisit( _node, _stack )
	{
		this.Visited[_node] <- 'g' // gray
		_stack.push(_node);
		if (_node in this.AdjList)
		{
			foreach (neighbor in this.AdjList[_node])
			{
				if (!(neighbor in this.Visited))
				{
					local stack = this.__dfsVisit(neighbor, _stack);
					if (stack != null)
						return stack;
				}
				else if (this.Visited[neighbor] == 'g')
				{
					_stack.push(neighbor);
					return _stack.slice(_stack.find(neighbor));
				}
			}
		}
		_stack.pop();
		this.Visited[_node] = 'b' // black;
		return null;
	}

	function findCycle()
	{
		foreach (node, array in this.AdjList)
		{
			if (!(node in this.Visited))
			{
				local stack = this.__dfsVisit(node, []);
				if (stack != null)
				{
					return stack;
				}
			}
		}
		return null;
	}

	function topologicalSort()
	{
		local cycleNodes = this.findCycle();
		if (cycleNodes != null)
		{
			::Hooks.__errorAndThrow(format("There is a dependency cycle between the Mods: %s",
				cycleNodes.filter(@(_i, _e)_e instanceof ::Hooks.QueuedFunction)
					.map(@(_e) format("%s (%s function: %i)", _e.getMod().getID(), _e.getMod().getName(), _e.getFunctionID()) )
					.reduce(@(_a, _b) _a + ", " + _b)));
		}
		local queue = [];
		foreach (node, array in this.AdjList)
		{
			if (!(node in this.InDegree) || this.InDegree[node] == 0)
			{
				queue.push(node);
			}
		}

		local sortedNodes = [];
		while (queue.len() != 0)
		{
			local node = queue.pop();
			sortedNodes.push(node);
			if (!(node in this.AdjList))
				continue;
			foreach (neighbor in this.AdjList[node])
			{
				this.InDegree[neighbor] -= 1;
				if (this.InDegree[neighbor] == 0)
					queue.push(neighbor);
			}
		}
		sortedNodes.reverse()
		return sortedNodes;
	}
}
