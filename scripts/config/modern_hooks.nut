::Hooks <- {
	ID = "mod_modern_hooks",
	Version = "0.4.8",
	Name = "Modern Hooks",
	SQClass = {},
	BBClass = {
		/* "scripts/..." : {
			Mods = {
				mod_modern_hooks = {
					RawHooks = [],
					TreeHooks = [],
					MetaHooks = []
				}
			},
			Descendants = []
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
	OrderedMods = [],
	JSFiles = [],
	CSSFiles = [],
	LateJSFiles = [],
	AfterHooksBucket = null,
	FirstWorldInitBucket = null,
	RootState = null,
	MainMenuState = null,
	DebugMode = false,
	__SemVerRegex = regexp("^((?:(?:0|[1-9]\\d*)\\.){2}(?:0|[1-9]\\d*))(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$"),
	__VersionOperatorRegex = regexp("^((?:!|=|<|>)?=?)"),
	__OverloadedFuncNameRegex = regexp("^__sqrat_ol_ \\w+_(\\d+)$"),
	__ModIDRegex = regexp(@"^\w+"),
	__ModOperatorAndVersionRegex = regexp(@"^((?:!|>|<|=)=?) ([^ ]+)"),
	__ModNameRegex = regexp(@"^\((.+)\)"),
	__ModDetailsRegex = regexp(@"^\[(.+)\]"),
	__OldHooksOperatorAndVersionRegex = regexp(@"^\(([<>!=]?=?)([\w\.\+\-]+)\)"),
	__OldHooksRequirementOperatorRegex = regexp(@"^[!<>]"),
	__IntFloatRegex = regexp("^\\d+(?:\\.\\d+)?$"),
	__TacticalEntityPath = "scripts/entity/tactical/entity",
	__WorldEntityPath = "scripts/entity/tactical/entity"
}

::include("modern_hooks/enums");
::include("modern_hooks/q_object");
::include("modern_hooks/private_globals");
::include("modern_hooks/public_globals");
::include("modern_hooks/squirrel_hooks");
foreach (file in ::IO.enumerateFiles("modern_hooks/queue"))
	::include(file);
::Hooks.JSConnection <- ::new("scripts/mods/modern_hooks/js_connection");
::Hooks.Popup <- ::Hooks.JSConnection;
::Hooks.registerCSS("ui/mods/modern_hooks/main.css");
::Hooks.inform("=================Initialized Hooks=================");
::setdebughook(::Hooks.__debughook.bindenv(::Hooks));
