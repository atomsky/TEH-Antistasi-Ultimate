/*
    Author: TEH Antistasi Ultimate

    Description:
        Loads every existing vehicle turret magazine from the Jeroen Arsenal.
        Each magazine instance is recreated with as much ammunition as is
        currently available in jna_datalist.

    Params:
        0: OBJECT - Vehicle to load

    Returns:
        BOOL - Whether the procedure ran
*/
#include "tehBulletPile.inc"

params [
    ["_veh", objNull, [objNull]]
];

if !(TEH_VehicleAmmo) exitWith { false };
if (isNull _veh) exitWith { false };

private _magazines = magazinesAllTurrets _veh;
private _ammoLoaded = createHashMap;

// Recreate every original magazine instance and fill it from the current
// Jeroen Arsenal state. Zero available ammunition recreates an empty magazine.
{
    _x params ["_magazineClass", "_turretPath"];

    private _ammoToLoad = [_magazineClass] call JN_fnc_arsenal_magLoadBullets;
    private _ammoCount = _ammoToLoad # 2;

    _veh addMagazineTurret [_magazineClass, _turretPath, _ammoCount];
    _ammoToLoad call jn_fnc_arsenal_removeItem;

    if (_ammoCount > 0) then {
        private _ammoClass = getText (configFile >> "CfgMagazines" >> _magazineClass >> "ammo");
        if (_ammoClass isNotEqualTo "") then {
            _ammoLoaded set [_magazineClass, (_ammoLoaded getOrDefault [_magazineClass, 0]) + _ammoCount];
        };
    };

    diag_log format ["Loading magazine - %1", _ammoToLoad];
} forEach _magazines;

if (hasInterface) then {
    private _lines = [];
    {
        private _ammoName = [_x] call JN_fnc_arsenal_tehAmmoDisplayName;
        _lines pushBack format ["%1 x %2", _y, _ammoName];
    } forEach _ammoLoaded;

    ["Ammunition loaded", if (_lines isEqualTo []) then {"No ammunition loaded"} else {_lines joinString "<br/>"}] call A3A_fnc_customHint;
};

true
