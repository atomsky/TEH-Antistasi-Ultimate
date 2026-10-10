/* Register the module's client-local actions for the TEH flat interaction list. */
if (!hasInterface) exitWith {};

private _register = {
    params ["_classes", "_descriptor"];
    {[_x, _descriptor] call teh_actions_fnc_addInteraction} forEach _classes;
};
private _vehicleClasses = ["LandVehicle", "Air", "Ship"];

// Pin Gather above other actions in the flat TEH Actions list.
private _gather = [
    "LootVehicleGatherAllLoot", "Gather all loot", "a3\ui_f\data\IGUI\Cfg\Actions\loadVehicle_ca.paa",
    {true},
    {
        params ["_target", "_player"];
        private _dist = 5000;
        private _leads = [];
        {
            if ((side _x == Occupants || side _x == Invaders) && {side leader _x == side _x}) then {
                _leads pushBack leader _x;
            };
        } forEach allGroups;
        if !(_leads isEqualTo []) then {
            private _nearestLead = [_leads, _target] call BIS_fnc_nearestPosition;
            private _calc = floor (_target distance2D _nearestLead) - 50;
            _dist = _dist min (_calc max 5);
        };
        systemChat format ["LootVehicle: Sending troops to gather loot in %1 m area", _dist];
        _player setCaptive false;
        private _holders = nearestObjects [_target, ["WeaponHolderSimulated"], _dist, false];
        private _containerList = nearestObjects [
            _target,
            ["CAManBase", "WeaponHolder", (A3A_faction_occ get "surrenderCrate"),
                (A3A_faction_inv get "surrenderCrate"), (A3A_faction_riv get "surrenderCrate"),
                "VirtualReammoBox_small_F"],
            _dist, false
        ] select {!alive _x || {!(_x isKindOf "CAManBase")}};
        private _loots = _holders + _containerList;
        if !(_loots isEqualTo []) then {
            [_target, _loots, _player, false] spawn loot_vehicle_fnc_transferToVehicle;
        } else {
            systemChat "LootVehicle: Nothing to gather.";
        };
    }, [], 2, objNull, 1
];
[_vehicleClasses + ["ReammoBox_F"], _gather] call _register;

// Pack a dead unit and nearby dropped items into a fresh box.
[["CAManBase"], [
    "LootVehiclePackToBox", "Pack to the box", "a3\ui_f\data\IGUI\Cfg\Actions\unloadVehicle_ca.paa",
    {params ["_target"]; !alive _target},
    {
        params ["_target", "_player"];
        private _pos = getPosATL _target;
        private _box = createVehicle ["VirtualReammoBox_small_F", [_pos # 0, _pos # 1, (_pos # 2) + 1], [], 0, "CAN_COLLIDE"];
        systemChat "LootVehicle: Scavenging the surroundings";
        private _holders = nearestObjects [_target, ["WeaponHolderSimulated"], 5];
        private _containerList = nearestObjects [_target, ["CAManBase", "WeaponHolder"], 3] select {
            !alive _x || {!(_x isKindOf "CAManBase")}
        };
        [_box, _holders + _containerList, _player, true] spawn loot_vehicle_fnc_transferToVehicle;
        _player setCaptive false;
    }, [], 2
]] call _register;

// Saved profile loadouts are exposed as individual rows in the flat list.
[["SoldierGB"], [
    "TEH_SelectAILoadout", "Select AI loadout", "\A3\Ui_f\data\GUI\Rsc\RscDisplayArsenal\uniform_ca.paa",
    {
        params ["_target"];
        alive _target && {!isPlayer _target} && {!isNull boxX} && {_target distance boxX < 50}
    }, {}, [], 2,
    {
        params ["_target", "_player"];
        private _choices = [];
        private _data = profileNamespace getVariable ["bis_fnc_saveInventory_data", []];
        for "_i" from 0 to ((count _data) - 2) step 2 do {
            private _name = _data # _i;
            private _blob = _data # (_i + 1);
            if !(_name isEqualType "" && {_blob isEqualType []} && {((toLower _name) find "ai ") == 0}) then {
                continue;
            };
            private _label = _name select [3];
            if (_label isEqualTo "") then {_label = _name};
            _choices pushBack [
                format ["TEH_SelectAILoadout_%1", _i],
                format ["Select AI loadout: %1", _label],
                "\A3\Ui_f\data\GUI\Rsc\RscDisplayArsenal\uniform_ca.paa",
                {
                    params ["_target"];
                    alive _target && {!isPlayer _target} && {!isNull boxX} && {_target distance boxX < 50}
                },
                {
                    params ["_target", "_player", "_params"];
                    _params params ["_templateName", "_loadoutBlob"];
                    if (isNull _target || {!alive _target} || {side _target != teamPlayer}) exitWith {
                        ["Loadout", "Invalid target"] call A3A_fnc_customHint;
                    };
                    if (isPlayer _target) exitWith {
                        ["Loadout", "Cannot apply AI loadout to a player"] call A3A_fnc_customHint;
                    };
                    if (isNull boxX || {_target distance boxX >= 50}) exitWith {
                        ["Loadout", "Bring the unit closer to the arsenal box"] call A3A_fnc_customHint;
                    };
                    // JNA accepts template, target unit, caller, and resolved blob.
                    [_templateName, _target, _player, _loadoutBlob] call JN_fnc_arsenal_loadInventory;
                },
                [_name, _blob], 2
            ];
        };
        if (_choices isEqualTo []) then {
            _choices pushBack [
                "TEH_SelectAILoadout_None", "No AI loadouts found",
                "\A3\Ui_f\data\GUI\Rsc\RscDisplayArsenal\uniform_ca.paa",
                {true},
                {["Loadout", "Save a loadout with the 'AI ' prefix first"] call A3A_fnc_customHint},
                [], 2
            ];
        };
        _choices
    }
]] call _register;

if (missionNamespace getVariable ["TEH_VehicleFlags", false]) then {
    [_vehicleClasses, [
        "TEH_attachFlag", "Change flag", "\A3\ui_f\data\igui\cfg\actions\takeflag_ca.paa",
        {params ["_target"]; alive _target},
        {
            params ["_target"];
            private _logic = "Logic" createVehicleLocal [0, 0, 0];
            _logic attachTo [_target, [0, 0, 0]];
            [_logic] call zen_modules_fnc_moduleAttachFlag;
        }, [], 2
    ]] call _register;
};

// The source vehicle stays fixed; the selected recipient is snapshotted in arguments.
[_vehicleClasses, [
    "TEH_QuickResupply", "Quick resupply", "\A3\Ui_f\data\IGUI\Cfg\Actions\reload_ca.paa",
    {
        params ["_target"];
        alive _target && {_target getVariable ["originalSide", sideUnknown] == teamPlayer}
            && {[_target] call loot_vehicle_fnc_isResupplySource}
    }, {}, [], 2,
    {
        params ["_target", "_player"];
        private _vehicles = nearestObjects [_target, ["LandVehicle", "Air", "Ship"], LootVehicleDistance] select {alive _x};
        _vehicles = _vehicles - [_target];
        _vehicles pushBack _target;
        private _recipients = [_player] + _vehicles;
        _recipients apply {
            private _recipient = _x;
            private _label = if (_recipient isEqualTo _player) then {
                "Quick resupply: Yourself"
            } else {
                format ["Quick resupply: %1 (%2m)", getText (configOf _recipient >> "displayName"), (_player distance _recipient) toFixed 1]
            };
            [
                format ["TEH_QuickResupply_%1", _forEachIndex], _label,
                "\A3\Ui_f\data\IGUI\Cfg\Actions\reload_ca.paa",
                {
                    params ["_source", "_caller", "_recipient"];
                    !isNull _recipient && {alive _recipient}
                        && {_recipient isEqualTo _caller || {_recipient distance _source <= LootVehicleDistance}}
                        && {alive _source}
                        && {_source getVariable ["originalSide", sideUnknown] == teamPlayer}
                        && {[_source] call loot_vehicle_fnc_isResupplySource}
                },
                {
                    params ["_source", "_caller", "_recipient"];
                    // JNA quickReload waits for cargo clearing, so invoke it scheduled.
                    [_recipient] spawn JN_fnc_arsenal_quickReload;
                },
                _recipient, 2
            ]
        }
    }
]] call _register;

[_vehicleClasses, [
    "LootVehicleSellAction", "Sell Vehicle", "",
    {params ["_target"]; count crew _target == 0},
    {
        params ["_target", "_player"];
        if ([getPosATL _player] call A3A_fnc_enemyNearCheck) exitWith {
            ["Sell Vehicle", "Can't sell this vehicle when there are enemies nearby"] call SCRT_fnc_misc_deniedHint;
        };
        [_player, _target] spawn A3A_fnc_sellVehicle;
    }, [], 2
]] call _register;

// Both the former direct nearest-holder action and explicit vehicle choices are rows.
[_vehicleClasses + ["B_CargoNet_01_ammo_F"], [
    "LootVehicleTransferAction", "Unload Cargo", "a3\ui_f\data\IGUI\Cfg\Actions\unloadVehicle_ca.paa",
    {
        params ["_target"];
        !(([_target, _target] call loot_vehicle_fnc_getCargoHolders) isEqualTo [])
    }, {}, [], 2,
    {
        params ["_target", "_player"];
        private _choices = [[
            "LootVehicleTransferNearest", "Unload Cargo: Nearest holder",
            "a3\ui_f\data\IGUI\Cfg\Actions\unloadVehicle_ca.paa",
            {!(([_this # 0, _this # 0] call loot_vehicle_fnc_getCargoHolders) isEqualTo [])},
            {
                params ["_target", "_player"];
                ([_player, _target] call loot_vehicle_fnc_getCargoHolders) params [["_nearest", objNull]];
                if (isNull _nearest) exitWith {
                    systemChat "LootVehicle: Error: couldn't find any nearby vehicle";
                };
                systemChat "LootVehicle: Using nearest vehicle";
                [_nearest, [_target], _player, false] spawn loot_vehicle_fnc_transferToVehicle;
            }, [], 2
        ]];
        {
            private _recipient = _x;
            _choices pushBack [
                format ["LootVehicleTransfer_%1", _forEachIndex],
                format ["Unload Cargo: %1 (%2m)", getText (configOf _recipient >> "displayName"), (_player distance _recipient) toFixed 1],
                "a3\ui_f\data\IGUI\Cfg\Actions\unloadVehicle_ca.paa",
                {
                    params ["_source", "_caller", "_recipient"];
                    !isNull _recipient && {_recipient in ([_source] call loot_vehicle_fnc_getTransferDestinations)}
                },
                {
                    params ["_source", "_caller", "_recipient"];
                    [_recipient, [_source], _caller, false] spawn loot_vehicle_fnc_transferToVehicle;
                },
                _recipient, 2
            ];
        } forEach ([_target] call loot_vehicle_fnc_getTransferDestinations);
        _choices
    }
]] call _register;

