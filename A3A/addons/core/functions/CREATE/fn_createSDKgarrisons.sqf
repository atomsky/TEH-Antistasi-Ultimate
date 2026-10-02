if (!isServer and hasInterface) exitWith{};
#include "..\..\script_component.hpp"
FIX_LINE_NUMBERS()

params ["_markerX"];

private ["_vehiclesX","_groups","_soldiers","_positionX","_staticsX","_garrison"];

private _vehiclesX = [];
private _groups = [];
private _soldiers = [];
private _civs = [];
_positionX = getMarkerPos (_markerX);

private _mrk = createMarkerLocal [format ["%1patrolarea", random 100], _positionX];
_mrk setMarkerShapeLocal "ELLIPSE";
_mrk setMarkerSizeLocal [(distanceSPWN),(distanceSPWN)];
_mrk setMarkerTypeLocal "hd_warning";
_mrk setMarkerColorLocal "ColorGreen";
_mrk setMarkerBrushLocal "Border";
if (hideEnemyMarkers) then {
	_mrk setMarkerAlphaLocal 0;
} else {
	_mrk setMarkerAlpha 0.5;
};

private _civNonHuman = Faction(civilian) getOrDefault ["attributeCivNonHuman", false];

if (_markerX != "Synd_HQ" && {!(_markerX in milAdministrationsX)}) then {  ///maaaaaaybe we should save vehicles near ANY friendly marker?
	if (!(_markerX in citiesX)) then {
		private _veh = nil;
		_spawnParameter = [_markerX, "flag"] call A3A_fnc_findSpawnPosition;
		if (_spawnParameter isEqualType []) then {
			_veh = createVehicle [FactionGet(reb,"flag"), (_spawnParameter select 0), [], 0, "NONE"];
			_veh setDir (_spawnParameter select 1); // this probably doesn't matter, but eh why not?
		} else {
			Warning_1("Could not find flag placement marker for garrison %1; falling back to marker center.", _markerX);
			_veh = createVehicle [FactionGet(reb,"flag"), _positionX, [],0, "NONE"];
		};
		_veh setFlagTexture FactionGet(reb,"flagTexture");
		_veh allowDamage false;
		_vehiclesX pushBack _veh;
		[_veh,"SDKFlag"] remoteExec ["A3A_fnc_flagaction",0,_veh];

		if (_markerX in seaports) then {
			[_veh,"seaport"] remoteExec ["A3A_fnc_flagaction",[teamPlayer,civilian],_veh];
		};
	};

	if ((_markerX in resourcesX) or (_markerX in factories)) then {
		private _spawnedCivilians = [_markerX, 4] call A3A_fnc_createResourceCiv;
		if !(isNil "_spawnedCivilians") then {
			_groups pushBack (_spawnedCivilians # 0);
			_civs append (_spawnedCivilians # 1);
		};
	};
};

private _size = 333;//[_markerX] call A3A_fnc_sizeMarker;
private _staticsX = staticsToSave select {_x distance2D _positionX < _size};

_positionX = [_markerX] call A3A_fnc_findAiSpawnPosition;

private _garrison = [];
_garrison = _garrison + (garrison getVariable [_markerX,[]]);

// Don't create these unless required
private _groupStatics = grpNull;
private _groupMortars = grpNull;

// Create the purchased mortars
private _typeCrew = FactionGet(reb,"unitCrew");
if (_typeCrew in _garrison) then {
	_groupMortars = createGroup teamPlayer;
	{
		private _unit = [_groupMortars, _typeCrew, _positionX, [], 0, "NONE"] call A3A_fnc_createUnit;
		private _pos = [_positionX] call A3A_fnc_mortarPos;
		private _veh = (FactionGet(reb,"staticMortars")) # 0 createVehicle _pos;
		_vehiclesX pushBack _veh;

		[_groupMortars] call A3A_fnc_artilleryAdd;

		_unit assignAsGunner _veh;
		_unit moveInGunner _veh;
		[_veh, teamPlayer] call A3A_fnc_AIVEHinit;
		_soldiers pushBack _unit;
	} forEach (_garrison select {_x == _typeCrew});
	_garrison deleteAt (_garrison find _typeCrew);
};

// Move riflemen into saved static weapons in area
{
    private _veh = _x; // Rename to avoid variable shadowing
    if !(isNil {_veh getVariable "lockedForAI"}) then { continue };
    if (!(isNull attachedTo _veh) && {_veh in (attachedTo _veh getVariable ["ace_cargo_loaded", []])}) then { continue };

    // Get all available crew positions
    private _crewPositions = [];
    
    // Check gunner position
    if (isNull gunner _veh) then {
        _crewPositions pushBack ["Gunner", []];
    };
    
    // Check commander position
    if ((_veh emptyPositions "Commander") > 0 && isNull commander _veh) then {
        _crewPositions pushBack ["Commander", []];
    };
    
    // Check turret positions - FIXED TURRET UNIT CHECK
    private _emptyTurrets = allTurrets [_veh, false] select { isNull (_veh turretUnit _x) };
    { _crewPositions pushBack ["Turret", _x] } forEach _emptyTurrets;

    // Process each position
    {
        if (count _garrison == 0) exitWith {};
        _x params ["_role", "_turretPath"];
        
        // Find rifleman in garrison
        private _index = _garrison findIf { _x == FactionGet(reb,"unitRifle") };
        if (_index == -1) exitWith {};
        
        // Create unit - FIXED TYPEOF CHECK
        private _unitGroup = if (typeOf _veh in FactionGet(all,"staticMortars")) then {
            if (isNull _groupMortars) then { _groupMortars = createGroup teamPlayer };
            _groupMortars
        } else {
            if (isNull _groupStatics) then { _groupStatics = createGroup teamPlayer };
            _groupStatics
        };
        
        private _unit = [_unitGroup, _garrison select _index, _positionX, [], 0, "NONE"] call A3A_fnc_createUnit;
        
        // Assign position
        switch (_role) do {
            case "Gunner": { 
                _unit moveInGunner _veh;
                if (_unitGroup == _groupMortars) then {
                    [_unitGroup] call A3A_fnc_artilleryAdd;
                };
            };
            case "Commander": { _unit moveInCommander _veh };
            case "Turret": { _unit moveInTurret [_veh, _turretPath] };
        };
        
        // Initialize and track unit
        [_unit,_markerX] call A3A_fnc_FIAinitBases;
        _soldiers pushBack _unit;
        _garrison deleteAt _index;
        
    } forEach _crewPositions;
} forEach _staticsX;


// Make max A3A_rebelGarrisonGroupSize groups out of the remainder of the garrison
_garrison = _garrison call A3A_fnc_garrisonReorg;

private _typeSL   = A3A_faction_reb get "unitSL";
private _SLs      = _garrison select { _x isEqualTo _typeSL };
private _enlisted = _garrison select { !(_x isEqualTo _typeSL) };

private _totalUnits = count _garrison;
private _totalSLs   = count _SLs;
private _maxGroupSize = A3A_rebelGarrisonGroupSize;

private _groupSize = (ceil ((_totalUnits max 1) / (_totalSLs max 1))) min _maxGroupSize;

//check if we need to promote more squad leaders
private _requiredSLs = ceil (_totalUnits / _groupSize);

 _enlisted = _enlisted call BIS_fnc_arrayShuffle;

while {count _SLs < _requiredSLs && {count _enlisted > 0}} do {
	_enlisted deleteAt 0;         // remove one soldier from pool
    _SLs pushBack _typeSL;        // "promote" to a SL
};

//==========================
// start making groups
private _groups = [];
private _soldiers = [];

{
    private _groupX = createGroup teamPlayer;
    _groups pushBack _groupX;

    // SL first
    private _slUnit = [_groupX, _x, _positionX, [], 0, "NONE"] call A3A_fnc_createUnit;
    _groupX selectLeader _slUnit;
    [_slUnit, _markerX] call A3A_fnc_FIAinitBases;
    _soldiers pushBack _slUnit;

    // fill with enlisted
    for "_i" from 1 to (_groupSize - 1) do {
        if (count _enlisted == 0) exitWith {};
        private _typeX = _enlisted deleteAt 0;
        private _unit = [_groupX, _typeX, _positionX, [], 0, "NONE"] call A3A_fnc_createUnit;
        [_unit, _markerX] call A3A_fnc_FIAinitBases;
        _soldiers pushBack _unit;
        sleep 0.5;
    };

} forEach _SLs;

for "_i" from 0 to (count _groups) - 1 do {
	_groupX = _groups select _i;
	if (_i == 0) then {
		private _garrisonGroup = [_groupX, getMarkerPos _markerX, _size] call A3A_fnc_patrolGroupGarrison;
		if (count _garrisonGroup > 0) then {
			_groups append _garrisonGroup;
		};
	} else {
		[_groupX, "Patrol_Defend", 0, 150, -1, true, getMarkerPos _markerX, false] call A3A_fnc_patrolLoop;
	};
};

[CBA_EVENT_SERVER_SPAWN_LOCATION, [_markerX, "RebelOutpost", true]] call FUNCMAIN(triggerLocalEvent);

waitUntil {
	sleep 5;
	
	switch (sidesX getVariable [_markerX,sideUnknown]) do {
		case Occupants: { _mrk setMarkerColor "ColorBlue" };
		case Invaders: { _mrk setMarkerColor "ColorRed" };
		case teamPlayer: { _mrk setMarkerColor "ColorGreen" };
	};
	(spawner getVariable _markerX == 2);
};
deleteMarker _mrk;

{ if (alive _x) then { deleteVehicle _x }; } forEach _soldiers;
{ deleteVehicle _x } forEach _civs;
{ deleteGroup _x } forEach _groups;

deleteGroup _groupStatics;
deleteGroup _groupMortars;

{if (!(_x in staticsToSave)) then {deleteVehicle _x}} forEach _vehiclesX;

[CBA_EVENT_SERVER_SPAWN_LOCATION, [_markerX, "RebelOutpost", false]] call FUNCMAIN(triggerLocalEvent);

nil;
