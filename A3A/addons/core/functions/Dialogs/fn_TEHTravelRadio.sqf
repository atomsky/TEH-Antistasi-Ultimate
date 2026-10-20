params [
    ["_quickMarker", "", [""]]
];

// private _titleStr = localize "STR_A3A_fn_dialogs_ftradio_title";
private _titleStr = localize "STR_TEH_TRAVEL_RADIO_TITLE";
if (limitedFT == 3) exitWith {[_titleStr, "Fast travel is disabled for this server."] call A3A_fnc_customHint}; // [_titleStr, localize "STR_A3A_fn_dialogs_ftradio_no_param"]
// This needs a proper stringtable ^

if (TEH_WarTierZero && !(player getVariable ["TEH_Rebel",false])) exitWith {
	[
		"Fast Travel unavailable",
		format [
			"Fast Travel Services are not available to unregistered rebels. Please contact your local %1 green representative.",
			A3A_faction_reb get "name"
		]
	] call A3A_fnc_customHint;

};

private _markersX = markersX + [respawnTeamPlayer];

if (!isNil "traderMarker") then {
	_markersX pushBack traderMarker;
};

if (!isNil "isRallyPointPlaced" && {isRallyPointPlaced}) then {
	_markersX pushBack rallyPointMarker;
};

private _teleportZones = _markersX  select { sidesX getVariable _x == teamPlayer };
{
	_mrk = createMarkerLocal [format["teleport-%1",_x],getMarkerPos _x];
	_mrk setMarkerShapeLocal "ELLIPSE";
	_mrk setMarkerSizeLocal [500,500];
	_mrk setMarkerColorLocal "ColorYellow";
	_mrk setMarkerAlphaLocal 0.33;
	_mrk setMarkerBrushLocal "Solid";

} forEach _teleportZones;

private _vics = vehicles select {(alive _x) && (side _x == teamPlayer || (side _x == Civilian && _x getVariable ["originalSide",sideUnknown] == teamPlayer))};
private _vicmrks = [];
{
	_mrk = createMarkerLocal [format["teleport-%1", random 99999],getPosATL _x];
	_vicmrks pushBack _mrk;
	_mrk setMarkerShapeLocal "ELLIPSE";
	_mrk setMarkerSizeLocal [100,100];
	_mrk setMarkerColorLocal "ColorGreen";
	_mrk setMarkerAlphaLocal 0.5;
	_mrk setMarkerBrushLocal "Solid";

} forEach _vics;

private _esHC = false;
if (count hcSelected player > 1) exitWith {
	[localize "STR_A3A_Dialogs_fast_travel_header", localize "STR_A3A_Dialogs_fast_travel_error_only_one_hc"] call SCRT_fnc_misc_deniedHint
};

private _groupX = nil;
if (count hcSelected player == 1) then {
	_groupX = hcSelected player select 0; 
	_esHC = true;
} else {
	_groupX = group player;
};
private _checkForPlayer = false;
if (!_esHC and {(limitedFT == 1 or limitedFT == 2)}) then {_checkForPlayer = true};
private _boss = leader _groupX;

if (_boss != player and {!_esHC}) then {_groupX = player};

if (_esHC && {{isPlayer _x} count units _groupX > 1}) exitWith {
	[localize "STR_A3A_Dialogs_fast_travel_header", localize "STR_A3A_Dialogs_fast_travel_error_player"] call SCRT_fnc_misc_deniedHint;
};

if (player != player getVariable ["owner",player]) exitWith {
	[localize "STR_A3A_Dialogs_fast_travel_header", localize "STR_A3A_Dialogs_fast_travel_no_controlai"] call SCRT_fnc_misc_deniedHint;
};

if (!_esHC and !isNil {vehicle player getVariable "SA_Tow_Ropes"}) exitWith {
	[localize "STR_A3A_Dialogs_fast_travel_header", localize "STR_A3A_Dialogs_fast_travel_no_towing"] call SCRT_fnc_misc_deniedHint;
};

if (!isNil "A3A_FFPun_Jailed" && {(getPlayerUID player) in A3A_FFPun_Jailed}) exitWith {
	[localize "STR_A3A_Dialogs_fast_travel_header", localize "STR_A3A_Dialogs_fast_travel_no_ff"] call SCRT_fnc_misc_deniedHint;
};

private _units = units _groupX;

/* Instead I'll handle individual units later (e.g. infantry, and driven vehicles are moved, static stays back)
if (_units findIf {
	vehicle _x != _x and ((!isPlayer (driver vehicle _x) && isNull (driver vehicle _x)) or !canMove vehicle _x or vehicle _x isKindOf "Boat")
} != -1) exitWith {
	[localize "STR_A3A_Dialogs_fast_travel_header", localize "STR_A3A_Dialogs_fast_travel_no_multiple"] call SCRT_fnc_misc_deniedHint;
};
*/

positionTel = [];

if (_quickMarker == "") then {[localize "STR_A3A_Dialogs_fast_travel_header", localize "STR_A3A_Dialogs_fast_travel_click"] call A3A_fnc_customHint;};
if (!visibleMap) then {openMap true};
showCommandingMenu "";

if !(_quickMarker == "") then {
	private _quickMarkerPosition = getMarkerPos _quickMarker;

	_quickMarkerPosition set [0, (_quickMarkerPosition select 0) + 0.1];
	_quickMarkerPosition set [1, (_quickMarkerPosition select 1) + 0.1];
	// I have to add a slight offset because this shit will take a different marker if its set exactly on the marker i want to tp to....
	positionTel = _quickMarkerPosition;
} else {
	onMapSingleClick "positionTel = _pos; true";
};

waitUntil {sleep 1; (count positionTel > 0) or {not visiblemap}};
onMapSingleClick "";

{
	deleteMarkerLocal format["teleport-%1",_x];
} forEach _teleportZones;

{
	deleteMarkerLocal _x;
} forEach _vicmrks;

private _positionTel = positionTel;
private _earlyEscape = false;

if (count _positionTel > 0) then {
	private _base = [_markersX, _positionTel] call BIS_fnc_nearestPosition;
	if (!isNil "rallyPointMarker" && {_base == rallyPointMarker}) then {
		[] spawn SCRT_fnc_rally_travelToRallyPoint;
		openMap false;
		_earlyEscape = true;
	};
};

if (_earlyEscape) exitWith {};

private _areEnemiesNearby = false;

if (!fastTravelEnemyCheck && !_esHC && {[getPosATL player] call A3A_fnc_enemyNearCheck}) exitWith {
	[localize "STR_A3A_Dialogs_fast_travel_header", localize "STR_A3A_Dialogs_fast_travel_enemiesnear_individual"] call SCRT_fnc_misc_deniedHint;
};

if ((fastTravelEnemyCheck || _esHC) && {_units findIf {[getPosATL _x] call A3A_fnc_enemyNearCheck} != -1}) exitWith {
	[localize "STR_A3A_Dialogs_fast_travel_header", localize "STR_A3A_Dialogs_fast_travel_enemiesnear_group"] call SCRT_fnc_misc_deniedHint;
};

//That kinda makes sense.
if (vehicle player != player && {driver vehicle player != player}) exitWith {
	[localize "STR_A3A_Dialogs_fast_travel_header", localize "STR_A3A_Dialogs_fast_travel_only_drivers"] call SCRT_fnc_misc_deniedHint;
};

if (_positionTel isEqualTo []) exitWith {
	[localize "STR_A3A_Dialogs_fast_travel_header", localize "STR_A3A_Dialogs_fast_travel_missclick"] call SCRT_fnc_misc_deniedHint;
};

private _nearvic = [_vics, _positionTel] call BIS_Fnc_nearestPosition;

private _base = [_markersX, _positionTel] call BIS_Fnc_nearestPosition;

private _traderExists = !(isNil "traderMarker");
if (_traderExists && {_base == traderMarker && {isTraderQuestAssigned || !isTraderQuestCompleted}}) exitWith {
	[localize "STR_A3A_Dialogs_fast_travel_header", localize "STR_A3A_Dialogs_fast_travel_trader_locked"] call SCRT_fnc_misc_deniedHint;
};

private _rebelMarkers = if (!isNil "traderMarker") then {["Synd_HQ", traderMarker]} else {["Synd_HQ"]};
private _isValidTargetLocation = (_base in (_rebelMarkers + airportsX + milbases));

if (_checkForPlayer && limitedFT == 1 && !_isValidTargetLocation) exitWith {
	[localize "STR_A3A_Dialogs_fast_travel_header", localize "STR_A3A_Dialogs_fast_travel_limited"] call SCRT_fnc_misc_deniedHint;
};

private _withinBoundaries = true;
if (limitedFT == 2) then {
	private _rebelLocations = (_rebelMarkers + airportsX + milbases) select { sidesX getVariable _x == teamPlayer };
	private _nearestPosition = [_rebelLocations, player] call BIS_Fnc_nearestPosition;
	private _distanceToNearest = player distance getMarkerPos _nearestPosition;
	_withinBoundaries = _distanceToNearest < 500;	
};

if (_checkForPlayer && limitedFT == 2 && (!_isValidTargetLocation or !_withinBoundaries)) exitWith {
	[localize "STR_A3A_Dialogs_fast_travel_header", localize "STR_A3A_Dialogs_fast_travel_limited_to_between_destinations"] call SCRT_fnc_misc_deniedHint;
};

private _baseDist = _positionTel distance getMarkerPos _base;

private _vicDist = 999;
if (_nearvic isNotEqualTo [0,0,0]) then { diag_log _nearvic; _vicDist = _positionTel distance2d getPosATL _nearvic;};

private _enemyBase = (sidesX getVariable [_base,sideUnknown]) in [Occupants, Invaders];

if ((_baseDist < _vicDist || _vicDist > 100) && _enemyBase) exitWith {
	[localize "STR_A3A_Dialogs_fast_travel_header", localize "STR_A3A_Dialogs_fast_travel_no_enemy_zone"] call SCRT_fnc_misc_deniedHint; 
	openMap [false,false];
};

/*
if (_base in forcedSpawn) exitWith {
	[localize "STR_A3A_Dialogs_fast_travel_header", localize "STR_A3A_Dialogs_fast_travel_no_enemy_attack"] call SCRT_fnc_misc_deniedHint; 
	openMap [false,false];
};

if ([getMarkerPos _base] call A3A_fnc_enemyNearCheck) exitWith {
	[localize "STR_A3A_Dialogs_fast_travel_header", localize "STR_A3A_Dialogs_fast_travel_no_enemy_surrounding"] call A3A_fnc_customHint; 
	openMap [false,false];
};
*/


if (_baseDist <= 500 || _vicDist <= 100) then {
	private _positionX = _positionTel;
	private _distanceX = round (((position _boss) distance _positionX)/200);
	private _forcedX = false;
	
	if (!_esHC) then {
		disableUserInput true; 
		cutText [format [localize "STR_hints_FT_timer", _distanceX],"BLACK",1]; 
		sleep 1;
	} else {
		[localize "STR_A3A_Dialogs_fast_travel_header", format [localize "STR_A3A_Dialogs_fast_travel_moving_hc_group",groupID _groupX]] call A3A_fnc_customHint; 
		sleep _distanceX;
	};

	if (!_esHC) then {
		private _timePassed = 0;
		while {_timePassed < _distanceX} do {
			cutText [format [localize "STR_hints_FT_timer", (_distanceX - _timePassed)],"BLACK",0.0001];
			sleep 1;
			_timePassed = _timePassed + 1;
		};
	};
	private _exit = false;
	if (limitedFT == 1 or limitedFT == 2) then {
		_vehicles = [];
		{if (vehicle _x != _x) then {_vehicles pushBackUnique (vehicle _x)}} forEach units _groupX;
		{if ((vehicle _x) in _vehicles) exitWith {_checkForPlayer = true}} forEach (call A3A_fnc_playableUnits);
	};

	if (_checkForPlayer and !_isValidTargetLocation) exitWith {
		[localize "STR_A3A_Dialogs_fast_travel_header", format [localize "STR_A3A_Dialogs_fast_travel_cancel",groupID _groupX]] call A3A_fnc_customHint;
	};

	private _chargeForTravel = 0;

	private _movedUnits = units _groupX;
	private _ftUnits = [];
	{
		private _unit = _x;
		if ((!isPlayer _unit and (leader _unit) == player) or {_unit == player} or _esHC) then {
			_unit allowDamage false;
			_ftUnits pushBack _unit;
			if (_unit != vehicle _unit) then {
				if (driver vehicle _unit == _unit) then {
					sleep 3;
					_radiusX = 10;
					private _roads = [];
					while {true} do {
						_roads = _positionX nearRoads _radiusX;
						if (count _roads > 0) exitWith {};
						_radiusX = _radiusX + 10;
					};
					_road = _roads select 0;
					private _pos = position _road findEmptyPosition [10,100,typeOf (vehicle _unit)];
					vehicle _unit setPos _pos;
					
					_chargeForTravel = _chargeForTravel + 100 + 50*(count (crew vehicle _unit));
					diag_log format["Vehicle travel. Tally %1",_chargeForTravel];
				};
				if ((vehicle _unit isKindOf "StaticWeapon") and (!isPlayer (leader _unit))) then {
					private _pos = _positionX findEmptyPosition [10,100,typeOf (vehicle _unit)];
					vehicle _unit setPosATL _pos;
					_chargeForTravel = _chargeForTravel + 100;
					diag_log format["Static travel. Tally %1",_chargeForTravel];
				};
			} else {
				if (!(_unit getVariable ["incapacitated",false])) then {
					_positionX = _positionX findEmptyPosition [1,50,typeOf _unit];
					_unit setPosATL _positionX;
					if (isPlayer leader _unit) then {_unit setVariable ["rearming",false]};
					_unit doWatch objNull;
					_unit doFollow leader _unit;
				} else {
					_positionX = _positionX findEmptyPosition [1,50,typeOf _unit];
					_unit setPosATL _positionX;
				};
				_chargeForTravel = _chargeForTravel + 50; 
				diag_log format["Unit travel. Tally %1",_chargeForTravel];
			};
		};
	} forEach _movedUnits;

	if (_enemyBase) then {
		if (_esHC) then {
			[0,-_chargeForTravel] remoteExec ["A3A_fnc_resourcesFIA",2];
			systemChat format["Faction paid %1%2 for squad fast travel to the vehicle", _chargeForTravel,A3A_faction_civ get "currencySymbol"];
		} else {
			[-_chargeForTravel, player] remoteExec ["A3A_fnc_addMoneyPlayer", player];
			systemChat format["You paid %1%2 for squad fast travel to the vehicle", _chargeForTravel,A3A_faction_civ get "currencySymbol"];
		};
	};

	if (!_esHC) then {
		disableUserInput false;
		cutText [localize "STR_hints_FT_dest","BLACK IN",1]
	} else {
		[localize "STR_A3A_Dialogs_fast_travel_header", format [localize "STR_A3A_Dialogs_fast_travel_arrived_hc",groupID _groupX]] call A3A_fnc_customHint;
	};

	if (_forcedX) then {
		forcedSpawn deleteAt (forcedSpawn find _base);
	};
	
	sleep 5;
	{_x allowDamage true} forEach _ftUnits;
	['off'] call SCRT_fnc_ui_toggleMenuBlur;
} else {
	[localize "STR_A3A_Dialogs_fast_travel_header", localize "STR_A3A_Dialogs_fast_travel_missclick"] call SCRT_fnc_misc_deniedHint;
};

if (!_esHC) then { openMap false };
