::Hooks <- {
	ID = "mod_modern_hooks",
	Version = "0.1.0",
	Name = "Modern Hooks",
	Classes = {
		/*"path/to/file" : {
			RawHooks = {
				Hooks = []
			},
			LeafHooks = {
				Hooks = [],
				Descendants = []
			},
		}*/
	},
	CachedModNames = {
		mod_msu = "Modding Standards & Utilities",
		dlc_lindwurm = "DLC: Lindwurm",
		dlc_unhold = "DLC: Beasts & Exploration",
		dlc_wildmen = "DLC: Warriors of the North",
		dlc_desert = "DLC: Blazing Deserts",
		dlc_paladins = "DLC: Of Flesh and Faith"
	}
	Mods = {},
	JSFiles = [],
	CSSFiles = [],
	RootState = null,
	MainMenuState = null,
	DebugMode = true,
	__SemVerRegex = regexp("^((?:(?:0|[1-9]\\d*)\\.){2}(?:0|[1-9]\\d*))(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$"),
	__VersionOperatorRegex = regexp("^((?:!|=|<|>)?=?)")
}

::include("modern_hooks/enums");
::include("modern_hooks/private_globals");
::include("modern_hooks/public_globals");
::Hooks.__inform("=================Initialized Hooks=================");
foreach (file in ::IO.enumerateFiles("modern_hooks/queue"))
	::include(file);

::setdebughook(::Hooks.__debughook.bindenv(::Hooks));
