# Declaring TEH Actions

TEH Actions has one flat, client-local action registry. Gameplay modules register descriptors; the `teh_actions` module supplies the root action, filters rows, opens the dialog, and executes the selected callback. Do not add separate root actions for each gameplay feature.

## Register an action

Register from client-side initialization (for example, an addon `XEH_postInit.sqf`). The `_register` helper below is the convention used by `loot_vehicle/functions/fn_registerActions.sqf`; it is local to that file, not a TEH API.

```sqf
if (!hasInterface) exitWith {};

private _register = {
    params ["_classes", "_descriptor"];
    {[_x, _descriptor] call teh_actions_fnc_addInteraction} forEach _classes;
};

[["CAManBase"], [
    "MyAddon_SearchBody",     // 0: stable ID
    "Search body",            // 1: row label
    "",                       // 2: icon path, or empty string
    {                         // 3: visibility/availability condition
        params ["_target", "_caller", "_arguments"];
        !alive _target
    },
    {                         // 4: callback when selected
        params ["_target", "_caller", "_arguments"];
        systemChat format ["Searching %1", typeOf _target];
    },
    [],                       // 5: arguments, passed unchanged to both code blocks
    2                         // 6: maximum TEH interaction distance in metres
]] call _register;
```

You may also call `[_class, _descriptor] call teh_actions_fnc_addInteraction` directly for a single class. The stable ID is unique **per registered class**: registering the same class and ID again replaces its descriptor instead of appending another one. To remove it, call `[_class, _id] call teh_actions_fnc_removeInteraction` on the client.

## Descriptor fields, in order

| Index | Field | Required | Meaning |
| --- | --- | --- | --- |
| 0 | ID | Yes | Stable string used for replacement/removal. |
| 1 | Label | Yes | Text shown in the flat list. |
| 2 | Icon | Yes | Texture path, or `""` for no icon. |
| 3 | Condition | Yes | Code receiving `[_target, _caller, _arguments]`, returning a Boolean. |
| 4 | Statement | Yes | Code receiving `[_target, _caller, _arguments]` when selected. |
| 5 | Arguments | Yes | Any value passed to condition, statement, and optional expansion code. |
| 6 | Distance | Yes | Maximum distance in metres, checked by TEH. |
| 7 | Expand | No | Code returning a flat array of child descriptors instead of showing this parent. |
| 8 | Priority | No | Positive number pins the row above normal rows; this is **not** the vanilla root-action priority. |

Use `objNull` in slot 7 when specifying priority without expansion, e.g. `[..., 2, objNull, 1]`. Normal rows retain registration order. Pinned rows also retain their registration order; different positive numbers do not create additional ranking levels.

The condition runs in the root action's visibility check, when the dialog builds its rows, and again immediately before the callback. Keep it fast, side-effect-free, and suitable for unscheduled execution. The callback runs on the activating **client** after the dialog closes; use your module's existing `spawn`, CBA event, or remote-execution path when gameplay effects require scheduling or another machine. The target and caller are snapshotted when the dialog opens, not reacquired from the cursor.

## Choose target classes

The registry matches `typeOf _target isKindOf _class` semantics, so registering for `CAManBase` covers its soldier and civilian descendants, including corpses. Registering one descriptor for `["LandVehicle", "Air", "Ship"]` covers those branches:

```sqf
private _vehicles = ["LandVehicle", "Air", "Ship"];
[_vehicles, _myVehicleDescriptor] call _register;
```

Use a narrower class to limit an action to that class and its descendants. Avoid registering the same intended row on both a parent and child class: a target matching both registrations can show two rows. Conditions decide whether a matched action is currently visible, not whether the class registration exists.

`CAManBase` gets its **root** `TEH Actions` entry from `CfgVehicles >> CAManBase >> UserActions`, which is unaffected by `removeAllActions`. Other classes currently get a client-local `addAction` root through CBA `InitPost`. Both entry points use the same registry, visibility check, and dialog. Gameplay modules should register descriptors the same way for either kind of target.

## Optional dynamic rows

Slot 7 may be a code block that receives `[_target, _caller, _arguments]` and returns child descriptors. The parent must pass its condition, but is not shown as a row. Each child must supply the usual fields 0–6 and is checked with its own condition and distance. For example:

```sqf
[["LandVehicle"], [
    "MyAddon_Choose", "Choose recipient", "",
    {params ["_target"]; alive _target},
    {}, [], 2,
    {
        params ["_target", "_caller", "_arguments"];
        [[
            "MyAddon_ChooseSelf", "Choose yourself", "",
            {true},
            {params ["_target", "_caller"]; systemChat name _caller},
            [], 2
        ]]
    }
]] call _register;
```

Expansion happens when opening the dialog, not for every root visibility check. If the parent condition is true but expansion returns no available children, the root may be visible yet open no dialog. Make the parent condition accurately represent availability, or return an informative fallback child row (as `loot_vehicle` does for missing AI loadouts).

For a working module example, see `loot_vehicle/functions/fn_registerActions.sqf`.
