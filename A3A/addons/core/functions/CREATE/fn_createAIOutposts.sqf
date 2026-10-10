#include "..\..\script_component.hpp"
FIX_LINE_NUMBERS()

if (!isServer and hasInterface) exitWith{};

params ["_markerX"];

//Not sure if that ever happens, but it reduces redundance
if(spawner getVariable _markerX == 2) exitWith {};

private _vehiclesX = [];
private _groups = [];
private _soldiers = [];
private _dogs = [];
private _outpostMines = []; 
private _spawnsUsed = [];

private _positionX = getMarkerPos (_markerX);
private _pos = [];

ServerInfo_1("Spawning Outpost %1", _markerX);

private _size = [_markerX] call A3A_fnc_sizeMarker;
private _frontierX = [_markerX] call A3A_fnc_isFrontline;

private _sideX = sidesX getVariable [_markerX,sideUnknown];
private _faction = Faction(_sideX);

private _frontierX = [_markerX] call A3A_fnc_isFrontline;
private _isFIA = random 10 > (tierWar + difficultyCoef) and {!_frontierX and {!(_markerX in forcedSpawn)}};
private _antenna = objNull;

if (_sideX == Occupants && {_markerX in outposts}) then {
	private _buildings = nearestObjects [_positionX,["Land_TTowerBig_1_F","Land_TTowerBig_2_F","Land_Communication_F"], _size];
	if (count _buildings > 0) then {
		_antenna = _buildings select 0;
	};
};


//private _mrk = createMarkerLocal [format ["%1patrolarea", random 100], _positionX];
//_mrk setMarkerShapeLocal "ELLIPSE";
//_mrk setMarkerSizeLocal [(distanceSPWN),(distanceSPWN)];

private _mrk = createMarkerLocal [format ["patrolarea:%1", _markerX], _positionX];
_mrk setMarkerShapeLocal "RECTANGLE";
_mrk setMarkerSizeLocal [(distanceSPWN/2),(distanceSPWN/2)];
_mrk setMarkerTypeLocal "hd_warning";
_mrk setMarkerColorLocal "ColorBlue";
_mrk setMarkerBrushLocal "Border";
if (hideEnemyMarkers) then {
	_mrk setMarkerAlphaLocal 0;
} else {
	_mrk setMarkerAlpha 0.5;
};


private _patrolVehicleData = [_sideX, _positionX, _size] call SCRT_fnc_garrison_rollOversizeVehicle;
if (_patrolVehicleData isNotEqualTo []) then {
	private _patrolVeh = _patrolVehicleData select 0;
	private _patrolVehCrew = crew _patrolVeh;
	private _patrolVehicleGroup = _patrolVehicleData select 2;
	{[_x] call A3A_fnc_NATOinit} forEach _patrolVehCrew;
	[_patrolVeh, _sideX] call A3A_fnc_AIVEHinit;

	_soldiers = _soldiers + _patrolVehCrew;
	_groups pushBack _patrolVehicleGroup;
	_vehiclesX pushBack _patrolVeh;

	[_patrolVehicleGroup, _positionX, (_size + 50)] call bis_fnc_taskPatrol;
};

//maybe it's no longer needed after all..?
private _additionalGarrison = [_sideX, _markerX] call SCRT_fnc_garrison_rollOversizeGarrison;
if (_additionalGarrison isNotEqualTo []) then {
	for "_i" from 0 to (count _additionalGarrison) - 1 do {
		private _groupTypes = _additionalGarrison select _i;
		private _group = [_positionX, _sideX, _groupTypes, false, true] call A3A_fnc_spawnGroup;
		if !(isNull _group) then {
			sleep 1;
			[_group, "Patrol_Area", 25, 150, 300, false, [], false] call A3A_fnc_patrolLoop;
			_groups pushBack _group;
			{[_x] call A3A_fnc_NATOinit; _soldiers pushBack _x} forEach units _group;
		};
	};
};

private _garrison = garrison getVariable [_markerX,[]];
_garrison = _garrison call A3A_fnc_garrisonReorg;
private _radiusX = count _garrison;
private _patrol = true;
//If one is missing, there are no patrols??
if (_radiusX < ([_markerX] call A3A_fnc_garrisonSize)) then {
	_patrol = false;
} else {
	//No patrol if patrol area overlaps with an enemy site
	_patrol = ((markersX findIf {(getMarkerPos _x inArea _mrk) && {sidesX getVariable [_x, sideUnknown] != _sideX}}) == -1);
};
if (_patrol) then {
	[_markerX, _positionX, _sideX, _faction] call SCRT_fnc_location_createPatrols;
};

if (_frontierX and {_markerX in outposts} && {!A3U_disableMortars}) then {
	_typeUnit = [_faction get "unitTierStaticCrew"] call SCRT_fnc_unit_getTiered;
	_typeVehX = selectRandom (_faction get "staticMortars");
	_spawnParameter = [_markerX, "Mortar"] call A3A_fnc_findSpawnPosition;
	if (_spawnParameter isEqualType []) then {
		_spawnsUsed pushBack _spawnParameter#2;
		_groupX = createGroup _sideX;
		_veh = _typeVehX createVehicle (_spawnParameter select 0);

		[_groupX] call A3A_fnc_artilleryAdd;

		_unit = [_groupX, _typeUnit, _positionX, [], 0, "NONE"] call A3A_fnc_createUnit;
		_unit moveInGunner _veh;
		[_unit,_markerX] call A3A_fnc_NATOinit;
		_groups pushBack _groupX;
		_soldiers pushBack _unit;
		_vehiclesX pushBack _veh;
		sleep 1;
	};
};

private _ret = [_markerX,_size,_sideX,_frontierX] call A3A_fnc_milBuildings;
_groups pushBack (_ret select 0);
_vehiclesX append (_ret select 1);
_soldiers append (_ret select 2);
_spawnsUsed append (_ret select 3);
{ [_x, _sideX] call A3A_fnc_AIVEHinit } forEach _vehiclesX;

if(random 100 < (40 + tierWar * 3)) then {
	_large = (random 100 < (30 + tierWar * 2));
	[_markerX, _large] spawn A3A_fnc_placeIntel;
};

([_markerX] call A3A_fnc_createZoneFlag) params ["_flagX", "_flagSpawn"];
_vehiclesX pushBack _flagX;
if (!isNil "_flagSpawn") then { _spawnsUsed pushBack _flagSpawn };

([_markerX] call A3A_fnc_createZoneAmmoBox) params ["_ammoBox", "_ammoBoxSpawn"];
if (!isNil "_ammoBoxSpawn") then { _spawnsUsed pushBack _ammoBoxSpawn };

_roads = _positionX nearRoads _size;

if (_markerX in seaports) then {
	_typeVehX = selectRandom (_faction get "vehiclesGunBoats");
	private _mrkMar = seaSpawn select {getMarkerPos _x inArea _markerX};
	if(count _mrkMar > 0) then {
		private _pos = (getMarkerPos (_mrkMar select 0)) findEmptyPosition [0,20,_typeVehX];
		private _vehicle=[_pos, 0,_typeVehX, _sideX] call A3A_fnc_spawnVehicle;
		private _veh = _vehicle select 0;
		[_veh, _sideX] call A3A_fnc_AIVEHinit;
		private _vehCrew = _vehicle select 1;
		{[_x,_markerX] call A3A_fnc_NATOinit} forEach _vehCrew;
		private _groupVeh = _vehicle select 2;
		_soldiers append _vehCrew;
		[_groupVeh, "Patrol_Water", 25, 200, -1, true, _pos] call A3A_fnc_patrolLoop;
		_groups pushBack _groupVeh;
		_vehiclesX pushBack _veh;
		sleep 1;
	} else {
		Error_1("Could not find seaSpawn marker on %1!", _markerX);
	};
} else {
	if (_frontierX && {count _roads != 0}) then {
		_dist = 0;
		_road = objNull;
		{
			if ((position _x) distance _positionX > _dist) then {
				_road = _x;
				_dist = position _x distance _positionX;
			};
		} forEach _roads;
		private _roadscon = roadsConnectedto _road;
		private _roadcon = objNull;
		//This is a extrem complex way, use vector and scalar product to determine which way they are pointing
		{
			if ((position _x) distance _positionX > _dist) then
			{
				_roadcon = _x;
			};
		} forEach _roadscon;
		private _dirveh = [_roadcon, _road] call BIS_fnc_DirTo;

		private _groupX = createGroup _sideX;
		_groups pushBack _groupX;
		private _pos = [getPos _road, 7, _dirveh + 270] call BIS_fnc_relPos;

		if (_faction getOrDefault ["noSandbag", false]) then {		
			private _typeVehX = selectRandom (_faction get "staticAT");
			private _veh = _typeVehX createVehicle _positionX;
			_vehiclesX pushBack _veh;
			_veh setPos _pos;
			_veh setDir _dirVeh + 180;
			private _typeUnit = [_faction get "unitTierStaticCrew"] call SCRT_fnc_unit_getTiered;
			private _unit = [_groupX, _typeUnit, _positionX, [], 0, "NONE"] call A3A_fnc_createUnit;
			_unit moveInGunner _veh;
			[_unit,_markerX] call A3A_fnc_NATOinit;
			[_veh, _sideX] call A3A_fnc_AIVEHinit;
			_soldiers pushBack _unit;
		} else {
			private _bunker = (_faction get "sandbag") createVehicle _pos;
			_vehiclesX pushBack _bunker;
			_bunker setDir _dirveh;
			_pos = getPosATL _bunker;
			private _typeVehX = selectRandom (_faction get "staticAT");
			private _veh = _typeVehX createVehicle _positionX;
			_vehiclesX pushBack _veh;
			_veh setPos _pos;
			_veh setDir _dirVeh + 180;
			private _typeUnit = [_faction get "unitTierStaticCrew"] call SCRT_fnc_unit_getTiered;
			private _unit = [_groupX, _typeUnit, _positionX, [], 0, "NONE"] call A3A_fnc_createUnit;
			_unit moveInGunner _veh;
			[_unit,_markerX] call A3A_fnc_NATOinit;
			[_veh, _sideX] call A3A_fnc_AIVEHinit;
			_soldiers pushBack _unit;
		};
	};
};

_spawnParameter = [_markerX, "Vehicle"] call A3A_fnc_findSpawnPosition;
private _veh = nil;
private _op = false;
if (_spawnParameter isEqualType []) then {
	_spawnsUsed pushBack _spawnParameter#2;
	private _typeVehX = call {
		private _types = if (random 1 < 0.33) then {
			_op = true;
			(_faction get "vehiclesLightAPCs") + 
			(_faction get "vehiclesAPCs") + 
			(_faction get "vehiclesIFVs") + 
			(_faction get "vehiclesAA") +
			(_faction get "vehiclesLightArmed") +
			(_faction get "vehiclesLightTanks") +
			(_faction get "vehiclesAirborne");
		} else {
			(_faction get "vehiclesTrucks") + 
			(_faction get "vehiclesCargoTrucks") + 
			(_faction get "vehiclesLightUnarmed") + 
			(_faction get "vehiclesRepairTrucks") +
			(_faction get "vehiclesAmmoTrucks") +
			(_faction get "vehiclesFuelTrucks");
		};
		// _types = _types select { _x in FactionGet(all,"vehiclesCargoTrucks") };
		//if (count _types == 0) then { (_faction get "vehiclesCargoTrucks") } else { _types };
		selectRandom _types;
	};
	isNil {
		_veh = createVehicle [_typeVehX, (_spawnParameter select 0), [], 0, "CAN_COLLIDE"];
		_veh setDir (_spawnParameter select 1);
	};
	_vehiclesX pushBack _veh;
	[_veh, _sideX] call A3A_fnc_AIVEHinit;

	if (_op) then {
		_veh setHitPointDamage ["hitEngine",1];
		if (random 100 < 50) then {
			_veh setHitPointDamage ["hitTurret",1];
		} else {
			_veh setHitPointDamage ["hitGun",1];
		};
		_veh setHitPointDamage ["hitHull", 0.51];
	} else {
		_lootList = [_veh, 3, 5, 0, 0, 1, 100, 0, 0, 1, 5, 0, 0, 1, 1, 1, 1, 0, 0];
		_lootList call A3A_fnc_fillLootCrate;
	};
	sleep 1;
};

private _countX = 0;
private _vehCount = round (random [2, 4, 5]);
while {_countX < _vehCount} do {
    private _veh = objNull;
    private _hangar = objNull;
    private _spawnParameter = [_markerX, "Plane"] call A3A_fnc_findSpawnPosition;
    if (_spawnParameter isEqualType []) then {
        private _vehiclesPlanesCAS = _faction get "vehiclesPlanesCAS";
        private _vehiclesPlanesAA = _faction get "vehiclesPlanesAA";
        private _vehPool = [];
        {
            _vehPool pushBack _x;
            _vehPool pushBack 1;
        } forEach _vehiclesPlanesCAS;
        {
            _vehPool pushBack _x;
            _vehPool pushBack 1;
        } forEach _vehiclesPlanesAA;
        _spawnsUsed pushBack (_spawnParameter select 2);
        private _typeVehX = selectRandomWeighted _vehPool;
        _veh = createVehicle [_typeVehX, (_spawnParameter select 0), [], 0, "CAN_COLLIDE"];
        _veh setDir (_spawnParameter select 1);
        sleep 0.5;
        if !(alive _veh) then {
            _hangar = (nearestObjects [_veh, ["Static"], 20]) select 0;
            deleteVehicle _hangar;
            deleteVehicle _veh;
            _veh = createVehicle [_typeVehX, (_spawnParameter select 0), [], 0, "CAN_COLLIDE"];
            _veh setDir (_spawnParameter select 1);
            _veh allowDamage false;
            _veh enableSimulation false;
            sleep 0.5;
            _veh enableSimulation true;
            _veh allowDamage true;
        };
        _vehiclesX pushBack _veh;
        [_veh, _sideX] call A3A_fnc_AIVEHinit;
    } else {
        _countX = _vehCount;
    };
    _countX = _countX + 1;
};

{ _x setVariable ["originalPos", getPos _x] } forEach _vehiclesX;

_countX = 0;

if (!isNull _antenna) then {
	if ((typeOf _antenna == "Land_TTowerBig_1_F") or {typeOf _antenna == "Land_TTowerBig_2_F"}) then {
		_groupX = createGroup _sideX;
		_pos = getPosATL _antenna;
		_dir = getDir _antenna;
		_posF = _pos getPos [2,_dir];
		_posF set [2,23.1];
		if (typeOf _antenna == "Land_TTowerBig_2_F") then
		{
			_posF = _pos getPos [1,_dir];
			_posF set [2,24.3];
		};
        private _typeUnit = if (_isFIA) then {
			_faction get "unitMilitiaMarksman"
		} else {
			selectRandom ([_faction, "unitTierTower"] call SCRT_fnc_unit_flattenTier)
		};
		private _unit = [_groupX, _typeUnit, _positionX, [], _dir, "NONE"] call A3A_fnc_createUnit;
		_unit setPosATL _posF;
		_unit forceSpeed 0;

		_unit setUnitPos "UP";
		[_unit,_markerX] call A3A_fnc_NATOinit;
		_soldiers pushBack _unit;
		_groups pushBack _groupX;
	};
};

private _array = [];
private _subArray = [];
_countX = 0;
_radiusX = _radiusX -1;
while {_countX <= _radiusX} do {
	_array pushBack (_garrison select [_countX,7]);
	_countX = _countX + 8;
};

for "_i" from 0 to (count _array - 1) do {

	private _groupX = grpNull;

	if (plusGarrison isEqualTo false) then {
		_array = (selectRandom ([_faction, "groupsTierSquads"] call SCRT_fnc_unit_flattenTier));
		_groupX = if (_i == 0) then {
			[_positionX, _sideX, _array, true, false] call A3A_fnc_spawnGroup;
		} else {
			private _spawnPosition = [_positionX, 10, 100, 2, 0, -1, 0] call A3A_fnc_getSafePos;
			[_spawnPosition, _sideX, _array, false, true] call A3A_fnc_spawnGroup;
		};
	} else {
		_groupX = if (_i == 0) then {
			[_positionX, _sideX, (_array select _i), true, false] call A3A_fnc_spawnGroup;
		} else {
			private _spawnPosition = [_positionX, 10, 100, 2, 0, -1, 0] call A3A_fnc_getSafePos;
			[_spawnPosition, _sideX, (_array select _i), false, true] call A3A_fnc_spawnGroup;
		};
	};

	_groups pushBack _groupX;

	{
		[_x,_markerX] call A3A_fnc_NATOinit;
		_soldiers pushBack _x;
	} forEach units _groupX;

	// Garrison the first group into buildings
	if (_i == 0) then {
		private _garrisonGroup = [_groupX, getMarkerPos _markerX, _size] call A3A_fnc_patrolGroupGarrison;
		if (count _garrisonGroup > 0) then {
			_groups append _garrisonGroup;
		};
	} else {
		[_groupX, "Patrol_Defend", 0, 100, -1, true, _positionX, false] call A3A_fnc_patrolLoop;
	};
};


// --- BEGIN: random AT mines around outpost ---
private _mineCount = TEH_outpostMines;
private _minRadius = 20;
private _maxRadius = 100;
private _mineType = selectRandom (_faction get "minefieldAT");
for "_i" from 1 to _mineCount do {
    private _attempts = 0;
    private _minePos  = [0,0,0];

    while {_attempts < 10} do {
        _attempts = _attempts + 1;

        private _dir  = random 360;
        private _dist = _minRadius + (random (_maxRadius - _minRadius));   // 50–150m
        _minePos = _positionX getPos [_dist, _dir];

        if (
            !surfaceIsWater _minePos &&                  // not in water
            { !(isOnRoad _minePos) } &&                  // avoid roads
            { (_minePos select 2) < 1 } &&               // not up a wall/roof
            { (count (nearestObjects [_minePos, ["House","Building","Land"], 2])) == 0 }
        ) exitWith {};
    };

    if (_attempts < 10) then {
        // Use generic AT mine; swap for faction-specific if you want
        private _mine = createMine [_mineType, _minePos, [], 0];
        if (!isNull _mine) then {
            _outpostMines pushBack _mine;
        };
    };
};
// --- END: random AT mines around outpost ---

[CBA_EVENT_SERVER_SPAWN_LOCATION, [_markerX, "Outpost", true]] call FUNCMAIN(triggerLocalEvent);

{
	if (_x isKindOf "Static" || _x isKindOf "StaticWeapon") then {continue};
	[_x, true] call A3U_fnc_setLock;
} forEach _vehiclesX;

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

{ if (alive _x) then { deleteVehicle _x } } forEach _soldiers;
{ deleteVehicle _x } forEach _dogs;
{ deleteGroup _x } forEach _groups;

_sideX = sidesX getVariable [_markerX,sideUnknown]; //captured maybe?
{
	// delete all vehicles that haven't been stolen
	if (_x getVariable ["ownerSide", _sideX] == _sideX) then {
		if (_x distance2d (_x getVariable "originalPos") < 100) then { deleteVehicle _x }
		else { if !(_x isKindOf "StaticWeapon") then { [_x] spawn A3A_fnc_VEHdespawner } };
	};
} forEach _vehiclesX;


// --- BEGIN: cleanup of outpost AT mines ---
{
    if (!isNull _x) then {
        deleteVehicle _x;
    };
} forEach _outpostMines;
// --- END: cleanup of outpost AT mines ---

_spawnsUsed call A3A_fnc_freeSpawnPositions;


// If loot crate was stolen, set the cooldown
if (!isNil "_ammoBox") then {
	if ((_sideX != teamPlayer) and (alive _ammoBox) and (_ammoBox distance2d _positionX < 100)) exitWith { deleteVehicle _ammoBox };
	if (alive _ammoBox) then { [_ammoBox] spawn A3A_fnc_VEHdespawner };
	private _lootCD = 60;
	garrison setVariable [_markerX + "_lootCD", _lootCD, true];
};

[CBA_EVENT_SERVER_SPAWN_LOCATION, [_markerX, "Outpost", false]] call FUNCMAIN(triggerLocalEvent);

nil;
