//-------------
// CBA settings
//-------------

[
	"LootVehicleDistance", // Internal setting name, should always contain a tag! This will be the global variable which takes the value of the setting.
	"SLIDER", // setting type
	["Max Transfer Distance", "Maxium distance interaction will show from target vehicle"], // Pretty name shown inside the ingame settings menu. Can be stringtable entry.
	"Antistasi Ultimate", // Pretty name of the category where the setting can be found. Can be stringtable entry.
	[1, 100, 15, 1], // data for this setting: [min, max, default, number of shown trailing decimals]
	1, // "_isGlobal" flag. Set this to true to always have this setting synchronized between all clients in multiplayer
	{} // function that will be executed once on mission start and every time the setting is changed.
] call CBA_fnc_addSetting;
[
	"LootVehicleSpeed", // Internal setting name, should always contain a tag! This will be the global variable which takes the value of the setting.
	"SLIDER", // setting type
	["Transfer speed in seconds", "Amount of seconds to transfer 100 units of weight\nFor example, most rifles in the game are 100 weight units, so a value of 1 second would take 1 second to transfer\nSet to 0 to disable interaction time."], // Pretty name shown inside the ingame settings menu. Can be stringtable entry.
	"Antistasi Ultimate", // Pretty name of the category where the setting can be found. Can be stringtable entry.
	[0, 10, 1, 1], // data for this setting: [min, max, default, number of shown trailing decimals]
	1, // "_isGlobal" flag. Set this to true to always have this setting synchronized between all clients in multiplayer
	{} // function that will be executed once on mission start and every time the setting is changed.
] call CBA_fnc_addSetting;

// Dedicated servers and headless clients do not need interaction actions or compatibility popups.
if (!hasInterface) exitWith {};

//-----------------------
// Compatibility checks
//-----------------------

private _loadedMods = getLoadedModsInfo;
private _loadedWorkshopIDs = _loadedMods apply { _x # 7 };
private _conflicts = [];

// Complete Antistasi Ultimate versions/forks that must not be loaded alongside TEH.
private _fullAUCWorkshopIDs = [
    "3020755032", // Antistasi Ultimate - Mod
    "3169463443", // Antistasi Ultimate - Public Testing
    "3387881294", // Antistasi Ultimate Modded
    "3335369377"  // Antistasi Ultimate (Full Arsenal)
];

private _loadedFullAUCMods = _loadedMods select { (_x # 7) in _fullAUCWorkshopIDs };
if !(_loadedFullAUCMods isEqualTo []) then {
    private _conflictLines = [
        "TEH Antistasi Ultimate is loaded together with another complete Antistasi Ultimate version:"
    ];

    {
        _conflictLines pushBack format ["- %1", _x # 0];
    } forEach _loadedFullAUCMods;

    _conflicts pushBack _conflictLines;
};

// Stable and Public Test compatibility patches are mutually exclusive.
if ("3747933298" in _loadedWorkshopIDs && {"3783217256" in _loadedWorkshopIDs}) then {
    _conflicts pushBack [
        "Both Point Campfire compatibility patches are loaded:",
        "- TEH Point Campfire Compatibility Patch",
        "- TEH Antistasi Ultimate - Point Campfire Public Test Compatibility"
    ];
};

// Stable and Public Test Point Campfire versions are mutually exclusive.
if ("3692487262" in _loadedWorkshopIDs && {"3558334679" in _loadedWorkshopIDs}) then {
    _conflicts pushBack [
        "Both stable and Public Test versions of Point Campfire are loaded:",
        "- A3UE - Point Campfire",
        "- A3UE - Point Campfire - Public Test"
    ];
};

if !(_conflicts isEqualTo []) then {
    private _messageParts = ["Incompatible mods detected."];

    {
        private _conflictLines = _x;
        _messageParts pushBack lineBreak;
        _messageParts pushBack lineBreak;

        {
            _messageParts pushBack _x;
            if (_forEachIndex < (count _conflictLines) - 1) then {
                _messageParts pushBack lineBreak;
            };
        } forEach _conflictLines;
    } forEach _conflicts;

    _messageParts pushBack lineBreak;
    _messageParts pushBack lineBreak;
    _messageParts pushBack "Disable one mod from each conflicting group and restart Arma 3.";

    [composeText _messageParts, "Incompatible mods detected", true, false] spawn BIS_fnc_guiMessage;
};

//----------------------
// Infantry loot actions
//----------------------

private _unloadToBox = [
	"LootVehicleTransferAction", "Pack to the box", "a3\ui_f\data\IGUI\Cfg\Actions\unloadVehicle_ca.paa",
	{
		params ["_target", "_player"];
		
		private _pos = getPosATL _target;
		private _box = createVehicle ["VirtualReammoBox_small_F", [_pos select 0, _pos select 1, (_pos select 2) + 1], [], 0, "CAN_COLLIDE"];
		
		systemChat "LootVehicle: Scavenging the surroundings";
		
		//first dropped weapons, as they are erased with the body otherwise
		private _holders =  nearestObjects[_target,["WeaponHolderSimulated"], 5];
		//then everything else
		private _containerList = (nearestObjects[_target,["CAManBase","WeaponHolder"], 3] select {!alive _x || !(_x isKindOf "CAManBase")});
		private _loots = _holders + _containerList;
		private _ignoreIntel = true;
		[_box,_loots,_player, _ignoreIntel] spawn loot_vehicle_fnc_transferToVehicle;
		_player setCaptive false;
	},
	{
		params ["_target", "_player"];
		!alive _target;
	},
	{}
] call ace_interact_menu_fnc_createAction;


private _selectAILoadout = [
    "TEH_SelectAILoadout",
    "Select AI loadout",
    "\A3\Ui_f\data\GUI\Rsc\RscDisplayArsenal\uniform_ca.paa",
    {
        // Root action has no direct effect. Children are generated dynamically.
    },
    {
        params ["_target", "_player"];

        alive _target
        && {!isPlayer _target}
        && {!isNull boxX}
        && {_target distance boxX < 50}
    },
    {
        params ["_target", "_player", "_params"];

        private _children = [];
        private _prefix = "AI ";
        private _prefixLower = toLower _prefix;
        private _prefixLength = count _prefix;

        private _loadoutData = profileNamespace getVariable ["bis_fnc_saveInventory_data", []];

        for "_i" from 0 to ((count _loadoutData) - 2) step 2 do {
            private _templateName = _loadoutData select _i;
            private _loadoutBlob = _loadoutData select (_i + 1);

            if !(_templateName isEqualType "") then {
                continue;
            };

            if !(_loadoutBlob isEqualType []) then {
                continue;
            };

            if !((toLower _templateName) find _prefixLower == 0) then {
                continue;
            };

            private _displayName = _templateName select [_prefixLength];
            if (_displayName isEqualTo "") then {
                _displayName = _templateName;
            };

            private _childAction = [
                format ["TEH_SelectAILoadout_%1", _i],
                _displayName,
                "\A3\Ui_f\data\GUI\Rsc\RscDisplayArsenal\uniform_ca.paa",
                {
                    params ["_target", "_player", "_params"];
                    _params params ["_templateName", "_loadoutBlob"];

                    if (isNull _target || {!alive _target} || {!(side _target == teamPlayer)}) exitWith {
                        ["Loadout", "Invalid target"] call A3A_fnc_customHint;
                    };

                    if (isPlayer _target) exitWith {
                        ["Loadout", "Cannot apply AI loadout to a player"] call A3A_fnc_customHint;
                    };

                    if (isNull boxX || {_target distance boxX >= 50}) exitWith {
                        ["Loadout", "Bring the unit closer to the arsenal box"] call A3A_fnc_customHint;
                    };

                    /*
                        Expected new JNA-compatible signature:
                        [_templateOrBlob, _targetUnit, _caller] call JN_fnc_arsenal_loadInventory;

                        _templateOrBlob:
                            STRING - old behavior, resolve from profileNamespace, apply to player by default
                            ARRAY  - new behavior, already resolved loadout blob

                        _targetUnit:
                            unit receiving the loadout

                        _caller:
                            player who requested the action, for hints / arsenal accounting context
                    */
                    [_templateName, _target, _player, _loadoutBlob] call JN_fnc_arsenal_loadInventory;
                },
                {
                    params ["_target", "_player"];

                    alive _target
                    && {!isPlayer _target}
                    && {!isNull boxX}
                    && {_target distance boxX < 50}
                },
                {},
                [_templateName, _loadoutBlob]
            ] call ace_interact_menu_fnc_createAction;

            _children pushBack [_childAction, [], _target];
        };

        if (_children isEqualTo []) then {
            private _noLoadoutsAction = [
                "TEH_SelectAILoadout_None",
                "No AI loadouts found",
                "\A3\Ui_f\data\GUI\Rsc\RscDisplayArsenal\uniform_ca.paa",
                {
                    ["Loadout", "Save a loadout with the 'AI ' prefix first"] call A3A_fnc_customHint;
                },
                {true},
                {},
                []
            ] call ace_interact_menu_fnc_createAction;

            _children pushBack [_noLoadoutsAction, [], _target];
        };

        _children
    }
] call ace_interact_menu_fnc_createAction;


//------------------------
// Vehicle utility actions
//------------------------

private _attachFlag = [
	"TEH_attachFlag", "Change flag", "\A3\ui_f\data\igui\cfg\actions\takeflag_ca.paa",
	{
		params ["_target", "_player"];
		private _logic = "Logic" createVehicleLocal [0, 0, 0];
		_logic attachTo [_target, [0, 0, 0]];

		[_logic] call zen_modules_fnc_moduleAttachFlag;
	},
	{
		params ["_target", "_player"];

        alive _target
	},
	{}
] call ace_interact_menu_fnc_createAction;

private _quickResupplyAction = [
    "TEH_QuickResupply",
    "Quick resupply",
    "\A3\Ui_f\data\IGUI\Cfg\Actions\reload_ca.paa",
    {},
    {
        params ["_target", "_player"];

        alive _target && (_target getVariable ["originalSide", sideUnknown] == teamPlayer)
        && {getNumber (configOf _target >> "ace_rearm_defaultSupply") > 0}
    },
    {
        params ["_target", "_player"];

        private _statement = {
            params ["_target", "_player", "_resupplyTarget"];

            [_resupplyTarget] call JN_fnc_arsenal_quickReload;
        };

        private _vehicles = (
            nearestObjects [
                _target,
                ["LandVehicle", "Air", "Ship"],
                LootVehicleDistance
            ]
        ) select { alive _x };

        // Player is always first.
        private _resupplyTargets = [_player];
		// Ammo truck is always last.
		_vehicles = _vehicles - [_target];
		_vehicles pushBack _target;

        _resupplyTargets append _vehicles;

        [
            _resupplyTargets,
            _statement,
            _target
        ] call ace_interact_menu_fnc_createVehiclesActions;
    }
] call ace_interact_menu_fnc_createAction;

private _storeLootSellVehicle = [
	"LootVehicleSellAction", "Sell Vehicle", "",
	{
		params ["_target", "_player"];
		if ([getPosATL _player] call A3A_fnc_enemyNearCheck) exitWith {
			["Sell Vehicle", "Can't sell this vehicle when there are enemies nearby"] call SCRT_fnc_misc_deniedHint;};
		[_player,_target] spawn A3A_fnc_sellVehicle;
	},
	{
		params ["_target", "_player"];
		count crew _target == 0;
	},
	{}
] call ace_interact_menu_fnc_createAction;

//---------------------
// Vehicle loot actions
//---------------------

private _transferBetweenAction = [
	"LootVehicleTransferAction", "Unload Cargo", "a3\ui_f\data\IGUI\Cfg\Actions\unloadVehicle_ca.paa",
	{
		params ["_target", "_player"];
		
		(nearestObjects [_player, ace_cargo_cargoHolderTypes, LootVehicleDistance]) select {
			(_x != _target) && {([_target, _x] call ace_interaction_fnc_getInteractionDistance) < LootVehicleDistance}
		} params [["_nearestVehicle", objNull]];
		
		if (isNull _nearestVehicle) then {
			systemChat "LootVehicle: Error: couldn't find any nearby vehicle";
		} else {
			systemChat "LootVehicle: Using nearest vehicle";
			[_nearestVehicle,[_target],_player, false] spawn loot_vehicle_fnc_transferToVehicle;
		};
	},
	{
		count ((nearestObjects [_target, ace_cargo_cargoHolderTypes, LootVehicleDistance]) select {
			(_x != _target) && {([_target, _x] call ace_interaction_fnc_getInteractionDistance) < LootVehicleDistance}
		}) > 0;
	},
	{
		private _statement = {
			params ["_target", "_player", "_vehicle"];
			[_vehicle,[_target],_player, false] call loot_vehicle_fnc_transferToVehicle;
		};
		
		private _vehicles = (nearestObjects [_target, ["landVehicle","air","ship"], LootVehicleDistance]) select {
			(_x != _target) && {([_target, _x] call ace_interaction_fnc_getInteractionDistance) < LootVehicleDistance} && (getNumber(configFile >> "CfgVehicles" >> typeOf _x >> "transportMaxBackpacks") + getNumber(configFile >> "CfgVehicles" >> typeOf _x >> "transportMaxMagazines") + getNumber(configFile >> "CfgVehicles" >> typeOf _x >> "transportMaxWeapons") != 0)
		};

		[_vehicles, _statement, _target] call ace_interact_menu_fnc_createVehiclesActions;
	}
] call ace_interact_menu_fnc_createAction;

private _actionVehicle = [
	"LootVehicleGatherAllLoot", "Gather all loot", "a3\ui_f\data\IGUI\Cfg\Actions\loadVehicle_ca.paa",
	{
		params ["_target", "_player"];
		private _dist = 5000;
		private _leads = [];
		{
			if ((side _x == Occupants || side _x == Invaders) && side leader _x == side _x) then {
				_leads pushBack leader _x;
			};
		} forEach allGroups;
		
		if (count _leads > 0) then {
			private _toL = [_leads,_target] call BIS_fnc_nearestPosition;
			private _calc = floor (_target distance2D _toL) - 50;
			_dist = _dist min (_calc max 5);
		};
		
		systemChat format["LootVehicle: Sending troops to gather loot in %1 m area",_dist];
		_player setCaptive false;
		
		//first dropped weapons, as they are erased with the body otherwise
		private _holders =  nearestObjects[_target,["WeaponHolderSimulated"],_dist, false];
		//then everything else
		private _containerList = (nearestObjects[_target,["CAManBase","WeaponHolder",(A3A_faction_occ get "surrenderCrate"),(A3A_faction_inv get "surrenderCrate"),(A3A_faction_riv get "surrenderCrate"),"VirtualReammoBox_small_F"],_dist, false] select {!alive _x || !(_x isKindOf "CAManBase")});
		private _loots = _holders + _containerList;
		if (count _loots > 0) then {
			[_target,_loots,_player, false] spawn loot_vehicle_fnc_transferToVehicle;
		} else {
			systemChat "LootVehicle: Nothing to gather.";
		};
	},
	{
		true;
	},
	{}] call ace_interact_menu_fnc_createAction;

//--------------------
// Action registration
//--------------------

["CAManBase", 0, ["ACE_MainActions"], _unloadToBox, true] call ace_interact_menu_fnc_addActionToClass;

// "SoldierGB" - green side men.
["SoldierGB", 0, ["ACE_MainActions"], _selectAILoadout, true] call ace_interact_menu_fnc_addActionToClass;

{
	if (TEH_VehicleFlags) then {
		[_x, 0, ["ACE_MainActions"], _attachFlag, true] call ace_interact_menu_fnc_addActionToClass;
	};
	
	[_x, 0, ["ACE_MainActions"], _quickResupplyAction, true] call ace_interact_menu_fnc_addActionToClass;
	[_x, 0, ["ACE_MainActions"], _transferBetweenAction, true] call ace_interact_menu_fnc_addActionToClass;
	[_x, 0, ["ACE_MainActions"], _storeLootSellVehicle, true] call ace_interact_menu_fnc_addActionToClass;
	[_x, 0, ["ACE_MainActions"], _actionVehicle, true] call ace_interact_menu_fnc_addActionToClass;

} forEach ["landVehicle","air","ship"];

["ReammoBox_F", 0, ["ACE_MainActions"], _actionVehicle, true] call ace_interact_menu_fnc_addActionToClass;
["B_CargoNet_01_ammo_F", 0, ["ACE_MainActions"], _transferBetweenAction, true] call ace_interact_menu_fnc_addActionToClass;

