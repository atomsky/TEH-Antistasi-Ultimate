/* Move the selection as well as the list's visible scroll position. */
params ["_list", "_delta"];
private _count = lbSize _list;
if (_count < 2 || {_delta == 0}) exitWith {false};

private _index = lbCurSel _list;
private _step = if (_delta > 0) then {-1} else {1};
_list lbSetCurSel (((_index max 0) + _step) max 0 min (_count - 1));
true
