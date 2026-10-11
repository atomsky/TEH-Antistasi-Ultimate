/* Broadcast once; every machine will handle only its locally owned occupants. */
params ["_vehicle"];
if !([_vehicle] call loot_vehicle_fnc_canUnloadCasualties) exitWith {false};

["LootVehicle_unloadCasualties", [_vehicle]] call CBA_fnc_globalEvent;
true
