/* CBA InitPost runs on each client, including retroactively for JIP entities. */
params ["_object"];
if (!hasInterface || {isNull _object} || {_object getVariable ["TEH_actions_rootAdded", false]}) exitWith {};

private _radius = (2 + ((boundingBoxReal _object) # 2)) min 50;
private _id = _object addAction [
    "TEH Actions",
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        [_arguments # 0, _caller] call teh_actions_fnc_openInteractionMenu;
    },
    [_object], 1.5, true, true, "",
    "[_originalTarget, _this] call teh_actions_fnc_hasInteractions",
    _radius, false
];
_object setVariable ["TEH_actions_rootAdded", true];
_object setVariable ["TEH_actions_rootId", _id];
