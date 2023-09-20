local inherit = ::inherit;
::inherit = function( _src, _prototype )
{
	::include(_src);
	::Hooks.__initClass(_src);
	if (!::Hooks.BBClass[_src].Processed)
		::Hooks.__processRawHooks(_src);
	return inherit(_src, _prototype);
}
