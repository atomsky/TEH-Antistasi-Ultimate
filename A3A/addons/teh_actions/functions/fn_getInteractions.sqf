/* Returns the visible flat list for the snapshotted target and caller. */
params ["_target", "_caller"];
private _topActions = [];
private _available = [];
private _addAvailable = {
    params ["_action"];
    if ((_action param [8, 0]) > 0) then {
        _topActions pushBack _action;
    } else {
        _available pushBack _action;
    };
};
{
    _x params ["_class", "_action"];
    if (_target isKindOf _class && {[_target, _caller, _action] call teh_actions_fnc_canInteract}) then {
        private _expand = _action param [7, objNull];
        if !(_expand isEqualType {}) then {
            [_action] call _addAvailable;
        } else {
            {
                if ([_target, _caller, _x] call teh_actions_fnc_canInteract) then {
                    [_x] call _addAvailable;
                };
            } forEach ([_target, _caller, _action # 5] call _expand);
        };
    };
} forEach (missionNamespace getVariable ["TEH_actions_registry", []]);
_topActions + _available
