::Hooks.__Q <- {
	function buildTargetString( _q )
	{
		if (!(_q instanceof ::Hooks.__Q.QTree))
			return _q.__Src;
		return format("%s (which is a descendent of hookTree target %s)", _q.__Src, _q.__Target);
	}

	function findInAncestors( _prototype, _key, _onStep = @()null )
	{
		local p = _prototype;
		local found = false;
		do
		{
			if (!(_key in p))
			{
				_onStep();
				continue;
			}
			found = true;
			break;
		}
		while ("SuperName" in p && (p = p[p.SuperName]))
		return found ? p : null;
	}

	function findInAncestorsM( _prototype, _key, _onStep = @()null )
	{
		local p = _prototype;
		local found = false;
		do
		{
			if (!(_key in p.m))
			{
				_onStep();
				continue;
			}
			found = true;
			break;
		}
		while ("SuperName" in p && (p = p[p.SuperName]) && "m" in p);
		return found ? p : null;
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
		local p = this.findInAncestorsM(_q.__Prototype, _key)
		if (p != null)
			::Hooks.error(format("Mod %s (%s) is adding a new field %s to bb class %s, but that field already exists in %s which is either the class itself or an ancestor", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q), p == _q.__Prototype ? _q.__Src : ::IO.scriptFilenameByHash(p.ClassNameHash)));
		_q.__Prototype.m[_key] <- _value;
	}

	function delSlot( _q, _key )
	{
		if (!(_key in _q.__Prototype))
			::Hooks.errorAndThrow(format("Mod %s (%s) is trying to remove function '%s' from %s, but this function does not exist in this class.", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q)))
		return delete _q.__Prototype[_key];
	}

	function delSlotM( _q, _key )
	{
		if (!(_key in _q.__Prototype.m))
			::Hooks.errorAndThrow(format("Mod %s (%s) is trying to remove field '%s' from %s, but this field does not exist in this class.", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q)))
		return delete _q.__Prototype.m[_key];
	}

	function foreach_generator(_table)
	{
		foreach (key, value in _table)
			yield key;
		return null;
	}

	function nexti( _qOrQm, _table, _prev )
	{
		if (_prev == null)
			_qOrQm.__NextIGenerator = this.foreach_generator(_table);
		local ret = resume _qOrQm.__NextIGenerator;
		if (ret == null)
			_qOrQm.__NextIGenerator = null;
		return ret;
	}

	function validateParameters( _q, _key, _oldInfos, _newInfos )
	{
		if (_oldInfos.native == true)
			return;

		local oldParams = _oldInfos.parameters;
		local newParams = _newInfos.parameters;
		local oldHasVargv = oldParams[oldParams.len()-1] == "...";
		local newHasVargv = newParams[newParams.len()-1] == "...";
		if (oldHasVargv || newHasVargv)
		{
			// For vargv-using functions we only want to error if the number of non-vargv
			// parameters is different between the old and new functions
			if (!oldHasVargv && newHasVargv)
			{
				if (newParams.len() - 2 > oldParams.len())
					::Hooks.warn(format("Mod %s (%s) is wrapping function %s in bb class %s with a vargv-using function but is increasing the number of non-vargv parameters from %i to %i", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q), oldParams.len() - 1, newParams.len() - 3));
			}
			else if (oldHasVargv && !newHasVargv)
			{
				if (oldParams.len() - 2 > newParams.len())
					::Hooks.warn(format("Mod %s (%s) is wrapping a vargv-using function %s in bb class %s with a non-vargv function with an increased number of non-vargv parameters (%i to %i)", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q), oldParams.len() - 3, newParams.len() - 1));
			}
		}
		else if (oldParams.len() != newParams.len())
		{
			if (oldParams.len() - _oldInfos.defparams.len() == newParams.len() - _newInfos.defparams.len())
			{
				::logInfo(format("Mod %s (%s) is wrapping function %s in bb class %s with a different number of parameters, but the additional parameters are optional, so this is probably fine (used to be %i, wrapper returned function with %i)", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q), oldParams.len()-1, newParams.len()-1))
			}
			else
			{
				::Hooks.warn(format("Mod %s (%s) is wrapping function %s in bb class %s with a different number of parameters (used to be %i, wrapper returned function with %i)", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q), oldParams.len()-1, newParams.len()-1))
			}
		}
	}

	function setNative( _q, _key, _value )
	{
		local p = this.findInAncestors(_q.__Prototype, "onInit")
		if (p == null)
			::Hooks.errorAndThrow(format("Mod %s (%s) is using a native function wrapper on function %s in class %s which doesn't have (or inherit) an onInit function", _q.__Mod.getID(), _q.__Mod.getName(), _key, _q.__Src));
		p = this.findInAncestors(_q.__Prototype, _key);
		if (p != null)
			::Hooks.error(format("Mod %s (%s) is using a native function wrapper on function %s in class %s, but that function already exists in %s which is either the target class or an ancestor", _q.__Mod.getID(), _q.__Mod.getName(), _key, _q.__Src, ::IO.scriptFilenameByHash(p.ClassNameHash)));
		::Hooks.BBClass[_q.__Src].NativeHooks.push({
			Mod = _q.__Mod,
			hook = function(){
				_q.onInit = @(__original) function() {
					_q.__Prototype = this;
					::Hooks.__Q.setSquirrel(_q, _key, _value, true)
					return __original();
				}
			}
		});
	}

	function setSquirrel( _q, _key, _value, _instantiated = false )
	{
		local ancestorCounter = 0;
		local p = this.findInAncestors(_q.__Prototype, _key, @()++ancestorCounter);
		if (p == null)
			::Hooks.errorAndThrow(format("Mod %s (%s) failed to set function %s in bb class %s: there is no function to set in the class or any of its ancestors", _q.__Mod.getID(), _q.__Mod.getName(),  _key, this.buildTargetString(_q)));

		local oldFunction = p[_key];
		local oldInfos = oldFunction.getinfos();

		if (_instantiated == false && ancestorCounter > 1)
		{
			local declarationParams = clone oldInfos.parameters; // used in compilestring for function declaration
			local wrappedParams = clone declarationParams; // used in compilestring to call parent function

			if (declarationParams[declarationParams.len() - 1] == "...")
			{
				declarationParams.remove(declarationParams.len() - 2); // remove "vargv"
				wrappedParams.remove(wrappedParams.len() - 1); // remove "..."
			}
			else // function with vargv cannot have defparams
			{
				foreach (i, defparam in oldInfos.defparams)
				{
					declarationParams[declarationParams.len() - oldInfos.defparams.len() + i] += " = " + defparam;
				}
			}

			declarationParams.remove(0); // remove "this"
			wrappedParams.remove(0); // remove "this"
			declarationParams = declarationParams.len() == 0 ? "" : declarationParams.reduce(@(a, b) a + ", " + b);
			wrappedParams = wrappedParams.len() == 0 ? "" : wrappedParams.reduce(@(a, b) a + ", " + b);

			oldFunction = compilestring(format("return function (%s) { return this.%s.%s(%s); }", declarationParams, _q.__Prototype.SuperName, _key, wrappedParams))();
		}

		local newFunction
		try
		{
			if (_value.getinfos().parameters.len() == 1)
				newFunction = _value();
			else
				newFunction = _value(oldFunction);
		}
		catch (error)
		{
			::Hooks.errorAndThrow(format("The overwrite attempt by mod %s (%s) for function %s in class %s failed because of error: %s", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q), error));
		}
		this.validateParameters(_q, _key, oldInfos, newFunction.getinfos());

		_q.__Prototype[_key] <- newFunction;
	}

	function set( _q, _key, _value )
	{
		if (typeof _value != "function")
			::Hooks.errorAndThrow(format("Mod %s (%s) is trying to set key %s to a value other than a function in bb class %s", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q)));
		local wrapperParams = _value.getinfos().parameters;
		local numParams = wrapperParams.len()
		if (numParams == 1 || (numParams == 2 && wrapperParams[1] == "__original"))
			return this.setSquirrel(_q, _key, _value);
		else if (numParams == 2 && wrapperParams[1] == "__native")
			return this.setNative(_q, _key, _value);
		::Hooks.errorAndThrow(format("Mod %s (%s) failed to hook function %s in bb class %s. Use the q.<methodname> = @(__original) function (...) {...} syntax", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q)));
	}

	function setM( _q, _key, _value )
	{
		local p = this.findInAncestorsM(_q.__Prototype, _key);
		if (p == null)
			::Hooks.errorAndThrow(format("Mod %s (%s) tried to set field %s in bb class %s, but the field doesn't exist in the class or any of its ancestors", _q.__Mod.getID(), _q.__Mod.getName(), _key, this.buildTargetString(_q)));
		p.m[_key] = _value;
	}

	function get( _q, _key )
	{
		// if ("SuperName" in _q.__Prototype && _key == _q.__Prototype.SuperName) implement once people have poretd
		// 	return ::Hooks.__Q.Q(_q.__Mod, _q.__Src, _q.__Prototype[_q.SuperName]);
		if ("SuperName" in _q.__Prototype && _key == _q.__Prototype.SuperName)
			::Hooks.errorAndThrow(format("Mod %s (%s) tried to climb the inheritance chain for bb class %s. This is no longer necessary when using Modern Hooks. Apply hooks directly to the current class instead, and it will automatically climb if necessary.", _q.__Mod.getID(), _q.__Mod.getName(), _q.__Src));
		local p = this.findInAncestors(_q.__Prototype, _key);
		if (p == null)
			throw null;
		return p[_key];
	}

	function getM( _q, _key )
	{
		local p = this.findInAncestorsM(_q.__Prototype, _key);
		if (p == null)
			::Hooks.errorAndThrow(format("Mod %s (%s) is trying to get field %s for bb class %s, but that field doesn't exist in the class or any of its ancestors", _q.__Mod.getID(), _q.__Mod.getName(), _key, _q.__Src));
		return p.m[_key];
	}

	function contains( _table, _key )
	{
		return _key in _table;
	}
}

::Hooks.__Q.Q <- class {
	__Src = null;
	__Prototype = null;
	__Mod = null;
	__NextIGenerator = null;
	m = null;
	constructor(_mod, _src, _prototype)
	{
		this.m = ::Hooks.__Q.Qm(this);
		this.__Mod = _mod;
		this.__Src = _src;
		this.__Prototype = _prototype;
	}

	function _set( _key, _value )
	{
		return ::Hooks.__Q.set(this, _key, _value);
	}

	function _get( _key )
	{
		if (this.__Prototype == null)
			throw null;
		return ::Hooks.__Q.get(this, _key);
	}

	function _newslot( _key, _value )
	{
		return ::Hooks.__Q.newSlot(this, _key, _value);
	}

	function _delslot( _key )
	{
		return ::Hooks.__Q.delSlot(this, _key)
	}

	function _nexti( _prev )
	{
		return ::Hooks.__Q.nexti(this, this.__Prototype, _prev);
	}

	function contains( _key, _checkAncestors = false )
	{
		if (_checkAncestors == false)
			return _key in this.__Prototype;
		return ::Hooks.__Q.findInAncestors(this.__Prototype, _key) != null;
	}
}

::Hooks.__Q.QTree <- class extends ::Hooks.__Q.Q {
	__Target = null;
	constructor(_mod, _src, _prototype, _target)
	{
		base.constructor(_mod, _src, _prototype);
		this.__Target = _target;
	}
}

::Hooks.__Q.Qm <- class {
	Q = null;
	__NextIGenerator = null;

	constructor(_Q)
	{
		this.Q = _Q.weakref();
	}

	function _set( _key, _value )
	{
		return ::Hooks.__Q.setM(this.Q, _key, _value);
	}

	function _get( _key )
	{
		return ::Hooks.__Q.getM(this.Q, _key);
	}

	function _newslot( _key, _value )
	{
		return ::Hooks.__Q.newSlotM(this.Q, _key, _value);
	}

	function _delslot( _key )
	{
		return ::Hooks.__Q.delSlotM(this.Q, _key)
	}

	function _nexti( _prev )
	{
		return ::Hooks.__Q.nexti(this, this.Q.__Prototype.m, _prev);
	}

	function contains( _key, _checkAncestors = false )
	{
		if (_checkAncestors == false)
			return _key in this.Q.__Prototype.m;
		return ::Hooks.__Q.findInAncestorsM(this.Q.__Prototype, _key) != null;
	}
}
