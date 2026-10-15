/*
    TEH Antistasi Ultimate - arsenal_tehAmmoDisplayName

    Input:  [magazineClassname] call <registered function>;
    Output: display name for the CfgAmmo class used by this magazine (STRING).

    The cache lives in local missionNamespace; it is keyed by CfgAmmo classname.
    First magazine to request a non-overridden ammo class supplies extra naming
    clues from CfgMagazines (v0.6.0 heuristics). Later calls reuse that name.
    No reverse magazine index or full config scan is performed.

    Returns "" for an invalid magazine class or one without CfgAmmo ammo.
    No publicVariable/network synchronization is performed.
*/

params [["_magClass", "", [""]]];
if (_magClass isEqualTo "") exitWith {""};

private _magCfg = configFile >> "CfgMagazines" >> _magClass;
if !(isClass _magCfg) exitWith {""};

private _ammoClass = getText (_magCfg >> "ammo");
if (_ammoClass isEqualTo "") exitWith {""};

// Check the client-local persistent cache BEFORE allocating parser helpers.
private _cache = missionNamespace getVariable "A3A_tehAmmoDisplayNameCache";
if (isNil "_cache") then {
    _cache = createHashMap;
    missionNamespace setVariable ["A3A_tehAmmoDisplayNameCache", _cache];
};

private _name = _cache getOrDefault [_ammoClass, ""];
if (_name != "") exitWith {_name};

// Explicit names for ambiguous ammo shared by several different magazines.
// Exact classname match, evaluated only on a cold cache lookup.
_name = switch (_ammoClass) do {
    case "CMflareAmmo": {"Flare"};
    case "CMflare_Chaff_Ammo": {"Chaff"};
    case "DummyPylonAmmo": {"External Fuel Tank"};
    case "Laserbeam": {"Designator Batteries"};
    case "M_AT": {"AT Guided Rocket"};
    case "M_Zephyr": {"Zephyr Missile"};
    case "ammo_Missile_AMRAAM_C": {"AMRAAM C Missile"};
    case "ammo_Missile_AMRAAM_D": {"AMRAAM D Missile"};
    case "rhs_CMflare_Ammo": {"Flare [RHS]"};
    case "rhs_Laserbeam": {"9M133 Missile [RHS]"};
    case "rhssaf_mine_mrud_b_ammo": {"MRUD Mine [RHS]"};
    case "rhsusf_CMflare_Ammo": {"Flare [USF]"};
    case "Bo_Leaflets": {"Leaflets"};
    case "rhs_ammo_s8t": {"S-8T HEAT-T Rocket [RHS]"};
    default {""};
};
if (_name != "") exitWith {
    _cache set [_ammoClass, _name];
    _name
};

// Default name builder from Ammo Name Auditor v0.6.0.
// Its magazine-derived clues are used only on the FIRST lookup for each CfgAmmo.
private _caliberMap = createHashMapFromArray [
    ["46", "4.6"], ["545", "5.45"], ["556", "5.56"],
    ["57", "5.7"], ["570", "5.7"], ["58", "5.8"], ["580", "5.8"],
    ["65", "6.5"], ["650", "6.5"], ["68", "6.8"], ["680", "6.8"],
    ["75", "7.5"], ["762", "7.62"], ["765", "7.65"],
    ["792", "7.92"], ["86", "8.6"], ["93", "9.3"],
    ["127", "12.7"], ["145", "14.5"]
];
private _imperialMap = createHashMapFromArray [
    ["50AE", ".50 AE"], ["50BW", ".50 Beowulf"],
    ["50BMG", ".50 BMG"], ["357SW", ".357 S&W"],
    ["357SIG", ".357 SIG"], ["357MAG", ".357 Magnum"],
    ["40SW", ".40 S&W"], ["45ACP", ".45 ACP"],
    ["44MAG", ".44 Magnum"], ["38SPL", ".38 Special"],
    ["308WIN", ".308 Win"], ["300BLK", ".300 BLK"],
    ["338LM", ".338 LM"], ["408CT", ".408 CT"],
    ["454CASULL", ".454 Casull"], ["500SW", ".500 S&W"]
];
private _colors = ["BLUE", "GREEN", "ORANGE", "PURPLE", "RED", "WHITE", "YELLOW"];
private _separators = " _-,:;()[]<>/=|" + toString [9, 10, 13];

private _digitsOnly = {
    params ["_s"];
    _s != "" && {(_s splitString "0123456789") isEqualTo []}
};
private _numeric = {
    params ["_s"];
    if (_s == "" || {_s == "."}) exitWith {false};
    private _parts = _s splitString ".";
    (count _parts <= 2)
    && {(_s splitString "0123456789.") isEqualTo []}
    && {parseNumber _s > 0}
};
private _hasDigitsAndLetters = {
    params ["_s"];
    private _u = toUpper _s;
    (count (_u splitString "0123456789") > 0)
    && {count (_u splitString "ABCDEFGHIJKLMNOPQRSTUVWXYZ") > 0}
};
private _startsWith = {
    params ["_s", "_prefix"];
    (_s find _prefix) == 0
};

// Exact caliber token (never guess inches from an arbitrary integer).
private _caliberToken = {
    params ["_raw"];
    private _t = toUpper _raw;
    private _imperial = _imperialMap getOrDefault [_t, ""];
    if (_imperial != "") exitWith {_imperial};

    if (
        (count _t > 1) && {_t select [0, 1] == "."}
        && {[_t select [1]] call _digitsOnly}
    ) exitWith {_t};

    private _gaugePos = _t find "GAUGE";
    private _result = "";
    if (_gaugePos > 0 && {_gaugePos + 5 == count _t}) then {
        private _digits = _t select [0, _gaugePos];
        if ([_digits] call _digitsOnly) then {_result = _digits + " Gauge"};
    };
    if (_result != "") exitWith {_result};

    // Keep decimal dots: 7.62x51mm, 26.5mm.
    private _dims = _t splitString "X";
    if (count _dims == 2) then {
        _dims params ["_diameter", "_case"];
        private _n = count _case;
        if (_n > 2 && {_case select [_n - 2, 2] == "MM"}) then {
            _case = _case select [0, _n - 2];
        };
        if ([_diameter] call _numeric && {[_case] call _digitsOnly}) then {
            _result = format ["%1x%2mm", _caliberMap getOrDefault [_diameter, _diameter], _case];
        };
    };
    if (_result != "") exitWith {_result};

    // Allows compound tokens: 105mmHE, 127mmAP.
    private _mmPos = _t find "MM";
    if (_mmPos > 0) then {
        private _number = _t select [0, _mmPos];
        if ([_number] call _numeric) then {_result = _number + "mm"};
    };
    _result
};
private _findCaliber = {
    params ["_source"];
    private _tokens = (toUpper _source) splitString _separators;
    private _result = "";
    {
        _result = [_x] call _caliberToken;
        if (_result != "") exitWith {};
        if (_x == "GAUGE" && {_forEachIndex > 0}) then {
            private _previous = _tokens # (_forEachIndex - 1);
            if ([_previous] call _digitsOnly) then {_result = _previous + " Gauge"};
        };
        if (_result != "") exitWith {};
    } forEach _tokens;
    _result
};

// Extract bare numeric mm caliber ONLY in specific projectile classname contexts.
private _bareAmmoCaliber = {
    params ["_ammo", "_kind"];
    private _tokens = (toUpper _ammo) splitString "_";
    private _result = "";
    if (_kind != "Shell" && {_kind != "Bullet"}) exitWith {""};
    {
        if ([_x] call _digitsOnly && {parseNumber _x >= 20} && {parseNumber _x <= 460}) exitWith {
            _result = _x + "mm";
        };
    } forEach _tokens;
    _result
};

// Ammunition purpose; guidance is handled independently.
private _getType = {
    params ["_source"];
    private _tokens = (toUpper _source) splitString _separators;
    private _result = "";
    {
        private _candidate = switch (_x) do {
            case "BALL": {"Ball"}; case "FMJ": {"FMJ"};
            case "SME": {"SmE"}; case "MDZ": {"MDZ"};
            case "JHP": {"JHP"}; case "MHP": {"MHP"};
            case "SD": {"SD"}; case "AA": {"AA"};
            case "SLUG": {"Slug"}; case "PELLETS": {"Pellets"};
            case "BUCKSHOT": {"Buckshot"}; case "BUCK": {"Buckshot"};
            case "AP": {"AP"}; case "APDS": {"APDS"};
            case "APCR": {"APCR"}; case "APFSDS": {"APFSDS"};
            case "HE": {"HE"}; case "HEFRAG": {"HE-FRAG"};
            case "HEAT": {"HEAT"}; case "HESH": {"HESH"};
            case "HEP": {"HEP"}; case "HEDP": {"HEDP"};
            case "SAPHE": {"SAPHE"}; case "SABOT": {"Sabot"};
            case "AT": {"AT"}; case "SMOKE": {"Smoke"};
            case "FLARE": {"Flare"}; case "ILLUM": {"Illumination"};
            case "ILLUMINATION": {"Illumination"}; case "WP": {"WP"};
            case "CANISTER": {"Canister"}; case "CLUSTER": {"Cluster"};
            case "GPR": {"GPR"}; case "MP": {"MP"};
            case "FLASHBANG": {"Flashbang"}; case "PRACTICE": {"Practice"};
            case "MIXED": {"Mixed"}; case "BZT": {"BZT"};
            default {""};
        };
        if (_candidate == "") then {
            if ((_x find "HEAT") == 0 && {count _x > 4}) then {
                private _suffix = _x select [4];
                if ([_suffix] call _digitsOnly) then {_candidate = "HEAT " + _suffix};
            };
            if (_candidate == "" && {(_x find "SMOKE") == 0}) then {_candidate = "Smoke"};
            if (_candidate == "" && {(_x find "FLARE") == 0}) then {_candidate = "Flare"};
        };
        if (_candidate != "") exitWith {_result = _candidate};
    } forEach _tokens;

    if (_result == "HE" && {"FRAG" in _tokens}) then {_result = "HE-FRAG"};
    if (_result == "APFSDS" || {_result == "APDS"} || {_result == "HE"}) then {
        if ("T" in _tokens) then {_result = _result + "-T"};
    };
    if (_result == "HEAT" && {"MP" in _tokens}) then {_result = "HEAT-MP"};
    if (_result == "HEAT" && {"FS" in _tokens}) then {_result = "HEAT-FS"};
    if (_result in ["HEAT", "HEAT-MP", "HEAT-FS"] && {"T" in _tokens}) then {_result = _result + "-T"};
    if (_result == "HE-FRAG" && {"FS" in _tokens}) then {_result = _result + "-FS"};
    if (_result in ["HE-FRAG", "HE-FRAG-FS"] && {"T" in _tokens}) then {_result = _result + "-T"};
    _result
};

private _getColor = {
    params ["_ammo", "_kind"];
    private _tokens = (toUpper _ammo) splitString _separators;
    private _markers = [
        "TRACER", "SMOKE", "FLARE", "SIGNAL", "STAR", "STARCLUSTER",
        "ILLUM", "T", "CASE", "CASELESS", "APFSDS", "HE", "HEAT",
        "HEFRAG", "BALL", "NSPN"
    ];
    private _result = "";
    {
        private _token = _x;
        private _previous = if (_forEachIndex > 0) then {_tokens # (_forEachIndex - 1)} else {""};
        private _next = if (_forEachIndex + 1 < count _tokens) then {_tokens # (_forEachIndex + 1)} else {""};
        if (_token in _colors && {(_previous in _markers) || {_next in _markers} || {_kind == "Flare"}}) then {
            _result = (_token select [0, 1]) + (toLower (_token select [1]));
        };
        if (_result == "" && {(_token find "SMOKE") == 0 || {(_token find "FLARE") == 0} || {(_token find "STAR") == 0}}) then {
            {
                private _n = count _x;
                if (count _token > _n && {_token select [count _token - _n, _n] == _x}) exitWith {
                    _result = (_x select [0, 1]) + (toLower (_x select [1]));
                };
            } forEach _colors;
        };
        if (_result != "") exitWith {};
    } forEach _tokens;
    _result
};

// Determine projectile kind from a classname, and then (when unclear) its
// parent CfgAmmo classes. Magazine description is deliberately not involved.
private _getKind = {
    params ["_ammo", "_ammoCfg"];
    private _u = toUpper _ammo;
    private _tokens = _u splitString "_";
    private _root = _tokens param [0, ""];
    private _i = 0;
    if (_root in ["CUP", "RHS", "RHSUSF", "RHSAFRF", "RHSGREF", "RHSSAF"]) then {_i = 1};
    if ((_tokens param [_i, ""]) == "SUB") then {_i = _i + 1};
    if ((_tokens param [_i, ""]) == "AMMO") then {_i = _i + 1};
    _root = _tokens param [_i, ""];
    private _kind = switch (_root) do {
        case "SH": {"Shell"}; case "G": {"Grenade"};
        case "R": {"Rocket"}; case "ROCKET": {"Rocket"};
        case "M": {"Missile"}; case "MISSILE": {"Missile"};
        case "BOMB": {"Bomb"}; case "BO": {"Bomb"};
        case "MINE": {"Mine"}; case "F": {"Flare"};
        default {""};
    };
    if (_kind == "" && {_root == "MK"} && {[_tokens param [_i + 1, ""]] call _digitsOnly}) then {
        private _mk = parseNumber (_tokens param [_i + 1, ""]);
        if (_mk >= 80 && {_mk <= 84}) then {_kind = "Bomb"};
    };
    if ((_u find "FUELPOD") >= 0) exitWith {"Fuel Pod"};
    if ((_u find "SMOKELAUNCHER") >= 0) exitWith {"Launcher"};
    if ((_u find "SMOKESHELL") >= 0) exitWith {"Grenade"};
    if ((_u find "SIGNAL") >= 0 || {(_u find "NSPN") >= 0}) exitWith {"Flare"};
    if ((_u find "GRENADEHAND") >= 0) exitWith {"Grenade"};
    if ((_u find "FAB") >= 0 && {_kind == ""}) then {_kind = "Bomb"};
    if ((_u find "KAB") >= 0 && {_kind == ""}) then {_kind = "Bomb"};
    if ((_u find "MGM") >= 0 && {_kind == ""}) then {_kind = "Rocket"};
    if ((_u find "_ROCKET") >= 0 && {_kind == ""}) then {_kind = "Rocket"};
    if ((_u find "_BOMB") >= 0 && {_kind == ""}) then {_kind = "Bomb"};
    if ((_u find "9M") >= 0 && {_kind == ""}) then {_kind = "Missile"};
    if ((_u find "_3OF") >= 0 || {(_u find "_3WOF") >= 0} || {(_u find "_53OF") >= 0}) then {
        if (_kind == "") then {_kind = "Shell"};
    };
    if (_kind == "" && {(_u find "_BR412") >= 0 || {(_u find "_OF412") >= 0}}) then {_kind = "Shell"};
    if (_kind == "" && {(_u find "S24") >= 0}) then {_kind = "Rocket"};
    if (_kind == "" && {[_root] call _digitsOnly} && {parseNumber _root >= 20} && {parseNumber _root <= 460}) then {
        if ("WP" in _tokens || {"HE" in _tokens} || {"LASER" in _tokens}) then {_kind = "Shell"};
    };
    if (_kind == "" && {(_u find "_AGM") >= 0 || {(_u find "_AIM") >= 0} || {(_u find "_FGM") >= 0}}) then {_kind = "Missile"};
    if (_kind == "" && {(_u find "CUP_AGM") == 0}) then {_kind = "Missile"};

    if (_kind == "" && {isClass _ammoCfg}) then {
        private _parent = inheritsFrom _ammoCfg;
        private _depth = 0;
        while {!isNull _parent && {_depth < 12} && {_kind == ""}} do {
            private _p = toUpper (configName _parent);
            if ((_p find "MISSILEBASE") >= 0) then {_kind = "Missile"};
            if ((_p find "ROCKETBASE") >= 0) then {_kind = "Rocket"};
            if ((_p find "SHELLBASE") >= 0) then {_kind = "Shell"};
            if ((_p find "GRENADEBASE") >= 0) then {_kind = "Grenade"};
            if ((_p find "BOMBCORE") >= 0 || {(_p find "BOMBBASE") >= 0}) then {_kind = "Bomb"};
            _parent = inheritsFrom _parent;
            _depth = _depth + 1;
        };
    };
    _kind
};

// Uppercase alphanumeric technical designations without pretending to decode them.
private _normalizeModel = {
    params ["_raw"];
    private _u = toUpper _raw;
    if (_u == "SME") exitWith {"SmE"};
    if ((_u find "MK") == 0 && {count _u > 2}) exitWith {"Mk" + (_u select [2])};
    {
        private _prefix = _x;
        if ((_u find _prefix) == 0 && {count _u > count _prefix}) then {
            private _tail = _u select [count _prefix];
            if ([_tail select [0, 1]] call _digitsOnly) exitWith {
                _u = _prefix + "-" + _tail;
            };
        };
    } forEach ["AGM", "AIM", "FGM", "GBU", "MGM", "KAB", "FAB", "KH", "R", "S"];
    _u
};
private _modelIsTechnical = {
    params ["_token"];
    private _u = toUpper _token;
    if (_u in [
        "NO", "NOCARTRIDGE", "NOTRACER", "SUBSONIC", "SPLASH", "CASE", "CASELESS",
        "SMOKE", "SIGNAL", "HEAT55", "TECHNICAL", "TECHICAL", "PROXY", "DUMMY",
        "STARCLUSTER", "ILLUM", "GUIDED", "MIXED", "TRACER", "HEAT", "HEFRAG",
        "SME", "FLASHBANG", "PRACTICE", "PELLETS", "BUCKSHOT", "ROCKET"
    ]) exitWith {true};
    if (([_u] call _caliberToken) != "") exitWith {true};
    if ((_u find "RND") > 0) exitWith {true};
    if ((_u find "HEAT") == 0) exitWith {true};
    if ((_u find "FUELPOD") >= 0) exitWith {true};
    false
};

// Only ammo classname can provide the canonical identity/model.
private _getIdentityModel = {
    params ["_ammo", "_kind"];
    private _tokens = _ammo splitString "_";
    private _upper = _tokens apply {toUpper _x};
    private _identity = "";
    private _model = "";

    // AGM_114L_Hellfire_II, Missile_AA_03, etc.
    {
        private _idx = _upper find _x;
        if (_identity == "" && {_idx >= 0} && {_idx + 1 < count _tokens}) then {
            _identity = _x + "-" + (toUpper (_tokens # (_idx + 1)));
            if (_x == "AGM" && {_idx + 2 < count _tokens}) then {
                private _extra = [];
                {
                    private _t = toUpper _x;
                    if (_t in ["AT", "AP", "HE", "HEAT", "F", "T", "GUIDED", "TRACER", "POD"]) exitWith {};
                    _extra pushBack _x;
                } forEach (_tokens select [_idx + 2]);
                if (count _extra > 0) then {_identity = _identity + " " + (_extra joinString " ")};
            };
        };
    } forEach ["AGM", "AIM", "FGM", "GBU"];

    if (_identity == "" && {(_upper param [0, ""]) == "MISSILE"} && {(_upper param [1, ""]) == "AA"}) then {
        _identity = "AA-" + (_tokens param [2, ""]);
    };
    if (_identity == "" && {(_upper param [0, ""]) in ["BOMB", "ROCKET"]}) then {
        private _suffix = _tokens param [1, ""];
        if ([_suffix] call _digitsOnly) then {_identity = (_tokens # 0) + "-" + _suffix};
    };
    if (_identity == "" && {"MK" in _upper}) then {
        private _idx = _upper find "MK";
        private _digit = _upper param [_idx + 1, ""];
        if ([_digit] call _digitsOnly) then {_model = "Mk" + _digit};
    };
    if (_identity == "" && {(_upper param [0, ""]) == "AMMO"} && {(_upper param [1, ""]) == "BOMB"}) then {
        private _candidate = _upper param [2, ""];
        if (_candidate != "" && {!([_candidate] call _modelIsTechnical)}) then {_identity = _candidate};
    };
    if (_identity == "" && {(_upper param [0, ""]) == "CUP"}) then {
        private _candidate = _upper param [1, ""];
        if ([_candidate] call _hasDigitsAndLetters && {!([_candidate] call _modelIsTechnical)}) then {
            _model = [_candidate] call _normalizeModel;
        };
    };

    if (_identity == "") then {
        private _start = 0;
        if ((_upper param [0, ""]) in ["CUP", "RHS", "RHSUSF", "RHSAFRF", "RHSGREF", "RHSSAF"]) then {_start = 1};
        if ((_upper param [_start, ""]) == "SUB") then {_start = _start + 1};
        if ((_upper param [_start, ""]) == "AMMO") then {_start = _start + 1};
        if ((_upper param [_start, ""]) in ["B", "SH", "M", "R", "G", "F", "BO", "ROCKET", "MISSILE", "BOMB"]) then {_start = _start + 1};
        for "_i" from _start to ((count _tokens) - 1) do {
            private _token = _tokens # _i;
            private _u = toUpper _token;
            if (_model == "" && {[_u] call _hasDigitsAndLetters} && {!([_token] call _modelIsTechnical)}) then {
                _model = [_token] call _normalizeModel;
            };
        };
    };

    // Families are useful when caliber/model alone cannot identify a missile.
    if (_identity == "" && {_model == ""}) then {
        private _families = ["MAAWS", "MRAAWS", "SMAW", "TOW", "TOW2", "TITAN", "VORONA", "GRAD", "MLRS", "JAVELIN", "NLAW", "SIDEWINDER", "NSPN", "HYDRA", "VIKHR", "S5", "S8", "CRV7"];
        {
            if (_x in _upper) exitWith {_identity = _x};
        } forEach _families;
    };
    if (_identity == "" && {_model == ""} && {_kind == "Fuel Pod"}) then {
        private _candidate = _upper param [2, ""];
        if ([_candidate] call _hasDigitsAndLetters) then {_identity = [_candidate] call _normalizeModel};
    };
    if (_identity == "" && {_model == ""} && {_kind == "Flare"} && {"SIGNAL" in _upper}) then {_identity = "Signal"};
    if (_identity == "" && {_model == ""} && {_kind == "Flare"} && {"NSPN" in _upper}) then {_identity = "NSPN"};
    if (_identity == "" && {_model == ""} && {"SMOKELAUNCHERAMMO" in _upper}) then {_identity = "Smoke"};

    [_identity, _model]
};

// Source label, only one configSourceMod lookup per distinct ammo class.
private _getSourceTag = {
    params ["_ammo", "_cfg"];
    private _mod = if (isClass _cfg) then {configSourceMod _cfg} else {""};
    private _u = toUpper _mod;
    if ((_u find "CUP") >= 0) exitWith {"CUP"};
    if ((_u find "RHS") >= 0) exitWith {"RHS"};
    if (_u == "") then {
        private _name = toUpper _ammo;
        if ((_name find "CUP_") == 0) then {_mod = "CUP"};
        if ((_name find "RHS") == 0) then {_mod = "RHS"};
    };
    if (_mod in ["CUP", "RHS"]) exitWith {_mod};
    if (_u in [
        "", "A3", "CURATOR", "HELI", "KART", "MARK", "EXPANSION", "JETS",
        "ORANGE", "TANK", "ENOCH", "VN", "GM", "WS", "SPE", "CSLA", "RF", "EF"
    ]) exitWith {""};
    _mod
};

// Remove capacity tokens only. Don't strip weapon names from full fallback.
private _cleanDisplay = {
    params ["_s", "_count"];
    private _upperSkip = [format ["%1RND", _count], format ["%1X", _count], format ["%1x", _count]];
    private _words = (_s splitString " ") select {!((toUpper _x) in _upperSkip)};
    private _clean = _words joinString " ";
    if (_clean in ["-", "--"]) then {_clean = ""};
    _clean
};

// Traits are computed only on a miss in the persistent ammo-name cache.
private _getTraits = {
    params ["_ammo"];

    private _ammoCfg = configFile >> "CfgAmmo" >> _ammo;
    private _kind = [_ammo, _ammoCfg] call _getKind;
    private _cal = [_ammo] call _findCaliber;
    if (_cal == "") then {_cal = [_ammo, _kind] call _bareAmmoCaliber};
    // Bare 408 is ambiguous; only this known ammo naming pattern means .408.
    if (_cal == "" && {(toUpper _ammo) find "B_408_" >= 0}) then {_cal = ".408"};
    if (_cal == "265mm" && {_kind == "Flare"}) then {_cal = "26.5mm"};

    private _type = [_ammo] call _getType;
    private _identityModel = [_ammo, _kind] call _getIdentityModel;
    _identityModel params ["_identity", "_model"];

    private _tokens = (toUpper _ammo) splitString _separators;
    private _guidance = "";
    if ("LG" in _tokens || {"LASER" in _tokens}) then {
        _guidance = "Laser Guided";
    } else {
        if ("GUIDED" in _tokens) then {_guidance = "Guided"};
    };

    private _variants = [];
    if ("SUBSONIC" in _tokens) then {_variants pushBack "Subsonic"};
    if ("NOTRACER" in _tokens || {"NO" in _tokens && {"TRACER" in _tokens}}) then {_variants pushBack "No Tracer"};
    if ("SPLASH" in _tokens) then {_variants pushBack "Splash"};
    if ("CASELESS" in _tokens) then {_variants pushBack "Caseless"};
    if ("SME" in _tokens) then {_variants pushBack "SmE"};
    if ("BOAT" in _tokens && {(_ammo find "SmokeLauncher") >= 0}) then {_variants pushBack "Boat"};
    private _color = [_ammo, _kind] call _getColor;
    if (_color != "") then {_variants pushBack _color};
    if ("TRACER" in _tokens && {_color == ""} && {!("No Tracer" in _variants)}) then {_variants pushBack "Tracer"};

    // SmE precedes Ball; don't display it twice.
    if (_type == "SmE") then {_type = ""};
    if ((toUpper _ammo) find "SMAW" >= 0 && {"SR" in _tokens}) then {_type = "Spotting"};
    if (_type == "" && {"BALL" in _tokens}) then {_type = "Ball"};

    // Remove trailer variants that are already spelled out by the type.
    if (_type == "APFSDS-T") then {_variants = _variants - ["Tracer"]};
    private _origin = [_ammo, _ammoCfg] call _getSourceTag;
    [_cal, _identity, _model, _type, _kind, _guidance, _variants, _origin]
};

private _resolve = {
    params ["_cfg"];
    private _mag = configName _cfg;
    private _ammo = getText (_cfg >> "ammo");
    private _count = getNumber (_cfg >> "count");
    private _short = getText (_cfg >> "displayNameShort");
    private _display = getText (_cfg >> "displayName");
    private _desc = getText (_cfg >> "descriptionShort");

    ([_ammo] call _getTraits) params ["_calAmmo", "_identity", "_model", "_type", "_kind", "_guidance", "_variants", "_origin"];

    private _calDesc = [_desc] call _findCaliber;
    private _calDisplay = [_display] call _findCaliber;
    private _calMag = [_mag] call _findCaliber;
    private _cal = _calAmmo;
    if (_cal == "") then {_cal = _calDesc};
    if (_cal == "") then {_cal = _calDisplay};
    if (_cal == "") then {_cal = _calMag};

    // A shotgun shell can reuse 19mm HE autocannon projectile mechanics.
    if (_calAmmo == "19mm" && {(_calDisplay find "Gauge") >= 0 || {(_calMag find "Gauge") >= 0}}) then {
        _cal = if ((_calDisplay find "Gauge") >= 0) then {_calDisplay} else {_calMag};
    };
    if (_calAmmo == "265mm" && {_calDisplay == "26.5mm" || {_calDesc == "26.5mm"}}) then {_cal = "26.5mm"};

    if (_type == "") then {
        {
            private _candidate = [_x] call _getType;
            if (_candidate != "") exitWith {_type = _candidate};
        } forEach [_short, _display];
    };
    // "SmE" is an ammunition modifier, so it precedes "Ball".
    if ("SmE" in _variants) then {
        if (_type != "") then {_type = "SmE " + _type} else {_type = "SmE"};
        _variants = _variants - ["SmE"];
    };
    // 'AT' is often a broad role suffix; a magazine may give a precise warhead.
    if (_type == "AT" && {_kind in ["Missile", "Rocket"]}) then {
        private _refined = [_short] call _getType;
        if (_refined in ["HE", "HEAT", "HEDP", "APFSDS", "HE-FRAG"]) then {
            _type = _refined;
        };
    };

    // Descriptions may clarify kind without overriding an ammo-derived model.
    private _descriptionU = toUpper (_desc + " " + _display);
    if (_kind == "" && {(_descriptionU find "ROCKET") >= 0}) then {_kind = "Rocket"};
    if (_kind == "" && {(_descriptionU find "MISSILE") >= 0}) then {_kind = "Missile"};
    if (_kind == "" && {(_descriptionU find "BOMB") >= 0}) then {_kind = "Bomb"};
    if (_kind == "" && {(_descriptionU find "SHELL") >= 0}) then {_kind = "Shell"};
    if (_kind == "" && {(_descriptionU find "MINE") >= 0}) then {_kind = "Mine"};
    // Arma's legacy M_AT is used for unguided rocket pods.
    if (_kind == "Missile" && {(_descriptionU find "UNGUIDED ROCKET") >= 0}) then {_kind = "Rocket"};
    if (_kind == "" && {_cal == "20mm"}) then {_kind = "Shell"};

    if (_guidance == "") then {
        if ((_descriptionU find "LASER GUIDED") >= 0 || {(_descriptionU find "LASER-GUIDED") >= 0} || {(toUpper _short) == "LASER GUIDED"}) then {
            _guidance = "Laser Guided";
        } else {
            if ((_descriptionU find "GUIDED") >= 0 || {(toUpper _short) == "GUIDED"}) then {_guidance = "Guided"};
        };
    };

    // Avoid duplicating purpose and guidance (e.g. "Laser Guided Guided").
    if (_type in ["Guided", "Laser Guided"] && {_guidance != ""}) then {_type = ""};
    if (_type == "AA" && {(_identity find "AA-") == 0}) then {_type = ""};
    if (_type == "AT" && {(_identity find "AGM-") == 0 || {(_identity find "FGM-") == 0}}) then {_type = ""};

    private _parts = [];
    {if (_x != "") then {_parts pushBack _x}} forEach [_cal, _identity, _type, _model, _guidance];
    if (_kind != "" && {!(_kind in _parts)}) then {
        private _uIdentity = toUpper _identity;
        if ((_uIdentity find ((toUpper _kind) + "-")) != 0) then {_parts pushBack _kind};
    };
    private _guess = _parts joinString " ";
    private _fallback = "";

    // A kind alone is a weak guess: try descriptive strings without
    // discarding the kind and already identified caliber.
    if (_cal == "" && {_identity == ""} && {_model == ""} && {_type == ""} && {_guidance == ""}) then {
        private _fallbackText = "";
        if (_count == 1) then {
            _fallbackText = if (_short != "") then {_short} else {[_display, _count] call _cleanDisplay};
            if (_fallbackText != "") then {_fallback = "count1"};
        };
        if (_fallbackText == "" && {_short != ""}) then {_fallbackText = _short; _fallback = "desc_s"};
        if (_fallbackText == "" && {_display != ""}) then {
            _fallbackText = [_display, _count] call _cleanDisplay;
            if (_fallbackText != "") then {_fallback = "desc"};
        };
        if (_fallbackText != "") then {
            _guess = _fallbackText;
            if (_kind != "" && {((toUpper _guess) find (toUpper _kind)) < 0}) then {
                _guess = _guess + " " + _kind;
            };
        };
    };
    if (_guess == "") then {
        if (_ammo != "") then {
            _guess = (_ammo splitString "_") joinString " ";
            _fallback = "ammo_raw";
        } else {
            _guess = (_mag splitString "_") joinString " ";
            _fallback = "mag_raw";
        };
    };

    // Variants are ammo-class traits, not magazine body colors.
    if (_fallback == "" && {count _variants > 0}) then {
        _guess = _guess + " (" + (_variants joinString ", ") + ")";
    };
    if (_origin != "") then {_guess = _guess + " [" + _origin + "]"};
    _guess
};


_name = [_magCfg] call _resolve;
_cache set [_ammoClass, _name];
_name
