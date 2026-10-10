params ["_target", ["_caller", player]];
if (!hasInterface) exitWith {false};

private _actions = [_target, _caller] call teh_actions_fnc_getInteractions;
if (_actions isEqualTo []) exitWith {false};
if !(createDialog "TEH_Actions_Dialog") exitWith {false};

private _display = findDisplay 96001;
_display setVariable ["TEH_actions_context", [_target, _caller, _actions]];
private _list = _display displayCtrl 96002;
{
    private _row = _list lbAdd (_x # 1);
    if !((_x # 2) isEqualTo "") then {
        _list lbSetPicture [_row, _x # 2];
    };
} forEach _actions;
_list lbSetCurSel 0;
ctrlSetFocus _list;
true
