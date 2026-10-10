/* Removes a locally registered class action. Existing root actions hide themselves. */
params ["_class", "_id"];
private _registry = missionNamespace getVariable ["TEH_actions_registry", []];
private _index = _registry findIf {(_x # 0) isEqualTo _class && {((_x # 1) # 0) isEqualTo _id}};
if (_index < 0) exitWith {false};
_registry deleteAt _index;
missionNamespace setVariable ["TEH_actions_registry", _registry];
true
