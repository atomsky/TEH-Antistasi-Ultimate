/*
    Author: TEH Megamin

    Description:
        Moves all ammunition from every vehicle turret magazine into the
        Jeroen Arsenal, then recreates the original magazine layout empty.

    Params:
        0: OBJECT - Vehicle to unload

    Returns:
        HASHMAP - Ammo classnames and quantities added to the arsenal
*/
#include "tehBulletPile.inc"

params [
    ["_veh", objNull, [objNull]]
];

if !(TEH_VehicleAmmo) exitWith {};
if (isNull _veh) exitWith {};

private _magazines = magazinesAllTurrets _veh;
private _ammoToStore = createHashMap;

{
    _x params [
        "_magazineClass",
        "_turretPath",
        "_ammoCount"
    ];

    if (_ammoCount > 0) then {
        private _ammoClass = getText (
            configFile
            >> "CfgMagazines"
            >> _magazineClass
            >> "ammo"
        );

        if (_ammoClass != "") then {
            _ammoToStore set [
                _ammoClass,
                (_ammoToStore getOrDefault [_ammoClass, 0]) + _ammoCount
            ];
        };
    };
} forEach _magazines;

{
    [IDC_RSCDISPLAYARSENAL_TAB_CARGOBULLET, _x, _y] call jn_fnc_arsenal_addItem;
} forEach _ammoToStore;

_veh setVehicleAmmo 0;

if (hasInterface) then {
    private _lines = [];
    {
        private _ammoName = [_x] call JN_fnc_arsenal_tehAmmoDisplayName;
        _lines pushBack format ["%1 x %2", _y, _ammoName];
    } forEach _ammoToStore;

    ["Ammunition unloaded", if (_lines isEqualTo []) then {"No ammunition unloaded"} else {_lines joinString "<br/>"}] call A3A_fnc_customHint;
};

diag_log format ["Unloaded ammo - %1", _ammoToStore];

_ammoToStore
