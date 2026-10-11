/*
    Author: [Hazey]
    Description:
        Create Ambient Civ's within city

    Arguments:
        <String> City Marker where you would like the Ambient Civilians created.
        Note, the marker must be provided from citiesX

    Return Value:
        N/A

    Scope: Any
    Environment: Any
    Public: No

    Example: 
        [[_marker], "A3A_fnc_createAmbientCiv"] call A3A_fnc_scheduler;

    License: MIT License
*/

#include "..\..\script_component.hpp"
FIX_LINE_NUMBERS()
params ["_markerX"];

// We only want to run on the server and not on the players
if (!isServer and hasInterface) exitWith {};

if (_markerX in destroyedSites) exitWith {};

private _lowCiv = Faction(civilian) getOrDefault ["attributeLowCiv", false];
private _civNonHuman = Faction(civilian) getOrDefault ["attributeCivNonHuman", false];

if (_lowCiv) exitWith {};
if ("seaport" in _markerX && {_civNonHuman}) exitWith {};

private _sideX = sidesX getVariable [_markerX,sideUnknown];
private _faction = Faction(_sideX);

private _groupSide = civilian;

private _spawnKey = _markerX + "_civ";
private _civilianGroups = [];
private _soundSources = [];
private _lightSources = [];
private _civilians = [];
private _special = [];
private _buildings = [];
private _building = objNull;
private _positionX = getMarkerPos (_markerX);
private _locationRadius = [_markerX] call A3A_fnc_sizeMarker;
private _dayState = [] call A3A_fnc_getDayState;

_buildings = nearestObjects [_positionX, ["House"], _locationRadius];

Info_2("Spawning City Civilians in %1 with a radius of %2", _markerX, _locationRadius);

private _city = if (_positionX isEqualType "") then {_positionX} else {[citiesX, _positionX] call BIS_fnc_nearestPosition};
private _cityData = A3A_townData get _city;
private _numCiv = round (1.5 * sqrt (_cityData # 0) * (1 - tierWar / 20));

// We don't want to add too many civ's.
if (_numCiv > maxCiviliansPerTown) then {
    _numCiv = maxCiviliansPerTown;
};

if (_faction isEqualTo A3A_faction_reb && {_civNonHuman}) exitWith {
    if (count units civilian >= globalCivilianMax) exitWith {
        Info("Global Civilian spawn limit reached! - Exiting");
    };

    for "_i" from 1 to _numCiv do {
        private _groupX = createGroup _groupSide;
        private _spawnPosition = [_positionX, 10, 150, 3, 0, -1, 0] call A3A_fnc_getSafePos;
        private _civUnit = [_groupX, FactionGet(civ, "unitMan"), _spawnPosition, [],0, "NONE"] call A3A_fnc_createUnit;
        _civUnit setPosATL _spawnPosition;
        _civilianGroups pushBack _groupX;
        _civilians pushBack _civUnit;
        [_civUnit] spawn A3A_fnc_civilianInitEH;
        [_groupX] call A3A_fnc_patrolLoop;
    };

    // need to repaste this so civs actually get removed
    waitUntil {sleep 1;(spawner getVariable _spawnKey == 2)};
    {if (alive _x) then {deleteVehicle _x};} forEach _civilians;
    { deleteGroup _x } forEach _civilianGroups;
    {deleteVehicle _x} forEach _soundSources;
    {deleteVehicle _x} forEach _lightSources;
}; // we don't want enemies spawning in friendly cities, call them "safe havens"

// Disregard the above statement if civs aren't human
if (_civNonHuman) exitWith
{
    if (count _special >= (globalCivilianMax * 2) && {zombiesUncapped isEqualTo false}) exitWith {
        Info("Global spawn limit reached! - Exiting");
    };

    // if (_numCiv < 5) then {_numCiv = _numCiv * 2}; // we want the cities to be infested, no?
    if (maxCiviliansPerTown <= 10) then {
        _numCiv = random [6, 8, 10];
    };

    if (zombiesUncapped isEqualTo true) then {
        _numCiv = _numCiv * (selectRandom [2,3]);
    };
    
    switch _faction do
    {
        case A3A_faction_occ : 
        {
            _groupSide = east; // if city is occupant, make the zombies invader
        };
        case A3A_faction_inv : 
        {
            _groupSide = west; // if city is invader, make the zombies occupant
        };
    };

    for "_i" from 1 to _numCiv do {
        private _groupX = createGroup _groupSide;
        private _spawnPosition = [_positionX, 10, 30, 3, 0, -1, 0] call A3A_fnc_getSafePos;

        private _civUnit = [_groupX, FactionGet(civ, "unitSpecial"), _spawnPosition, [],0, "NONE"] call A3A_fnc_createUnit;

        _civUnit setPosATL _spawnPosition;
        _civilianGroups pushBack _groupX;
        _special pushBack _civUnit;
        [_civUnit] spawn A3A_fnc_civilianInitEH;
        [_groupX] call A3A_fnc_patrolLoop;
    };

    // need to repaste this so civs actually get removed
    waitUntil {sleep 1;(spawner getVariable _spawnKey == 2)};
    {if (alive _x) then {deleteVehicle _x};} forEach _civilians;
    {if (alive _x) then {deleteVehicle _x};} forEach _special;
    { deleteGroup _x } forEach _civilianGroups;
    {deleteVehicle _x} forEach _soundSources;
    {deleteVehicle _x} forEach _lightSources;
}; // This ensures the zombies are always aggro to the city owner

//HUMAN FACTIONS

//Press man
if (random 100 < ((aggressionOccupants) + (aggressionInvaders))) then {
    private _spawnPosition = [_positionX, 10, 150, 3, 0, -1, 0] call A3A_fnc_getSafePos;
    private _groupX = createGroup _groupSide;
    _civilianGroups pushBack _groupX;
    private _civPress = [_groupX, FactionGet(civ, "unitPress"), _spawnPosition, [],0, "NONE"] call A3A_fnc_createUnit;
    _civPress setVariable ["TEH_CivRole","Press",true];
    [_civPress] spawn A3A_fnc_civilianInitEH;
    _civilians pushBack _civPress;
    [_groupX, "Patrol_Area", 5, 50, 300, false, [], false] call A3A_fnc_patrolLoop;
    
};

//Mechanic man
private _mechanicsCar = objNull;
if (random 100 < 66) then {
    private _spawnPosition = [_positionX, 10, 150, 3, 0, -1, 0] call A3A_fnc_getSafePos;
    private _groupX = createGroup _groupSide;
    _civilianGroups pushBack _groupX;
    private _mechanic = _groupX createUnit ["C_Man_UtilityWorker_01_F", _spawnPosition, [], 3, "NONE"];
    _mechanic setVariable ["TEH_CivRole","Mechanic",true];
    _civilians pushBack _mechanic;

    private _carPos = [getPosATL _mechanic, 2, 6, 3, 0, -1, 0] call A3A_fnc_getSafePos;
    private _carType =  selectRandomWeighted civVehiclesWeighted;
    _mechanicsCar = createVehicle [_carType, _carPos, [], 0, "NONE"];
    _mechanicsCar setDir random 360;
    _mechanicsCar setVectorUp surfaceNormal getPosATL _mechanicsCar;
    

    //TODO: mechanics scene object collection
    [_mechanic, _mechanicsCar] spawn A3A_fnc_setupMechanic;
};

//Normal civs
for "_i" from 1 to _numCiv do {
    if (count units civilian >= globalCivilianMax) exitWith {
        Info("Global Civilian spawn limit reached! - Exiting");
    };

    private _building = objNull;
    private _spawnPosition = [];
    private _spawnInBuilding = count _buildings > 0;

    if (_spawnInBuilding) then {
        _building = selectRandom _buildings;
        _buildings deleteAt (_buildings find _building);

        private _housePositions = [_building] call BIS_fnc_buildingPositions;

        _spawnPosition = if !(_housePositions isEqualTo []) then {
            selectRandom _housePositions;
        } else {
            [_positionX, 10, 150, 3, 0, -1, 0] call A3A_fnc_getSafePos;
        };
    } else {
        _spawnPosition = [_positionX, 10, 150, 3, 0, -1, 0] call A3A_fnc_getSafePos;
    };

    private _groupX = createGroup _groupSide;
    private _civUnit = [_groupX, FactionGet(civ, "unitMan"), _spawnPosition, [], 0, "NONE"] call A3A_fnc_createUnit;

    _civUnit setPosATL _spawnPosition;
    _civilianGroups pushBack _groupX;
    _civilians pushBack _civUnit;

    // TEH Vars
    _civUnit setVariable ["TEH_Town", _markerX, true];
    _civUnit setVariable ["TEH_noIntel",_sideX == teamPlayer];
    private _loyal = random 100 > ((server getVariable _markerX) # 2);
    
    _civUnit setVariable ["TEH_RebelLoyalty", _loyal, true];
    _civUnit setVariable ["TEH_ArmsInfo", selectRandomWeighted ["none",0.2,"rick",0.4,"bob",0.15,"bandits",0.25]];

    [_civUnit] spawn A3A_fnc_civilianInitEH;
    [_civUnit] call A3A_fnc_dialogCivAction;

    if (_spawnInBuilding) then {
        if (_dayState == "EVENING" || {_dayState == "NIGHT"}) then {
            private _light = [_building] call A3A_fnc_createRoomLight;
            _lightSources pushBack _light;
        };

        if (_dayState == "MORNING") then {
            if (4 > random 10) then {
                private _soundSource = [_building] call A3A_fnc_createMusicSource;
                _soundSources pushBack _soundSource;
            };

            private _light = [_building] call A3A_fnc_createRoomLight;
            _lightSources pushBack _light;
        };

        if (_dayState == "DAY") then {
            if (7 > random 10) then {
                private _soundSource = [_building] call A3A_fnc_createMusicSource;
                _soundSources pushBack _soundSource;
            };

            [_groupX] call A3A_fnc_patrolLoop;
        };
    } else {
        [_groupX] call A3A_fnc_patrolLoop;
    };
};

// TEH Oblivion: Assign one Joe and one Bob only if this spawned town has at least two civilians.
// No plot armor: if either role dies, despawns, or becomes unavailable, the lead can simply be lost.
if (isNil {missionNamespace getVariable "TEH_CivDialogTownStates"}) then {
    missionNamespace setVariable ["TEH_CivDialogTownStates", createHashMap, true];
};

_town = _markerX;

if (_town isEqualTo "") exitWith {false};

private _townStates = missionNamespace getVariable ["TEH_CivDialogTownStates", createHashMap];
private _townState = _townStates getOrDefault [_town, createHashMap];

if !(_townState getOrDefault ["CacheCompleted", false]) then {

    if ((count _civilians) < 6) exitWith {false};

    private _joe = selectRandom _civilians;
    private _bob = selectRandom (_civilians - [_joe]);

    _townState set ["Town", _town];
    _townState set ["CacheStarted", true];
    _townState set ["CacheLead", _joe];
    _townState set ["CacheContact", _bob];

    _townStates set [_town, _townState];

    missionNamespace setVariable ["TEH_CivDialogTownStates", _townStates, true];

    _joe  setVariable ["TEH_CivRole", "Joe", true];

    [_bob] spawn A3A_fnc_setupBob;
    _bob  setVariable ["TEH_CivRole", "Bob", true];
    _bob  setVariable ["TEH_CacheContactUnlocked", false, true];
    _bob  setVariable ["TEH_CacheBobFound", false, true];
};

//Pickle Rick
private _rick = selectRandom (_civilians select {isNil {_x getVariable "TEH_CivRole"}});
_townState set ["PetrosContact", _rick];
_townStates set [_town, _townState];

[_rick] spawn A3A_fnc_setupRick;

//The gopniks

private _building = objNull;
private _spawnPosition = [];
private _spawnInBuilding = count _buildings > 0;

if (_spawnInBuilding) then {
    _building = selectRandom _buildings;
    _buildings deleteAt (_buildings find _building);

    private _housePositions = [_building] call BIS_fnc_buildingPositions;

    _spawnPosition = if !(_housePositions isEqualTo []) then {
        selectRandom _housePositions;
    } else {
        [_positionX, 10, 150, 3, 0, -1, 0] call A3A_fnc_getSafePos;
    };
} else {
    _spawnPosition = [_positionX, 10, 150, 3, 0, -1, 0] call A3A_fnc_getSafePos;
};

private _gopnikGroup = createGroup east;
if (isNull _gopnikGroup) exitWith {[]};

private _gopniks = [];
private _count = 3 + floor random 3;

for "_i" from 1 to _count do {
    private _unit = _gopnikGroup createUnit ["O_Spotter_F", _spawnPosition, [], 3, "NONE"];

    _gopniks pushBack _unit;

    [_unit] spawn A3A_fnc_setupGopnik;
};


// Handle removal of civ's.
waitUntil {sleep 1;(spawner getVariable _spawnKey == 2)};
{if (alive _x) then {deleteVehicle _x};} forEach _civilians;
{ deleteGroup _x } forEach _civilianGroups;
{if (alive _x) then {deleteVehicle _x};} forEach _gopniks;
deleteGroup _gopnikGroup;
{deleteVehicle _x} forEach _soundSources;
{deleteVehicle _x} forEach _lightSources;

if (!isNil "_mechanicsCar") then {
    deleteVehicle _mechanicsCar;
};