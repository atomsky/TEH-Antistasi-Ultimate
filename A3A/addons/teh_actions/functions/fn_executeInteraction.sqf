private _display = findDisplay 96001;
if (isNull _display) exitWith {false};
private _index = lbCurSel (_display displayCtrl 96002);
(_display getVariable ["TEH_actions_context", [objNull, objNull, []]]) params ["_target", "_caller", "_actions"];
if (_index < 0 || {_index >= count _actions}) exitWith {false};
private _action = _actions # _index;

if !([_target, _caller, _action] call teh_actions_fnc_canInteract) exitWith {
    closeDialog 0;
    hint "This action is no longer available.";
    false
};

closeDialog 0;
[_target, _caller, _action # 5] call (_action # 4);
true
