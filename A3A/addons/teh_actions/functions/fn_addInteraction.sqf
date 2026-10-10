/*
    [class, descriptor] call teh_actions_fnc_addInteraction
    Descriptor: [id, label, icon, condition, statement, arguments, distance, expand, priority]
    expand may return a flat array of descriptors instead of showing the parent.
    Positive priority pins an action above normal rows.
    The registry and object actions are deliberately local to each client.
*/
params ["_class", "_action"];
if (!hasInterface) exitWith {false};

private _registry = missionNamespace getVariable ["TEH_actions_registry", []];
private _id = _action # 0;
private _old = _registry findIf {(_x # 0) isEqualTo _class && {((_x # 1) # 0) isEqualTo _id}};
if (_old >= 0) then {
    _registry set [_old, [_class, _action]];
} else {
    _registry pushBack [_class, _action];
};
missionNamespace setVariable ["TEH_actions_registry", _registry];

private _classes = missionNamespace getVariable ["TEH_actions_classes", []];
if !(_class in _classes) then {
    _classes pushBack _class;
    missionNamespace setVariable ["TEH_actions_classes", _classes];
    [_class, "InitPost", {(_this # 0) call teh_actions_fnc_initObject}, true, [], true] call CBA_fnc_addClassEventHandler;
};
true
