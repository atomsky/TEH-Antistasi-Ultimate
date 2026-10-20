// CBA settings are registered on every machine; only clients need actions/UI.
[
    "LootVehicleDistance",
    "SLIDER",
    [localize "STR_TEH_LOOT_VEHICLE_MAX_TRANSFER_DISTANCE", localize "STR_TEH_LOOT_VEHICLE_MAX_TRANSFER_DISTANCE_DESC"],
    "TEH Loot Vehicle",
    [1, 100, 15, 1],
    1,
    {}
] call CBA_fnc_addSetting;
[
    "LootVehicleSpeed",
    "SLIDER",
    [localize "STR_TEH_LOOT_VEHICLE_TRANSFER_SPEED", localize "STR_TEH_LOOT_VEHICLE_TRANSFER_SPEED_DESC"],
    "TEH Loot Vehicle",
    [0, 10, 1, 1],
    1,
    {}
] call CBA_fnc_addSetting;

// The action is client-side, but each casualty must be moved on its owner.
["LootVehicle_unloadCasualties", {
    _this call loot_vehicle_fnc_unloadCasualtiesLocal;
}] call CBA_fnc_addEventHandler;

if (!hasInterface) exitWith {};

// Complete Antistasi Ultimate versions/forks must not be loaded alongside TEH.
private _loadedMods = getLoadedModsInfo;
private _loadedWorkshopIDs = _loadedMods apply {_x # 7};
private _conflicts = [];
private _fullAUCWorkshopIDs = [
    "3020755032", // Antistasi Ultimate - Mod
    "3169463443", // Antistasi Ultimate - Public Testing
    "3387881294", // Antistasi Ultimate Modded
    "3335369377"  // Antistasi Ultimate (Full Arsenal)
];
private _loadedFullAUCMods = _loadedMods select {(_x # 7) in _fullAUCWorkshopIDs};
if !(_loadedFullAUCMods isEqualTo []) then {
    private _lines = ["TEH Antistasi Ultimate is loaded together with another complete Antistasi Ultimate version:"];
    {_lines pushBack format ["- %1", _x # 0]} forEach _loadedFullAUCMods;
    _conflicts pushBack _lines;
};

if ("3747933298" in _loadedWorkshopIDs && {"3783217256" in _loadedWorkshopIDs}) then {
    _conflicts pushBack [
        "Both Point Campfire compatibility patches are loaded:",
        "- TEH Point Campfire Compatibility Patch",
        "- TEH Antistasi Ultimate - Point Campfire Public Test Compatibility"
    ];
};
if ("3692487262" in _loadedWorkshopIDs && {"3558334679" in _loadedWorkshopIDs}) then {
    _conflicts pushBack [
        "Both stable and Public Test versions of Point Campfire are loaded:",
        "- A3UE - Point Campfire",
        "- A3UE - Point Campfire - Public Test"
    ];
};
if !(_conflicts isEqualTo []) then {
    private _messageParts = [localize "STR_TEH_INCOMPATIBLE_MODS_DETECTED"];
    {
        private _lines = _x;
        _messageParts pushBack lineBreak;
        _messageParts pushBack lineBreak;
        {
            _messageParts pushBack _x;
            if (_forEachIndex < (count _lines) - 1) then {_messageParts pushBack lineBreak};
        } forEach _lines;
    } forEach _conflicts;
    _messageParts pushBack lineBreak;
    _messageParts pushBack lineBreak;
    _messageParts pushBack localize "STR_TEH_INCOMPATIBLE_MODS_RESOLUTION";
    [composeText _messageParts, "Incompatible mods detected", true, false] spawn BIS_fnc_guiMessage;
};

[] call loot_vehicle_fnc_registerActions;
