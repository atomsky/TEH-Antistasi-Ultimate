#include "..\..\script_component.hpp"
FIX_LINE_NUMBERS()
if (isDedicated) exitWith {};
params ["_newUnit","_oldUnit"];

if (missionNamespace getVariable ["TEH_ballsOfSteel",0] == 1) exitWith {
	["hardcoreLoss",false,true] remoteExec ["BIS_fnc_endMission"];
};

if (isNull _oldUnit) exitWith {};

private _civilRespawn = (TEH_warTierZero && !(_oldUnit getVariable ["TEH_Rebel",false]));

waitUntil {alive _newUnit};

//When LAN hosting, Bohemia's Zeus module code will cause the player lose Zeus access if the body is deleted after respawning.
//This is a workaround that re-assigns curator to the player if their body is deleted.
//It will only run on LAN hosted MP, where the hoster is *always* admin, so we shouldn't run into any issues.
if (isServer) then {
	_oldUnit addEventHandler ["Deleted", {
		[] spawn {
			sleep 1;		// should ensure that the bug unassigns first
			{ player assignCurator _x } forEach allCurators;
		};
	}];
};

removeAllActions _oldUnit;
[_oldUnit] remoteExecCall[QFUNCMAIN(postmortem), 2];

[_newUnit,"spotting"] call A3A_fnc_flagaction;

_oldUnit setVariable ["incapacitated",false,true];
_newUnit setVariable ["incapacitated",false,true];

[true] call A3A_fnc_selfReviveReset;

_owner = _oldUnit getVariable ["owner",_oldUnit];

if (_owner != _oldUnit) exitWith {
	[localize "STR_A3A_proxy_remoteai_header", localize "STR_A3A_proxy_remoteai_desc"] call A3A_fnc_customHint; 
	selectPlayer _owner; 
	disableUserInput false; 
	deleteVehicle _newUnit
};

_nul = [0,-1,getPos _oldUnit] remoteExec ["A3A_fnc_citySupportChange",2];

_score = _oldUnit getVariable ["score",0];
_punish = _oldUnit getVariable ["punish",0];
_moneyX = _oldUnit getVariable ["moneyX",0];
_moneyX = round (_moneyX - (_moneyX * (deathPenalty / 100)));
_eligible = _oldUnit getVariable ["eligible",true];
_rankX = _oldUnit getVariable ["rankX","PRIVATE"];

if (_moneyX < 0) then {_moneyX = 0};

_newUnit setVariable ["score",_score - 10,true];
_newUnit setVariable ["owner",_newUnit,true];
_newUnit setVariable ["punish",_punish,true];
_newUnit setVariable ["respawning",false];
_newUnit setVariable ["moneyX",_moneyX,true];
_newUnit setVariable ["compromised",0];
_newUnit setVariable ["eligible",_eligible,true];
_oldUnit setVariable ["eligible",false,true];
_newUnit setVariable ["spawner",true,true];
_oldUnit setVariable ["spawner",nil,true];
[_newUnit,false] remoteExec ["setCaptive",0,_newUnit];
_newUnit setRank (_rankX);
_newUnit setVariable ["rankX",_rankX,true];
{
	_newUnit addOwnedMine _x;
} count (getAllOwnedMines (_oldUnit));
{
	if (_x getVariable ["owner", ObjNull] == _oldUnit) then {
		_x setVariable ["owner", _newUnit, true];
	};
} forEach (units group _newUnit);

private _deathPenaltyNum = nil;
private _warningText = nil;
if (!_civilRespawn) then {
	switch (loseHROnDeath) do
	{
		//no HR loss on death
		case 0:
		{
			call A3A_fnc_checkLossCondition;
		};
		
		//no chat msg on player death
		case 1:
		{
			call A3A_fnc_checkLossCondition;

			if(tierWar >= 2) exitWith
			{
				[-1,0] remoteExec ["A3A_fnc_resourcesFIA",2];
			};
		};

		//chat msg on player death
		case 2:
		{
			call A3A_fnc_checkLossCondition;

			if(tierWar >= 2) exitWith
			{
				[-1,0] remoteExec ["A3A_fnc_resourcesFIA",2];

				_deathPenaltyNum = "-1";

				if(((server getVariable ["hr",0]) <= 10) && (tierWar >= 2)) then
				{
					_warningText = "<t font ='PuristaBold' align = 'center' size='0.8' color='#bd0000'>" + localize "STR_A3AU_respawn_warning" +"</t>"+"<br />"+"<t font ='PuristaSemibold' align = 'center' size='0.55' color='#ebebeb'>" + format [localize "STR_A3AU_respawn_warning_info", (A3A_faction_reb get "name"), ((server getVariable ["hr",0])-1)]+"</t>"+"<br />"+"<t font ='PuristaSemibold' align = 'center' size='0.4' color='#ebebeb'>" + format [localize "STR_chats_player_kia", _deathPenaltyNum]+"</t>";
					[_warningText,0,safezoneY+0.05] spawn BIS_fnc_dynamicText;
				};

				if(((server getVariable ["hr",0]) > 10) && (tierWar >= 2)) then
				{
					_warningText = "<t font ='PuristaSemibold' align = 'center' size='0.5' color='#ebebeb'>" + format [localize "STR_chats_player_kia", _deathPenaltyNum]+"</t>";
					[_warningText,0,safezoneY+0.05] remoteExec ["BIS_fnc_dynamicText"];
				};
			};
		};

		default {Error_1("Lose HR on death num was not recognized. Condition given: %1", loseHROnDeath)};
	};
};

disableUserInput false;
if (_oldUnit == theBoss) then
{
	[_newUnit, true] remoteExec ["A3A_fnc_theBossTransfer", 2];
};

//EQUIPMENT

if (_civilRespawn) then {
	[_newUnit] remoteExec ["A3A_fnc_goUndercover",0,_newUnit];
	private _loadouts = (A3A_customUnitTypes getVariable ["loadouts_civ_militia_Man", []]) select 0;
	_newUnit setUnitLoadout selectRandom _loadouts;
	_newUnit setVariable ["moneyX",300,true];
	waituntil {sleep 0.1;  captive _newUnit};
	private _respawnPos = (getMarkerPos selectRandom citiesX);

	respawnTeamPlayer setMarkerAlphaLocal 0;

    private _safePos = [
        _respawnPos, //center
        0, //minimal distance
        50, //maximumDistance
        1, //object distance
        0, //water mode
        0, //maximum terrain gradient
        0, //shore mode
        [], //blacklist positions
        [_respawnPos, _respawnPos] //default position
    ] call BIS_fnc_findSafePos;
    _newUnit setPos _safePos;
    _newUnit setDir (random 360);
} else {
	//Give them a map, in case they're commander and need to replace petros.
	[_newUnit] call A3A_fnc_dress;

	private _prefix = "loadouts_reb_militia_";
	private _loadout =  switch (typeOf _newUnit) do {
		case "I_G_medic_F":  { "Medic" }; 
		case "I_G_Soldier_TL_F": { "SquadLeader" };
		case "I_G_Soldier_F": { "Rifleman" };
		case "I_G_Soldier_GL_F": { "Grenadier" };
		case "I_G_Soldier_AR_F": { "MachineGunner" };
		case "I_G_engineer_F":  { "Engineer" };
		default { "Rifleman" };
	};

	[_newUnit, 0, _prefix + _loadout] call A3A_fnc_equipRebel;
	_newUnit setCaptive false;
};

if (!isPlayer (leader group _newUnit)) then {(group _newUnit) selectLeader _newUnit};
_newUnit addEventHandler ["FIRED", 
{
	_player = _this select 0;
	if (captive _player) then {
		if ({if (((side _x == Occupants) or (side _x == Invaders)) and (_x distance _player < 300)) exitWith {1}} count allUnits > 0) then
		{
			[_player,false] remoteExec ["setCaptive",0,_player];
			_player setCaptive false;
		}
		else
		{
			_city = [citiesX,_player] call BIS_fnc_nearestPosition;
			_size = [_city] call A3A_fnc_sizeMarker;
			_dataX = server getVariable _city;
			if (random 100 < _dataX select 2) then
			{
				if (_player distance getMarkerPos _city < _size * 1.5) then
				{
					[_player,false] remoteExec ["setCaptive",0,_player];
					_player setCaptive false;
					if (vehicle _player != _player) then
					{
						{if (isPlayer _x) then {[_x,false] remoteExec ["setCaptive",0,_x]; _x setCaptive false}} forEach ((assignedCargo (vehicle _player)) + (crew (vehicle _player)) - [_player]);
					};
				};
			};
		};
	};
}];

_newUnit addEventHandler ["InventoryOpened",
{
	private ["_playerX","_containerX","_typeX"];
	_control = false;
	_playerX = _this select 0;
	if (captive _playerX) then
	{
		_containerX = _this select 1;
		_typeX = typeOf _containerX;
		if (((_containerX isKindOf "CAManBase") and (!alive _containerX)) or (_typeX in [A3A_faction_occ get "ammobox", A3A_faction_inv get "ammobox"])) then
		{
			if ({if (((side _x== Invaders) or (side _x== Occupants)) and (_x knowsAbout _playerX > 1.4)) exitWith {1}} count allUnits > 0) then
			{
				[_playerX,false] remoteExec ["setCaptive",0,_playerX];
				_playerX setCaptive false;
			}
			else
			{
				_city = [citiesX,_playerX] call BIS_fnc_nearestPosition;
				_size = [_city] call A3A_fnc_sizeMarker;
				_dataX = server getVariable _city;
				if (random 100 < _dataX select 2) then
				{
					if (_playerX distance getMarkerPos _city < _size * 1.5) then
					{
						[_playerX,false] remoteExec ["setCaptive",0,_playerX];
						_playerX setCaptive false;
					};
				};
			};
		};
	};
	_control
}];

if (hasInterface) then {
	[_newUnit] call A3A_fnc_punishment_FF_addEH;
	[] spawn A3A_fnc_outOfBounds;
};
_newUnit addEventHandler ["HandleHeal",
{
	_player = _this select 0;
	if (captive _player) then
	{
		if ({((side _x== Invaders) or (side _x== Occupants)) and (_x knowsAbout _player > 1.4)} count allUnits > 0) then
		{
			[_player,false] remoteExec ["setCaptive",0,_player];
			_player setCaptive false;
		}
		else
		{
			_city = [citiesX,_player] call BIS_fnc_nearestPosition;
			_size = [_city] call A3A_fnc_sizeMarker;
			_dataX = A3A_townData get _city;
			if (random 100 < _dataX select 2) then
			{
				if (_player distance getMarkerPos _city < _size * 1.5) then
				{
					[_player,false] remoteExec ["setCaptive",0,_player];
					_player setCaptive false;
				};
			};
		};
	}
}];
_newUnit addEventHandler ["WeaponAssembled",
{
	private _veh = _this select 1;
	[_veh, teamPlayer] call A3A_fnc_AIVEHinit;		// will flip/capture if already initialized
	if (_veh isKindOf "StaticWeapon") then {
		if (not(_veh in staticsToSave)) then {
			staticsToSave pushBack _veh;
			publicVariable "staticsToSave";
		};
		_markersX = markersX select {sidesX getVariable [_x,sideUnknown] == teamPlayer};
		_pos = position _veh;
		if (_markersX findIf {_pos inArea _x} != -1) then {
			[(localize "STR_antistasi_actions_move_assets_static_deployed_header"), (localize "STR_antistasi_actions_move_assets_static_deployed_hint")] call A3A_fnc_customHint;
		};
	};
}];

if (areRivalsDiscovered) then {
	_newUnit addEventHandler ["Killed", {
		params ["_unit", "_killer", "_instigator", "_useEffects"];
		if (_killer getVariable ["isRival", false]) then {
			[-5, 60] remoteExec ["SCRT_fnc_rivals_reduceActivity",2];
		};
	}];
};

[] call A3A_fnc_unitTraits;
[] spawn A3A_fnc_statistics;

if (fatigueEnabled isEqualTo false) then { 
	_newUnit enableFatigue false; 
}; 
 
if (staminaEnabled isEqualTo false) then { 
	_newUnit enableStamina false; 
}; 
 
private _newWeaponSway = swayEnabled / 100;
_newUnit setCustomAimCoef _newWeaponSway;
