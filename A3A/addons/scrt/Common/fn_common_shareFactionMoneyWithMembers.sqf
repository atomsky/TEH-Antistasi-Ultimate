#include "..\defines.inc"
FIX_LINE_NUMBERS()

if (TEH_WarTierZero && !(commanderX getVariable ["TEH_Rebel",false])) exitWith {
	[
		localize "STR_TEH_SHARE_MONEY_FAILED",
		localize "STR_TEH_SHARE_MONEY_TIER_ZERO_DENIED"
	] call A3A_fnc_customHint
};


params [["_amount", 0]];

private _resourcesFIA = server getVariable ["resourcesFIA", 0];

private _affectedPlayers = call SCRT_fnc_misc_getRebelPlayers;

if (membershipEnabled) then {
    _affectedPlayers = _affectedPlayers select {
        private _uid = getPlayerUID _x;
        private _isMember = _x call A3A_fnc_isMember;
        _isMember
    };
};

private _playersCount = count _affectedPlayers;

if (_playersCount < 1) exitWith {
    Info("No rebel players to share money with.");
};

private _reserveMinimum = ceil ((_resourcesFIA * 0.3) max 1000);
private _shareableResources = (_resourcesFIA - _reserveMinimum) max 0;

private _maxSharePerPlayer = floor ((_shareableResources / _playersCount) / 100) * 100;
_maxSharePerPlayer = _maxSharePerPlayer min 25000;

if (_maxSharePerPlayer < 100) exitWith {
    Info("Not enough rebel resources to share while keeping reserve.");
    [
        localize "STR_antistasi_actions_common_notifications_share_money_title",
        localize "STR_antistasi_actions_common_notifications_share_money_not_enough_text"
    ] remoteExecCall ["A3A_fnc_customHint", theBoss];
};

private _sharePerPlayer = if (_amount > 0) then {
    floor (((_amount max 100) min 25000) / 100) * 100;
} else {
    _maxSharePerPlayer;
};

if (_sharePerPlayer > _maxSharePerPlayer) exitWith {
    Info("Not enough rebel resources to share requested amount while keeping reserve.");
    [
        localize "STR_antistasi_actions_common_notifications_share_money_title",
        localize "STR_antistasi_actions_common_notifications_share_money_not_enough_text"
    ] remoteExecCall ["A3A_fnc_customHint", theBoss];
};

private _totalShare = _sharePerPlayer * _playersCount;

Info_2("Share per player: %1, quantity of players: %2", str _sharePerPlayer, str _playersCount);

{
    [_sharePerPlayer] remoteExec ["A3A_fnc_resourcesPlayer", _x];

    private _paycheckText = format [
        localize "STR_comms_mp_money_share",
        name theBoss,
        name _x,
        _sharePerPlayer,
        A3A_faction_civ get "currencySymbol"
    ];

    [petros, "income", _paycheckText] remoteExec ["A3A_fnc_commsMP", _x];
} forEach _affectedPlayers;

server setVariable ["resourcesFIA", (_resourcesFIA - _totalShare), true];