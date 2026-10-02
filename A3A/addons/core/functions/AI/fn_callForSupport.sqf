/*  Simulates the call for support by a group by making the teamleader a bit more dumb for a time

    Execution on: HC or Server

    Scope: Internal

    Params:
        _group: GROUP : The group which should call support
        _target: OBJECT : The target object the group wants support against

    Returns:
        Nothing
*/
#include "..\..\script_component.hpp"
FIX_LINE_NUMBERS()

params ["_group", "_target"];

private _side = side _group;

if ((_side isEqualTo Occupants && areOccupantsDefeated) || {(_side isEqualTo Invaders && areInvadersDefeated)}) exitWith {
    Info_1("%1 faction had been defeated earlier, aborting calling support.", _side);
};

if(_side != Occupants && {_side != Invaders}) exitWith {
    Error_2("Non-enemy group %1 of side %2 managed to call callForSupport", _group, _side);
};

private _groupLeader = leader _group;
private _isRival = _groupLeader getVariable ["isRival", false];

if (_isRival) then {
    Error("Rivals are not using general supports, aborting.");
};

//If groupleader is down, dont call support
if !(_groupLeader call A3A_fnc_canFight) exitWith {};

if((_group getVariable ["A3A_canCallSupportAt", -1]) > time) exitWith {};

private _timeToCallSupport = (15 + random 15) / A3A_balancePlayerScale;
_group setVariable ["A3A_canCallSupportAt", time + 15*_timeToCallSupport];

ServerDebug_4("Leader of %1 (side %2) is starting to request support against %3 (type %4)", _group, _side, _target, typeof _target);

{_groupLeader disableAI _x} forEach ["ANIM","AUTOTARGET","FSM","MOVE","TARGET"];

_groupLeader setVariable ["callAnimsDone",false];
_groupLeader setVariable ["timeToCall",_timeToCallSupport];
_groupLeader setVariable ["callSuccess",false];
_groupLeader playMoveNow "Acts_SupportTeam_Front_ToKneelLoop";

_groupLeader spawn {
    sleep random 3;
    playSound3D [(selectRandom radioSoundsIn), _this, false, getPosASL _this, 3, 1, 30];
};

_groupLeader addEventHandler ["AnimDone", {
    params ["_supportCaller"];
    if (([_supportCaller] call A3A_fnc_canFight) && {(time <= (_supportCaller getVariable ["timeToCall",time])) && {_supportCaller == vehicle _supportCaller}}) then {
        _supportCaller spawn {
            sleep random 3;
            playSound3D [(selectRandom radioSoundsMid), _this, false, getPosASL _this, 3, 1, 30];
        };
        _supportCaller playMoveNow "Acts_SupportTeam_Front_KneelLoop";
    } else {
        _supportCaller removeEventHandler ["AnimDone",_thisEventHandler];
        _supportCaller setVariable ["callAnimsDone",true];
        if (([_supportCaller] call A3A_fnc_canFight) && {_supportCaller == vehicle _supportCaller}) then {
            _supportCaller playMoveNow "Acts_SupportTeam_Front_FromKneelLoop";
            _supportCaller spawn {
                sleep random 3;
                playSound3D [(selectRandom radioSoundsOut), _this, false, getPosASL _this, 3, 1, 30];
            };
            _supportCaller setVariable ["callSuccess",true];
        };
    };
}];

waitUntil {sleep 0.5; (_groupLeader getVariable ["callAnimsDone",true])};

_groupLeader setVariable ["radioAnimsDone",nil];
_groupLeader setVariable ["timeToCall", nil];

{_groupLeader enableAI _x} forEach ["ANIM","AUTOTARGET","FSM","MOVE","TARGET"];

//If the group leader survived the call, proceed
if(_groupLeader call A3A_fnc_canFight && _groupLeader getVariable ["callSuccess",true]) then
{
    // why here? Are we intercepting the radio traffic?
    private _revealed = [getPosATL _groupLeader, side _group] call A3A_fnc_calculateSupportCallReveal;
    private _precision = if !(_target isEqualType objNull) then [{ 0 }, { _group knowsAbout _target }];
    //Starting the support
    ServerDebug_2("%1 managed to request support, reveal value is %2", _group, _revealed);
    [_side, _target, getPosATL _groupLeader, _precision, _revealed] remoteExec ["A3A_fnc_requestSupport", 2];
}
else
{
    //Support call failed, reset cooldown
    ServerDebug_1("%1 failed to request support as the leader is dead or down", _group);
    _group setVariable ["A3A_canCallSupportAt", nil];
};
