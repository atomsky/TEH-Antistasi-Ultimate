/* CBA event handler: each machine moves only casualties local to it. */
params ["_vehicle"];
if !([_vehicle] call loot_vehicle_fnc_canUnloadCasualties) exitWith {};

{
    if (local _x && {objectParent _x isEqualTo _vehicle}
        && {!alive _x || {!([_x] call A3A_fnc_canFight)}}) then {
        if (alive _x) then {
            unassignVehicle _x;
            [_x] orderGetIn false;
        };
        moveOut _x;
        if (objectParent _x isEqualTo _vehicle) then {
            diag_log format ["LootVehicle: moveOut could not unload %1 from %2", _x, _vehicle];
        };
    };
} forEach crew _vehicle;
