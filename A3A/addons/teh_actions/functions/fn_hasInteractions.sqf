/* Used by addAction's visibility condition; avoid generating dynamic choices per frame. */
params ["_target", "_caller"];
private _found = false;
{
    _x params ["_class", "_action"];
    if (_target isKindOf _class && {[_target, _caller, _action] call teh_actions_fnc_canInteract}) exitWith {
        _found = true;
    };
} forEach (missionNamespace getVariable ["TEH_actions_registry", []]);
_found
