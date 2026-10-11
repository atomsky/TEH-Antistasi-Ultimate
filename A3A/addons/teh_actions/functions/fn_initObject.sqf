/* Runtime root for vehicles/boxes; CAManBase uses a config UserAction instead. */
params ["_object"];
if (!hasInterface || {isNull _object} || {_object isKindOf "CAManBase"} || {_object getVariable ["TEH_actions_rootAdded", false]}) exitWith {};

private _radius = (2 + ((boundingBoxReal _object) # 2)) min 50;
private _id = _object addAction [
    "TEH Actions",
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        [_arguments # 0, _caller] call teh_actions_fnc_openInteractionMenu;
    },
    [_object], 3, true, true, "",
    "[_originalTarget, _this] call teh_actions_fnc_hasInteractions",
    _radius, false
];
_object setVariable ["TEH_actions_rootAdded", true];
_object setVariable ["TEH_actions_rootId", _id];
