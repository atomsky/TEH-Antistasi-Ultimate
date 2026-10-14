params ["_unit","_instigator"];

private _side = _unit getVariable "originalSide";

// Only occupiers/invaders get SWAT-style response
if !(_side in [Occupants, Invaders]) exitWith {};

private _dispatch = true;
private _incidentPos = getPosATL _unit;

// Cities controlled by this side (citiesX = array of marker names)
private _policeCities = citiesX select { sidesX getVariable [_x, sideUnknown] == _side };
if (_policeCities isEqualTo []) exitWith {};

// First nearest city
private _loc = [_policeCities, _incidentPos] call BIS_fnc_nearestPosition;
private _nearestPos  = getMarkerPos _loc;

// Prevent spawn on top of players
if ((allPlayers inAreaArray [_nearestPos, 200, 200, 0, false]) isNotEqualTo []) then {
    _policeCities = _policeCities - [_loc];
    if (_policeCities isEqualTo []) exitWith {};

    _loc = [_policeCities, _incidentPos] call BIS_fnc_nearestPosition;
};

// Create SWAT group on same side as dead cop
private _grp = createGroup _side;
private _veh = objNull;
private _faction = [A3A_faction_occ, A3A_faction_inv] select (_side == Invaders);
private _swatWeaponLoadouts = [];
private _uavTypes = switch (TEH_spawnSwatDrone) do {
    case 0: { [] }; // Disable
    case 1: { _faction getOrDefault ["uavsPortable", []] }; // Faction
    case 2: { _faction getOrDefault ["uavsPortable", ["B_UAV_01_F"]] }; // Always
    default { [] };
};

if (TEH_spawnSwat == 1) then {
	// Gendarmerie secion
	private _partyVan = "B_GEN_Van_02_vehicle_F";
	private _inCharge = "B_GEN_Commander_F";
	private _policeman = "B_GEN_Soldier_F";

    private _spawnPos = (getMarkerPos _loc) findEmptyPosition [5, 40, _partyVan];
	if (_spawnPos isEqualTo []) exitWith {};
	_veh = createVehicle [_partyVan, _spawnPos, [], 0, "NONE"];

	private _skill = (0.1 * A3A_enemySkillMul) + (0.07 * (1 max A3A_activePlayerCount^0.5)) + (0.01 * tierWar);
	// Commander first → becomes leader
	private _commander = _grp createUnit [_inCharge, _spawnPos, [], 0, "NONE"];
	[_commander] call A3A_fnc_NATOinit;
	_commander setSkill _skill*1.1;

	// Group size: commander + N grunts (max 11 seats in van)
	private _gruntCount = 4 + tierWar;
	if (_gruntCount > 10) then { _gruntCount = 10; };

	for "_i" from 1 to _gruntCount do {
		private _u = _grp createUnit [_policeman, _spawnPos, [], 0, "NONE"];

		// Override headgear
		removeHeadgear _u;
		_u addHeadgear "H_PASGT_basic_blue_F";
		[_u] call A3A_fnc_NATOinit;
		_u setSkill _skill*1.05;
	};
};

if (TEH_spawnSwat == 2) then {
    _swatWeaponLoadouts = _faction getOrDefault ["TEH_swatWeaponLoadouts", []];
	private _partyVan = selectRandom (_faction get "vehiclesPolice");
	private _spawnPos = (getMarkerPos _loc) findEmptyPosition [5, 40, _partyVan];
	if (_spawnPos isEqualTo []) exitWith {};
	_veh = createVehicle [_partyVan, _spawnPos, [], 0, "NONE"];

	private _typeCargoGroup = [_partyVan, _side] call A3A_fnc_cargoSeats;
	_grp = [_spawnPos, _side, _typeCargoGroup, true, false] call A3A_fnc_spawnGroup;

	private _swatHelmets = _faction getOrDefault [
		"TEH_swatHelmets",
		["H_PASGT_basic_blue_F"]
	];

	private _swatVests = _faction getOrDefault [
		"TEH_swatVests",
		["V_TacVest_gen_F"]
	];

	{
		private _unitToChange = _x;

		removeHeadgear _unitToChange;
		if (_swatHelmets isNotEqualTo []) then {
			_unitToChange addHeadgear selectRandom _swatHelmets;
		};

		private _vestItems = vestItems _unitToChange;
		removeVest _unitToChange;
		_unitToChange addVest selectRandom _swatVests;

		{
			_x params ["_item", "_count"];

			for "_i" from 1 to _count do {
				_unitToChange addItemToVest _item;
			};
		} forEach (_vestItems call BIS_fnc_consolidateArray);
	} forEach (units _grp);
};

// Ground personnel only. UAV virtual pilots join _grp later, but must never
// affect SWAT casualty checks, disembark orders or van re-boarding.
private _policeUnits = + (units _grp);
if (isNull _veh || {_policeUnits isEqualTo []}) exitWith {
    if (!isNull _veh) then { deleteVehicle _veh; };
    if (!isNull _grp) then { deleteGroup _grp; };
};
private _commander = leader _grp;
private _medicCandidates = _policeUnits - [_commander];
private _medic = _medicCandidates param [0, objNull];

// Preserve the faction's ordinary police weapon for commander and medic.
if (!isNull _medic) then {
    _medic setUnitTrait ["Medic", true];
    if (!("Medikit" in (items _medic)) && {_medic canAdd "Medikit"}) then {
        _medic addItem "Medikit";
    };
};

// Faction SWAT: 50% roll for each ordinary rifleman to receive a template
// weapon. Template format: [weapon, muzzle, rail, optic, magazines, GL mags, bipod].
// Commander and medic are never converted to specialists.
if (TEH_spawnSwat == 2 && {_swatWeaponLoadouts isNotEqualTo []}) then {
    {
        private _soldier = _x;
        if (_soldier != _commander && {_soldier != _medic} && {random 1 < 0.5}) then {
            private _loadout = selectRandom _swatWeaponLoadouts;
            private _weapon = _loadout # 0;

            private _oldWeapon = primaryWeapon _soldier;
            if (_oldWeapon != "") then {
                { _soldier removeMagazines _x } forEach compatibleMagazines [_oldWeapon, "this"];
                _soldier removeWeapon _oldWeapon;
            };

            _soldier addWeapon _weapon;
            {
                if (_x != "") then {
                    _soldier addWeaponItem [_weapon, _x, true];
                };
            } forEach [_loadout # 1, _loadout # 2, _loadout # 3, _loadout # 6];

            private _magazines = _loadout # 4;
            if (_magazines isNotEqualTo []) then {
                _soldier addWeaponItem [_weapon, _magazines # 0, true];
                { _soldier addMagazine _x } forEach (_magazines select [1]);
            };
        };
    } forEach _policeUnits;
};

{
	_x setVariable ["TEH_ArtilleryDisabled",true,false];
} forEach _policeUnits;

_veh setVariable ["TEH_Swat",true,true];
_veh setVariable ["originalSide", _side];

//Hardcore bonus
if !(_instigator getVariable["TEH_Rebel",true]) then {
	private _newWeapon = (selectRandom (((A3A_faction_occ get "loadouts") get "SF_Rifleman") # 0)) # 0; 
	private _magazines = _newWeapon # 4 # 0;
    private _quantity = 1;

    clearWeaponCargoGlobal _veh;
    clearMagazineCargoGlobal _veh;
    clearItemCargoGlobal _veh;
    clearBackpackCargoGlobal _veh;

    _veh addWeaponCargoGlobal [_newWeapon # 0, _quantity];
    _veh addItemCargoGlobal [_newWeapon # 1, _quantity];
    _veh addItemCargoGlobal [_newWeapon # 2, _quantity];
    _veh addItemCargoGlobal [_newWeapon # 3, _quantity];

    _veh addMagazineCargoGlobal [_magazines, 3 + random 3];
};

// Initial group behaviour while mounted
_grp setCombatMode "YELLOW";      // will shoot if threatened
_grp setBehaviour "AWARE";
_grp setSpeedMode "FULL";
_grp setFormation "COLUMN";

// Load ground personnel into the van
{ _x moveInAny _veh } forEach _policeUnits;

// Turn on emergency lights (if supported)
_veh animateSource ["lights_em_hide", 1];
[_veh,'CustomSoundController1',1,0.2] remoteExec ['BIS_fnc_setCustomSoundController', 0, ['CustomSoundController1', netID this] joinString ':'];

["TaskSucceeded", ["", format [localize "STR_notifiers_vehicle_spotted","SWAT"]]] spawn BIS_fnc_showNotification;

// Waypoint: drive to crime scene
private _wp = _grp addWaypoint [_incidentPos, 0];
_wp setWaypointType "MOVE";
_wp setWaypointBehaviour "AWARE";
_wp setWaypointSpeed "FULL";
_wp setWaypointCombatMode "YELLOW";
_wp setWaypointFormation "COLUMN";

// Spawn behaviour thread: disembark, search, then RTB
[_grp, _veh, _incidentPos, _instigator, _policeUnits, _commander, _side, _uavTypes] spawn {
    params ["_grp", "_veh", "_incidentPos", "_instigator", "_policeUnits", "_commander", "_side", "_uavTypes"];

    private _uav = objNull;
    private _uavCrew = [];
    private _fnc_cleanupUAV = {
        params ["_uav", "_uavCrew"];
        if (!isNull _uav) then {
            deleteVehicleCrew _uav;
            deleteVehicle _uav;
        };
        // Also catch crew members no longer seated in the UAV.
        { if (!isNull _x) then { deleteVehicle _x; }; } forEach _uavCrew;
    };

	// === Phase 1: arrive and disembark near the scene ===
	waitUntil {
		sleep 1;
		({ alive _x } count _policeUnits == 0)
		|| { !alive _veh }
		|| { !canMove _veh }
		|| { (leader _grp distance2D _incidentPos) < 60 }
	};

	// Everyone dead → nothing more to do
	if ({ alive _x } count _policeUnits == 0) exitWith {};

	// Force disembark
	{
		if (alive _x) then {
			unassignVehicle _x;
			[_x] orderGetIn false;
			doGetOut _x;
		};
	} forEach _policeUnits;

	//turn off sirens
	[_veh, 'CustomSoundController1',0,0.4] remoteExec ['BIS_fnc_setCustomSoundController', 0, ['CustomSoundController1', netID this] joinString ':'];

    // Deploy the faction's portable reconnaissance UAV at the usual disembark.
    // Its virtual crew joins the SWAT group to share contact information.
    if (_uavTypes isNotEqualTo []) then {
        private _uavClass = selectRandom _uavTypes;
        if (isClass (configFile >> "CfgVehicles" >> _uavClass)) then {
            _uav = createVehicle [_uavClass, getPosATL _veh, [], 0, "FLY"];
            if (!isNull _uav) then {
                [_side, _uav] call A3A_fnc_createVehicleCrew;
                _uavCrew = crew _uav;
                if (_uavCrew isNotEqualTo []) then {
                    private _uavGroup = group (_uavCrew # 0);
                    {
                        _x setVariable ["TEH_ArtilleryDisabled", true, false];
                        [_x] joinSilent _grp;
                    } forEach _uavCrew;
                    if (!isNull _uavGroup && {_uavGroup != _grp}) then {
                        deleteGroup _uavGroup;
                    };
                    if (alive _commander) then {
                        _grp selectLeader _commander;
                    } else {
                        private _groundLeader = (_policeUnits select {alive _x}) param [0, objNull];
                        if (!isNull _groundLeader) then { _grp selectLeader _groundLeader; };
                    };
                } else {
                    // No AI crew = no reconnaissance; do not leave an idle UAV.
                    deleteVehicle _uav;
                    _uav = objNull;
                };
            };
        };
    };

	// Aggressive posture on foot
	_grp setCombatMode "RED";
	_grp setBehaviour "AWARE";
	_grp setSpeedMode "FULL";
	_grp setFormation "LINE";

	// Clear old waypoints (drive-to)
	while {count waypoints _grp > 0} do {
		deleteWaypoint [_grp, 0];
	};

	// Choose search position: instigator if valid, else incident pos
	private _searchPos =
		if (!isNull _instigator && {alive _instigator}) then {
			getPosWorld _instigator
		} else {
			_incidentPos
		};

	// Search-and-destroy around target area
	private _wpSearch = _grp addWaypoint [_searchPos, 10];
	_wpSearch setWaypointType "SAD";
	_wpSearch setWaypointBehaviour "AWARE";
	_wpSearch setWaypointSpeed "FULL";
	_wpSearch setWaypointCombatMode "RED";
	_wpSearch setWaypointFormation "LINE";

	// === Phase 2: monitor situation and eventually RTB ===

	private _tickLimit = diag_tickTime + 900;   // 15 min max
	private _allDead = false;

	private _post = 5 + random 10;
	waitUntil {
		sleep 20;

		_allDead = { alive _x } count _policeUnits == 0;
		if ( isNull _instigator || !alive _instigator ) then {
			_post = _post - 1; //a bit of a cooldown to see if player comes back
		};

		_allDead
		|| _post <= 0 
		|| { diag_tickTime > _tickLimit }
	};

    // Air support is over regardless of why the search ended.
    [_uav, _uavCrew] call _fnc_cleanupUAV;
    if (_allDead) exitWith {};

    private _groundLeader = (_policeUnits select {alive _x}) param [0, objNull];
    if (!isNull _groundLeader) then { _grp selectLeader _groundLeader; };

	// Done here → clear waypoints
	while {count waypoints _grp > 0} do {
		deleteWaypoint [_grp, 0];
	};

	// Try to re-use their own van if it's still usable and nearby
	if (
		!isNull _veh
		&& { _veh isKindOf "Car" }
		&& { alive _veh }
		&& { count crew _veh == 0 }
		&& { (leader _grp) distance2D _veh < 300 }
	) then {
		private _passengers = [];
		{
			if (alive _x) then {
				_x assignAsCargo _veh;
				_passengers pushBack _x;
			};
		} forEach _policeUnits;
		_passengers orderGetIn true;

		private _lead = leader _grp;
		_lead assignAsDriver _veh;
		[_lead] orderGetIn true;

		// Give them some time to mount before RTB logic kicks in
		sleep 90;
	};

	// Hand off to global RTB logic
	[_grp] spawn A3A_fnc_enemyReturnToBase;
};
