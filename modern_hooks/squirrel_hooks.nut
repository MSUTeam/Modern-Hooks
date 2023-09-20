local inherit = ::inherit;
::inherit = function( _src, _prototype )
{
	::Hooks.__initClass(_src);
	local ret = inherit(_src, _prototype);
	if (!::Hooks.BBClass[_src].Processed)
		::Hooks.__processRawHooks(_src);
	return ret;
}
