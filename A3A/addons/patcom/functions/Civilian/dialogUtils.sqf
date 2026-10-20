private _sayToCaller = {
    params ["_speaker", "_listener", "_text"];
    [_speaker, _text] remoteExec ["globalChat", _listener];
};

private _getUnitTown = {
    params ["_unit"];

    _unit getVariable ["TEH_Town", ""]
};

private _getTownVar = {
    params ["_town", "_key", "_default"];

    private _townStates = missionNamespace getVariable ["TEH_CivDialogTownStates", createHashMap];
    private _townState = _townStates getOrDefault [_town, createHashMap];
    _townState getOrDefault [_key, _default]
};

private _setTownVar = {
    params ["_town", "_key", "_value"];

    private _townStates = missionNamespace getVariable ["TEH_CivDialogTownStates", createHashMap];
    private _townState = _townStates getOrDefault [_town, createHashMap];

    _townState set [_key, _value];
    _townStates set [_town, _townState];
    missionNamespace setVariable ["TEH_CivDialogTownStates", _townStates, true];
};

private _findTownCivs = {
    params ["_town"];

    allUnits select {
        alive _x
        && {side group _x isEqualTo civilian}
        && {isNull objectParent _x}
        && {(_x getVariable ["TEH_Town", ""]) isEqualTo _town}
    }
};

private _describeContact = {
    params ["_unit"];

    private _getItemName = {
        params ["_class", "_fallback"];
        if (_class isEqualTo "") exitWith {_fallback};

        private _name = getText (configFile >> "CfgWeapons" >> _class >> "displayName");
        if (_name isEqualTo "") then {_class} else {_name};
    };

    private _uniformName = [uniform _unit, localize "STR_TEH_SPOTTING_CIVILIAN_CLOTHES"] call _getItemName;
    private _vestName = [vest _unit, ""] call _getItemName;
    private _headgearName = [headgear _unit, ""] call _getItemName;

    private _parts = [format [localize "STR_TEH_SPOTTING_WEARING_UNIFORM", _uniformName]];
    if (_vestName isNotEqualTo "") then {_parts pushBack format [localize "STR_TEH_SPOTTING_WEARING_VEST", _vestName]};
    if (_headgearName isNotEqualTo "") then {_parts pushBack format [localize "STR_TEH_SPOTTING_WEARING_HEADGEAR", _headgearName]};

    _parts joinString ", "
};

private _unlockRandomWeapon = {
    params ["_speaker", "_listener", "_sayToCaller"];

    private _newWeapon = selectRandom (((A3A_faction_occ get "loadouts") get "militia_Rifleman") # 0) # 0;
    private _magazines = _newWeapon # 4 # 0;
    private _quantity = crateWepNumMax max 1;

    private _crateType = "Box_NATO_Wps_F";
    private _cratePos = (getPosATL _speaker) findEmptyPosition [1, 12, _crateType];
    if (_cratePos isEqualTo []) then {
        _cratePos = _speaker modelToWorld [0, 2, 0];
        _cratePos set [2, 0];
    };

    private _crate = createVehicle [_crateType, _cratePos, [], 0, "NONE"];
    _crate setDir (random 360);
    clearWeaponCargoGlobal _crate;
    clearMagazineCargoGlobal _crate;
    clearItemCargoGlobal _crate;
    clearBackpackCargoGlobal _crate;

    _crate addWeaponCargoGlobal [_newWeapon # 0, _quantity];
    _crate addItemCargoGlobal [_newWeapon # 1, _quantity];
    _crate addItemCargoGlobal [_newWeapon # 2, _quantity];
    _crate addItemCargoGlobal [_newWeapon # 3, _quantity];

    private _magazineCount = (_quantity * crateAmmoNumMax) max 3;
    _crate addMagazineCargoGlobal [_magazines, _magazineCount];

    private _weaponName = getText (configFile >> "CfgWeapons" >> (_newWeapon # 0) >> "displayName");
    if (_weaponName isEqualTo "") then {_weaponName = (_newWeapon # 0)};

    private _text = format [localize "STR_TEH_CIVILIAN_BOB_CACHE_RECOVERED", _quantity, _weaponName];
    [_text, true] remoteExec ["A3A_fnc_showIntel", [civilian, teamPlayer]];

    true
};

private _actionArgs = [_sayToCaller, _getUnitTown, _getTownVar, _setTownVar, _findTownCivs, _describeContact, _unlockRandomWeapon];
private _commonCondition = "alive _target && {alive _this} && {isNull objectParent _this} && {_target getVariable ['TEH_DialogStarted', false]}";