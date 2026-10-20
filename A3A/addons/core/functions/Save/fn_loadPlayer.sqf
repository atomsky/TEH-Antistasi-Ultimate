#include "..\..\script_component.hpp"
FIX_LINE_NUMBERS()
if (!isServer) exitWith {
    Error("Miscalled server-only function");
};

params ["_playerId", "_unit"];

if !(_playerId in A3A_playerSaveData) then {
    Info_1("No save found for _unit ID %1", _playerId);
	[_playerId, _unit] call A3A_fnc_resetPlayer;
    _unit setVariable ["TEH_Rebel",false,true];
} else {
    Info_2("Loading _unit data for ID %1 into unit %2", _playerId, _unit);

    private _playerHM = A3A_playerSaveData get _playerID;
    private _loadout = _playerHM get "loadoutPlayer";
    if (!isNil "_loadout") then { _unit setUnitLoadout _loadout };

    private _score = 0;
    private _rank = "PRIVATE";

    private _saveScore = _playerHM get "scorePlayer";
    if (!isNil "_saveScore" && { _saveScore isEqualType 0 }) then {_score = _saveScore};

    private _saveRank = _playerHM get "rankPlayer";
    if (!isNil "_saveRank" && { _saveRank isEqualType "" }) then {_rank = _saveRank};

    private _money = _playerHM get "moneyX";
    if (isNil "_money" || {!(_money isEqualType 0)}) then {_money = initialPlayerMoney};

    private _rebel = _playerHM get "TEH_Rebel";
    if (isNil "_rebel") then {
        diag_log "_rebel was not actually saved";
        _rebel = false;
    } else {
        diag_log (format ["_rebel retrieved is %1", _rebel]);
    };

    private _garage = _playerHM get "personalGarage";
    if (isNil "_garage" || {!(_garage isEqualType [])}) then {_garage = []};
    [_garage, _playerId] call HR_GRG_fnc_addVehiclesByClass;

    _unit setVariable ["score", _score, true];
    _unit setUnitRank _rank;
    _unit setVariable ["rankX", _rank, true];
    _unit setVariable ["moneyX", _money, true];
    _unit setVariable ["TEH_Rebel",_rebel,true];

    if (isNil { _playerHM get "pluginsData" }) then {
        _playerHM set["pluginsData", createHashMap];
    };

    [CBA_EVENT_CLIENT_PLAYER_LOAD, [_playerHM get "pluginsData"], owner _unit] call FUNCMAIN(triggerOwnerEvent);

    [] remoteExec ["A3A_fnc_statistics", _unit];
    _unit setVariable ["canSave", true, true];

    Info_5("Player %1: Score %2, rank %3, money %4, garage count %5", _playerId, _score, _rank, _money, count _garage);
};

private _opening = format["%1, %2 %3", worldName, (localize (rank _unit)), name _unit];

if (TEH_WarTierZero and !(_unit getVariable "TEH_Rebel")) then {
    respawnTeamPlayer setMarkerAlphaLocal 0;

    private _loadouts = (A3A_customUnitTypes getVariable ["loadouts_civ_militia_Man", []]) select 0;
	_unit setUnitLoadout selectRandom _loadouts;
	_unit setVariable ["moneyX",300,true];
	[_unit] remoteExec ["A3A_fnc_goUndercover",0,_unit];
    private _respawnPos = (getMarkerPos selectRandom citiesX);
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
    _unit setPos _safePos;
    _unit setDir (random 360);

    _opening = localize "STR_TEH_WTZ_OPENING";

} else {
    petros setCaptive false;
    respawnTeamPlayer setMarkerAlphaLocal 1;
};



private _colourTeamPlayer = teamPlayer call BIS_fnc_sideColor;
private _colorInvaders = Invaders call BIS_fnc_sideColor;

{
	_x set [3, 0.33]
} forEach [_colourTeamPlayer, _colorInvaders];

private _enableIntroAnimation = profileNamespace getVariable ["A3U_setting_enableIntroAnimation", true];

if (_enableIntroAnimation) then {
    [
        position _unit,
        _opening,
        50,
        50,
        90,
        0,
        [
            ["\a3\ui_f\data\map\markers\Nato\o_inf.paa", _colourTeamPlayer, markerPos "insertMrk", 1, 1, 0, "Insertion Point", 0],
            ["\a3\ui_f\data\map\markers\Nato\o_inf.paa", _colorInvaders, markerPos "towerBaseMrk", 1, 1, 0, "Radio Towers", 0]
        ]
    ] remoteExec ["BIS_fnc_establishingShot", _unit];
};