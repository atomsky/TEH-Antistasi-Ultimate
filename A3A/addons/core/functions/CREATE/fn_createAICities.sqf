#include "..\..\script_component.hpp"
FIX_LINE_NUMBERS()
if (!isServer and hasInterface) exitWith{};

params ["_markerX"];

private _groups = [];
private _soldiers = [];
private _dogs = [];

private _positionX = getMarkerPos _markerX;

private _num = [_markerX] call A3A_fnc_sizeMarker;
private _patrolSize = _num;

private _sideX = sidesX getVariable [_markerX,sideUnknown];
private _faction = Faction(_sideX);

if ((markersX - controlsX - milAdministrationsX) findIf {(getMarkerPos _x inArea _markerX) and (sidesX getVariable [_x,sideUnknown] != _sideX)} != -1) exitWith {};
_num = round (_num / 100);

ServerInfo_1("Spawning City Patrol in %1", _markerX);

private _dataX = A3A_townData get _markerX;
private _prestigeOPFOR = _dataX select 2;
private _prestigeBLUFOR = _dataX select 3;

private _isAAF = true;
private _params = nil;
if (_markerX in destroyedSites) then {
	_isAAF = false;
	_params = [_positionX,Invaders, selectRandom (_faction get "groupSpecOpsRandom")];
} else {
	_num = round (_num * (_prestigeOPFOR + _prestigeBLUFOR)/100);
	private _frontierX = [_markerX] call A3A_fnc_isFrontline;
	if (_frontierX) then {
		_num = _num * 2;
		_params = [_positionX, Occupants, (selectRandom ([_faction, "groupsTierSmall"] call SCRT_fnc_unit_flattenTier))];
	} else {
		_params = [_positionX, Occupants, _faction get "groupPolice"];
	};
};
if (_num < 1) then {_num = 1};

private _countX = 0;
private _groupX = nil;
private _roadPositions = (_positionX nearRoads round(_patrolSize / 2));

private _civNonHuman = Faction(civilian) getOrDefault ["attributeCivNonHuman", false];

private _fnc_exit = {
	[CBA_EVENT_SERVER_SPAWN_LOCATION, [_markerX, "City", true]] call FUNCMAIN(triggerLocalEvent);

	waitUntil {sleep 1;(spawner getVariable _markerX == 2)};

	[CBA_EVENT_SERVER_SPAWN_LOCATION, [_markerX, "City", false]] call FUNCMAIN(triggerLocalEvent);
};

if (_markerX in townSkirmishes) exitWith {
	Info("Aborting city patrol spawn; is in town skirmish");

	call _fnc_exit;
};

if (_civNonHuman && {(selectRandom [1,2,3]) isEqualTo 2}) exitWith {
	call _fnc_exit;
};

while {(spawner getVariable _markerX != 2) and (_countX < _num)} do {
	private _spawnPosition = [];

	if (count _roadPositions >= 1) then {
		_spawnPosition = selectRandom _roadPositions;
		_roadPositions deleteAt (_roadPositions find _spawnPosition);
	} else {
		_spawnPosition = _positionX;
	};

	_groupX = [_spawnPosition, (_params # 1), (_params # 2)] call A3A_fnc_spawnGroup;

	// Forced non-spawner for performance and consistency with other garrison patrols
	{
		private _unit = _x;
		[_unit, "", false] call A3A_fnc_NATOinit;
		_soldiers pushBack _unit;

		// Early-game police nerf: no primaries on city cops before war tier 2 if player starts with handguns or no weapons
		if ((_params # 2) isEqualTo (_faction get "groupPolice")) then {
			private _handgun = handgunWeapon _unit;
			if (tierWar == 1) then {
				private _primary = primaryWeapon _unit;
				if (_primary != "") then {
					_unit removeWeaponGlobal _primary;
				};
				{
					if !(_x in handgunMagazine _unit) then {
						_unit removeMagazineGlobal _x;
					};
				} forEach (magazines _unit);

				_unit selectWeapon _handgun;
				_unit action ["SwitchWeapon", _unit, _unit, -1];
			};

			// Killed EH for police response van
			if (TEH_spawnSwat > 0) then {
				_unit addEventHandler ["Killed", {
					params ["_unit", "_killer", "_instigator", "_useEffects"];

					// 40% chance to call Gendarmerie, 60% chance to call faction police
					if (random 100 > 20 + 20 * TEH_spawnSwat) exitWith {};

					private _swatCount = count ((_unit nearEntities ["Car", 1000]) select {_x getVariable ["TEH_Swat", false]});
					private _swatWeight = ([0,40,30] select TEH_spawnSwat) * _swatCount + tierWar * 5; //weight of van is 40, weight of police car is 30)
					if (random 100 > _swatWeight) then {
						[_unit,_instigator] spawn A3A_fnc_spawnSwat;
					} else {
						private _side = _unit getVariable ["originalSide",sideUnknown];
						private _revealed = [getPosATL _unit, _side] call A3A_fnc_calculateSupportCallReveal;
    					private _sup = [_side, _instigator, getPosATL _unit, 4, _revealed] remoteExec ["A3A_fnc_requestSupport", 2];
					};
					[_side, 10, 30] remoteExec ["A3A_fnc_addAggression", 2]; //snowball a bit
				}];
			};

			//Can't call mortars
			_unit setVariable ["TEH_ArtilleryDisabled",true,false];
		};
	} forEach units _groupX;

	sleep 1;
	
	// Only spawn dog units with Occupant forces.
	if (_isAAF) then {
		if (random 10 < 2.5) then {
			private _dog = [_groupX, "Fin_random_F", _spawnPosition, [], 0, "FORM"] call A3A_fnc_createUnit;
			_dogs pushBack _dog;
			[_dog] spawn A3A_fnc_guardDog;
		};
	};
	[_groupX, "Patrol_Area", 25, 150, 150, false, _positionX, true] call A3A_fnc_patrolLoop;
	_groups pushBack _groupX;
	_countX = _countX + 1;
};

[CBA_EVENT_SERVER_SPAWN_LOCATION, [_markerX, "City", true]] call FUNCMAIN(triggerLocalEvent);

waitUntil {sleep 1;(spawner getVariable _markerX == 2)};

{if (alive _x) then {deleteVehicle _x}} forEach _soldiers;
{deleteVehicle _x} forEach _dogs;
{ deleteGroup _x } forEach _groups;
{deleteVehicle _x} forEach (units teamPlayer select { !alive _x && !(_x getVariable ["TEH_Rebel",false])});

[CBA_EVENT_SERVER_SPAWN_LOCATION, [_markerX, "City", false]] call FUNCMAIN(triggerLocalEvent);
