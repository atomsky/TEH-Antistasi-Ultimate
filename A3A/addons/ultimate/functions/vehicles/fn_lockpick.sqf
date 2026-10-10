#include "..\..\script_component.hpp"
/*
    Author:
        Maxx, Silence
    
    Description:
        Adds the action to lockpick a vehicle locally
    
    Params:
        _vehicle <OBJECT>
    
    Dependencies:
        vehicleLockpickTime
    
    Scope:
        Client
    
    Environment:
        Unscheduled
    
    Usage:
        [_vehicle] call A3U_fnc_lockpick;
    
    Return:
        N/A
*/

params ["_vehicle"];

if isNull(_vehicle) exitWith {};

private _pickRoll = vehicleLockpickTime / 2 + random vehicleLockpickTime;

_vehicle setVariable [QGVAR(lockpickAction),
    _vehicle addAction [
        localize "STR_A3AU_action_lockpick_title",
        {
            params ["_target", "_caller", "_actionId", "_arguments"];

            _arguments params [
                "_duration",
                "_title"
            ];

            if !([_caller, _target] call A3U_fnc_canLockpick) exitWith {};

            [_target, _caller] call A3U_fnc_lockpickOnStart;

            [
                _title,
                _duration,
                {
                    params ["_args"];
                    _args params ["_target", "_caller"];

                    _caller isEqualTo player
                    && {alive _caller}
                    && {[_caller, _target] call A3U_fnc_canLockpick}
                },
                {
                    params ["_args"];
                    _args params ["_target", "_caller"];

                    [_target] call A3U_fnc_lockpickOnSuccess;
                },
                {
                    params ["_args"];
                    _args params ["_target", "_caller"];

                    [_target, _caller] call A3U_fnc_lockpickOnFail;
                },
                [_target, _caller]
            ] call CBA_fnc_progressBar;
        },
        [
            _pickRoll,
            localize "STR_A3AU_action_lockpick_title"
        ],
        2026,
        false,
        true,
        "",
        QUOTE([ARR_3(_this,_target,true)] call A3U_fnc_canLockpick),
        5,
        false
    ]
];

nil;
