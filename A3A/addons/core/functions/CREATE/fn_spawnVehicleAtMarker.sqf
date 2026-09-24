params
[
    ["_marker", "", [""]],
    ["_vehicle", "", [""]]
];

/*  Spawns the given vehicle at the given marker, only works if the marker as spawn places defined, not recommended for planes

    Execution on: HC or Server

    Called by: call

    Params:
        _marker : STRING : The name of the marker, where the vehicle should be spawned in
        _vehicle : STRING : The configname of the vehicle, which should be spawned in

    Returns:
        OBJECT : The vehicle object, objNull if spawn wasnt possible
        If it was a land vehicle, the spawnPlace variable on it is set to the spawn place used
*/
#include "..\..\script_component.hpp"
FIX_LINE_NUMBERS()

if(_vehicle == "" || _marker == "") exitWith
{
    Error_1("Function called with bad input, was %1", _this);
    objNull;
};

private _vehicleObj = objNull;
if(_vehicle isKindOf "Air") exitWith
{
    _vehicleObj = [_vehicle, getMarkerPos _marker, 100, 5, true] call A3A_fnc_safeVehicleSpawn;
    _vehicleObj;
};

//Get the spawn place of the marker
private _spawnParams = [_marker, "Vehicle"] call A3A_fnc_findSpawnPosition;

if (_spawnParams isEqualType []) then
{
	_spawnParams params ["_spawnPos", "_spawnDir", "_spawnPlace"];

	private _safePos = +_spawnPos;
	_safePos set [2, 0];

	// Small local collision adjustment. Keeps vehicle close to reserved spawn pad.
	private _emptyPos = _safePos findEmptyPosition [0, 8, _vehicle];
	if !(_emptyPos isEqualTo []) then {
		_safePos = _emptyPos;
	};

	private _createPos = +_safePos;
	_createPos set [2, 0.75];

	_vehicleObj = createVehicle [_vehicle, _createPos, [], 0, "CAN_COLLIDE"];

	if !(isNull _vehicleObj) then {
		_vehicleObj setVariable ["spawnPlace", _spawnPlace];

		_vehicleObj allowDamage false;
		_vehicleObj setDir _spawnDir;
		_vehicleObj setPosATL _createPos;
		_vehicleObj setVectorUp (surfaceNormal _safePos);
		_vehicleObj setVelocity [0,0,0];

		[_vehicleObj, _safePos, _spawnDir] spawn {
			params ["_veh", "_safePos", "_dir"];

			private _placePos = +_safePos;
			_placePos set [2, 0.75];

			for "_i" from 1 to 8 do {
				sleep 0.05;

				if (isNull _veh) exitWith {};

				_veh setDir _dir;
				_veh setPosATL _placePos;
				_veh setVectorUp (surfaceNormal _safePos);
				_veh setVelocity [0,0,0];
			};

			sleep 0.5;

			if (isNull _veh) exitWith {};

			// Hell guard
			if ((getPosATL _veh # 2) < -1) then {
				Warning_1("Vehicle %1 fell below terrain during marker spawn, repositioning", typeOf _veh);

				_veh setDir _dir;
				_veh setPosATL _placePos;
				_veh setVectorUp (surfaceNormal _safePos);
				_veh setVelocity [0,0,0];
			};

			sleep 0.25;

			if !(isNull _veh) then {
				_veh allowDamage true;
			};
		};
	};

	_vehicleObj setVariable ["spawnPlace", _spawnParams select 2];
	[_vehicleObj, sidesX getVariable[_marker, sideUnknown]] call A3A_fnc_AIVEHinit;

};

_vehicleObj;
