::Hooks.__Q <- {
	Q = {
		__Src = null,
		__Prototype = null,
		__Mod = null,
		m = {}
	},
	QTree = {
		__Target = null,
		__Src = null,
		__Prototype = null,
		__Mod = null,
		m = {}
	}
	QMeta = {
		function _set( _key, _value )
		{
			return ::Hooks.__Q.set(::Hooks.__Q.Q, _key, _value);
		}

		function _get( _key )
		{
			return ::Hooks.__Q.get(::Hooks.__Q.Q, _key);
		}

		function _newslot( _key, _value )
		{
			return ::Hooks.__Q.newSlot(::Hooks.__Q.Q, _key, _value);
		}

		function _delslot( _key )
		{
			// TODO
		}

		function _nexti( _prev )
		{
			// TODO
		}

		function contains( _key )
		{
			return ::Hooks.__Q.contains(::Hooks.__Q.Q.__Prototype, _key);
		}
	},
	MMeta = {
		function _set( _key, _value )
		{
			return ::Hooks.__Q.setM(::Hooks.__Q.Q, _key, _value);
		}

		function _get( _key )
		{
			return ::Hooks.__Q.getM(::Hooks.__Q.Q, _key);
		}

		function _newslot( _key, _value )
		{
			return ::Hooks.__Q.newSlotM(::Hooks.__Q.Q, _key, _value);
		}

		function _delslot( _key )
		{
			// TODO
		}

		function _nexti( _prev )
		{
			// TODO
		}

		function contains( _key )
		{
			return ::Hooks.__Q.contains(::Hooks.__Q.Q.__Prototype.m, _key);
		}
	},
	QTreeMeta = {
		function _set( _key, _value )
		{
			return ::Hooks.__Q.set(::Hooks.__Q.QTree, _key, _value);
		}

		function _get( _key )
		{
			return ::Hooks.__Q.get(::Hooks.__Q.QTree, _key);
		}

		function _newslot( _key, _value )
		{
			return ::Hooks.__Q.newSlot(::Hooks.__Q.QTree, _key, _value);
		}

		function _delslot( _key )
		{
			// TODO
		}

		function _nexti( _prev )
		{
			// TODO
		}

		function contains( _key )
		{
			return ::Hooks.__Q.contains(::Hooks.__Q.QTree.__Prototype, _key);
		}
	},
	MTreeMeta = {
		function _set( _key, _value )
		{
			return ::Hooks.__Q.setM(::Hooks.__Q.QTree, _key, _value);
		}

		function _get( _key )
		{
			return ::Hooks.__Q.getM(::Hooks.__Q.QTree, _key);
		}

		function _newslot( _key, _value )
		{
			return ::Hooks.__Q.newSlotM(::Hooks.__Q.QTree, _key, _value);
		}

		function _delslot( _key )
		{
			// TODO
		}

		function _nexti( _prev )
		{
			// TODO
		}

		function contains( _key )
		{
			return ::Hooks.__Q.contains(::Hooks.__Q.QTree.__Prototype.m, _key);
		}
	}

	function buildTargetString( _q )
	{
		if (!this.isQTree(_q))
			return _q.__Src;
		return format("%s (which is a descendent of hookTree target %s)", _q.__Src, _q.__Target);
	}

	function isQTree( _q )
	{
		return "__Target" in _q
	}

	function newSlot( _q, _key, _value )
	{
		if (typeof _value != "function")
			::Hooks.errorAndThrow(format("Mod %s (%s) is trying to add key \'%s\' to %s. The key's value must be a function. Fields must instead be added to the class's \'m\' table.", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q)));
		local p = _q.__Prototype;
		if (_key in p)
		{
			::Hooks.warn(format("Mod %s (%s) is adding a new function %s to %s, but that function already exists in the bb class", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q)));
		}
		_q.__Prototype[_key] <- _value;
	}

	function newSlotM( _q, _key, _value )
	{
		local p = _q.__Prototype;
		do
		{
			if (!(_key in p.m))
				continue;
			::Hooks.error(format("Mod %s (%s) is adding a new field %s to bb class %s, but that field already exists in %s which is either the class itself or an ancestor", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q), p == _q.__Prototype ? _q.__Src : ::IO.scriptFilenameByHash(p.ClassNameHash)));
			break;
		}
		while ("SuperName" in p && (p = p[p.SuperName]) && "m" in p)
		_q.__Prototype.m[_key] <- _value;
	}

	function set( _q, _key, _value )
	{
		if (typeof _value != "function")
			::Hooks.errorAndThrow(format("Mod %s (%s) is trying to set key %s to a value other than a function in bb class %s", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q)));
		local wrapperParams = _value.getinfos().parameters;
		if (wrapperParams.len() != 2 || wrapperParams[1] != "__original")
			::Hooks.errorAndThrow(format("Mod %s (%s) failed to hook function %s in bb class %s. Use the q.<methodname> = @(__original) function (...) {...} syntax", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q)));

		local originalFunction;
		local ancestorCounter = 0;
		local p = _q.__Prototype;
		do
		{
			if (!(_key in p))
			{
				++ancestorCounter;
				continue;
			}
			originalFunction = p[_key];
			break;
		}
		while ("SuperName" in p && (p = p[p.SuperName]))

		if (originalFunction == null)
		{
			::Hooks.errorAndThrow(format("Mod %s (%s) failed to set function %s in bb class %s: there is no function to set in the class or any of its ancestors", _q.__Mod.getID(), _q.__Mod.getName(),  _key, this.buildTargetString(_q)));
			return;
		}
		local oldInfos = originalFunction.getinfos();
		local oldParams = oldInfos.parameters;
		if (ancestorCounter > 1)
		{
			local superName = _q.__Prototype.SuperName;
			originalFunction = function(...) {
				vargv.insert(0, this);
				return this[superName][_key].acall(vargv);
			}
		}

		local newFunc
		try
		{
			newFunc = _value(originalFunction);
		}
		catch (error)
		{
			::Hooks.errorAndThrow(format("The overwrite attempt by mod %s (%s) for function %s in class %s failed because of error: %s", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q), error));
		}

		local newParams = newFunc.getinfos().parameters;
		if (newParams[newParams.len()-1] == "..." || oldParams[oldParams.len()-1] == "...")
		{
			// one of the functions uses vargv, do not perform validation
		}
		else if (oldInfos.native == false)
		{
			if (oldParams.len() != newParams.len())
			{
				::Hooks.warn(format("Mod %s (%s) is wrapping function %s in bb class %s with a different number of parameters (used to be %i, wrapper returned function with %i)", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q), oldParams.len()-1, newParams.len()-1))
			}
		}
		else
		{
			::Hooks.errorAndThrow(format("Mod %s (%s) seems to be targetting a native function %s in bb class %s, which shouldn't be possible, please report this", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q)))
		}

		_q.__Prototype[_key] <- newFunc;
	}

	function setM( _q, _key, _value )
	{
		local m = null;
		local p = _q.__Prototype;
		do
		{
			if (!(_key in p.m))
				continue;
			m = p.m;
			break;
		}
		while ("SuperName" in p && (p = p[p.SuperName]) && ("m" in p))
		if (m == null)
			::Hooks.errorAndThrow(format("Mod %s (%s) tried to set field %s in bb class %s, but the field doesn't exist in the class or any of its ancestors", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q)));
		m[_key] = _value;
	}

	function get( _q, _key )
	{
		local value;
		local exists = false;
		local p = _q.__Prototype;
		if ("SuperName" in p && _key == p.SuperName)
			::Hooks.errorAndThrow("Modern hooks disallows getting the parent prototype from a basic hook"); // todo improve error
		do
		{
			if (_key in p)
			{
				value = p[_key];
				exists = true;
				break;
			}
		}
		while ("SuperName" in p && (p = p[p.SuperName]))

		if (exists)
			return value;
		throw null;
	}

	function getM( _q, _key )
	{
		local value;
		local found = false;
		local p = _q.__Prototype;
		do
		{
			if (!(_key in p.m)) // state.nut
				continue;
			found = true;
			value = p.m[_key];
			break;
		}
		while ("SuperName" in p && (p = p[p.SuperName]) && ("m" in p))
		if (!found)
			::Hooks.errorAndThrow(format("Mod %s (%s) is trying to get field %s for bb class %s, but that field doesn't exist in the class or any of its ancestors", _q.__Mod.getID(), _q.__Mod.getName(), _key, _q.__Src));
		return value;
	}

	function contains( _table, _key )
	{
		return _key in _table;
	}
}
::Hooks.__Q.Q.setdelegate(::Hooks.__Q.QMeta);
::Hooks.__Q.Q.m.setdelegate(::Hooks.__Q.MMeta);
::Hooks.__Q.QTree.setdelegate(::Hooks.__Q.QTreeMeta);
::Hooks.__Q.QTree.m.setdelegate(::Hooks.__Q.MTreeMeta);
