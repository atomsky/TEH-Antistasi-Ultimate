/* Recheck target, caller, reach and action-specific state immediately before use. */
params ["_target", "_caller", "_action"];
if (isNull _target || {isNull _caller} || {!alive _caller}) exitWith {false};
if !(_caller isEqualTo player) exitWith {false};
if (!isNull objectParent _caller || {lifeState _caller isEqualTo "INCAPACITATED"}) exitWith {false};
if (([_caller, _target] call teh_actions_fnc_distanceToTarget) > (_action # 6)) exitWith {false};
[_target, _caller, _action # 5] call (_action # 3)
