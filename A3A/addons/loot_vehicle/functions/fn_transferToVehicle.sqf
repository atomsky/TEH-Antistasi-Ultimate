params ["_targetVehicle", "_containerList", "_player", "_ignoreIntel"];

private _total = count _containerList;
systemChat format ["LootVehicle: Moving from %1 containers to %2", _total, getText (configFile >> "CfgVehicles" >> typeOf _targetVehicle >> "displayname")];

private _processNext = {
	params ["_state", "_processNext"];
	_state params ["_targetVehicle", "_containerList", "_player", "_ignoreIntel", "_total", "_nextIndex"];

	if (isNull _targetVehicle) exitWith {
		systemChat "LootVehicle: Gathering is interrupted";
	};

	private _container = objNull;
	private _current = 0;
	private _timer = 0;

	// Find and lock the next valid container. Invalid, already claimed and empty
	// containers are handled synchronously so the progress-bar chain never recurses
	// through a long run of skipped entries.
	while {_nextIndex < _total && {isNull _container}} do {
		private _candidate = _containerList # _nextIndex;
		_current = _nextIndex + 1;
		_nextIndex = _nextIndex + 1;

		if (isNull _candidate) then { continue; };
		if ((_candidate getVariable ["LV_isLooted", false]) || {_candidate isEqualTo _targetVehicle}) then { continue; };

		if ((_candidate getVariable ["hasIntel", false]) && {!_ignoreIntel}) then {
			// Not in the water or below ground
			private _depth = floor ((getPosATL _candidate) # 2 * 100) / 100;
			if (!surfaceIsWater position _candidate && {_depth > -2}) then {
				systemChat format ["LootVehicle: Intel discovered! (%1m ATL)", _depth];
				[_candidate] spawn {
					params ["_intel"];
					private _mrk = createMarkerLocal [str (random 9999), getPosATL _intel];
					_mrk setMarkerTypeLocal "hd_dot_noShadow";
					_mrk setMarkerTextLocal "Intel";
					_mrk setMarkerColor "ColorGreen";
					sleep 120;
					deleteMarker _mrk;
				};
				continue;
			};
		};

		// Claim this source so another player skips it while we are looting it.
		_candidate setVariable ["LV_isLooted", true, true];

		// Count weight / determine looting time.
		private _deleteEmpty = false;
		_timer = if (_candidate isKindOf "ReammoBox_F" && !(_candidate isKindOf "B_CargoNet_01_ammo_F")) then {
			1
		} else {
			private _weight = loadAbs _candidate;

			if (_weight == 0 && {!(_candidate isKindOf "Car") && !(_candidate isKindOf "B_CargoNet_01_ammo_F")}) then {
				_deleteEmpty = true;
				0
			} else {
				private _rawTime = ceil ((_weight * LootVehicleSpeed) / 100);

				if (_rawTime <= 60) then {
					_rawTime
				} else {
					private _delta = _rawTime - 60;
					ceil (60 + 120 * _delta / (_delta + 120))
				};
			};
		};

		// Empty non-vehicle containers are deleted immediately; continue scanning
		// without calling _processNext recursively. A valid source with a zero-second
		// timer is still processed normally.
		if (_deleteEmpty) then {
			deleteVehicle _candidate;
		} else {
			_container = _candidate;
		};
	};

	if (isNull _container) exitWith {
		systemChat "LootVehicle: Done";
	};

	[
		_timer,
		[_targetVehicle, _container, _player, _containerList, _ignoreIntel, _total, _nextIndex, _processNext],
		{
			params ["_args"];
			_args params ["_vehicle", "_container", "_player", "_containerList", "_ignoreIntel", "_total", "_nextIndex", "_processNext"];

			// The source may have disappeared while the progress bar was running.
			// It is simply skipped and the queue continues.
			if (isNull _container) exitWith {
				[[_vehicle, _containerList, _player, _ignoreIntel, _total, _nextIndex], _processNext] call _processNext;
			};

			// If the target is gone, release the current source and cancel the queue.
			if (isNull _vehicle) exitWith {
				_container setVariable ["LV_isLooted", false, true];
				systemChat "LootVehicle: RIP";
				systemChat "LootVehicle: Gathering is interrupted";
			};

			private _items = [];
			private _backpacks = [];
			private _ammo = [];

			// Write down all items.
			if (_container isKindOf "CAManBase") then {
				if (primaryWeapon _container != "") then {
					_items append (_container weaponAccessories primaryWeapon _container);
					_items pushBack ((primaryWeapon _container) call BIS_fnc_baseWeapon);
				};
				if (secondaryWeapon _container != "") then {
					_items append (_container weaponAccessories secondaryWeapon _container);
					_items pushBack ((secondaryWeapon _container) call BIS_fnc_baseWeapon);
					_items pushBack (secondaryWeapon _container);
				};
				if (handgunWeapon _container != "") then {
					_items append (_container weaponAccessories handgunWeapon _container);
					_items pushBack ((handgunWeapon _container) call BIS_fnc_baseWeapon);
				};
				_items append assignedItems [_container, true, true];

				_backpacks pushBack ((backpack _container) call BIS_fnc_basicBackpack);
				_items pushBack uniform _container;
				_items pushBack vest _container;
				{
					private _cont = _x;
					_ammo append magazinesAmmoCargo _cont;
					_items append itemCargo _cont;
					{
						_items pushBack (_x call BIS_fnc_baseWeapon);
					} forEach weaponCargo _cont;
					{
						_items append (_x select [1, 3]);
						if (_x select 4 isNotEqualTo []) then {
							_ammo pushBack (_x select 4);
						};
						if (_x select 5 isNotEqualTo []) then {
							_items pushBack (_x select 5 select 0);
						};
						_items pushBack (_x select 6);
					} forEach weaponsItemsCargo _cont;
					{
						_backpacks pushBack (_x call BIS_fnc_basicBackpack);
					} forEach backpackCargo _cont;
				} forEach [
					uniformContainer _container,
					backpackContainer _container,
					vestContainer _container
				];
			} else {
				_ammo append magazinesAmmoCargo _container;
				_items append itemCargo _container;
				{
					private _weap = _x call BIS_fnc_baseWeapon;
					_items pushBack _weap;
				} forEach weaponCargo _container;
				{
					_items append (_x select [1, 3]);
					if (_x select 4 isNotEqualTo []) then {
						_ammo pushBack (_x select 4);
					};
					if (_x select 5 isNotEqualTo []) then {
						_items pushBack (_x select 5 select 0);
					};
					_items pushBack (_x select 6);
				} forEach weaponsItemsCargo _container;
				{
					_backpacks pushBack (_x call BIS_fnc_basicBackpack);
				} forEach backpackCargo _container;
				{
					_items append itemCargo (_x select 1);
					_ammo append magazinesAmmoCargo (_x select 1);
					{
						_items pushBack (_x call BIS_fnc_baseWeapon);
					} forEach weaponCargo (_x select 1);
					{
						_items append (_x select [1, 3]);
						if (_x select 4 isNotEqualTo []) then {
							_ammo pushBack (_x select 4);
						};
						if (_x select 5 isNotEqualTo []) then {
							_items pushBack (_x select 5 select 0);
						};
						_items pushBack (_x select 6);
					} forEach weaponsItemsCargo (_x select 1);
					{
						_backpacks pushBack (_x call BIS_fnc_basicBackpack);
					} forEach backpackCargo (_x select 1);
				} forEach everyContainer _container;
			};

			// Filter empty items out to reduce write time.
			_items = _items select {_x != ""};

			// Wait asynchronously for another local looter to finish writing to the
			// target vehicle. CBA executes the statement in unscheduled environment,
			// so no sleep/waitUntil is needed here.
			[
				{
					params ["_vehicle", "_container"];
					isNull _vehicle || {isNull _container} || {!(_vehicle getVariable ["LV_lootWrite", false])}
				},
				{
					params ["_vehicle", "_container", "_player", "_containerList", "_ignoreIntel", "_total", "_nextIndex", "_processNext", "_items", "_backpacks", "_ammo"];

					if (isNull _vehicle) exitWith {
						if (!isNull _container) then {
							_container setVariable ["LV_isLooted", false, true];
						};
						systemChat "LootVehicle: Gathering is interrupted";
					};

					// If somebody/something removed this source while we were waiting for
					// the target write-lock, discard the cached snapshot instead of duplicating it.
					if (isNull _container) exitWith {
						[[_vehicle, _containerList, _player, _ignoreIntel, _total, _nextIndex], _processNext] call _processNext;
					};

					// Lock target cargo writes.
					_vehicle setVariable ["LV_lootWrite", true, true];

					// Actually move loot.
					{
						_vehicle addItemCargoGlobal [_x, 1];
					} forEach _items;
					{
						_vehicle addBackpackCargoGlobal [_x, 1];
					} forEach _backpacks;
					{
						_vehicle addMagazineAmmoCargo [_x # 0, 1, _x # 1];
					} forEach _ammo;

					// Unlock target cargo writes.
					_vehicle setVariable ["LV_lootWrite", false, true];

					// The source might have been removed by some unrelated system while
					// waiting for the target write-lock. In that case there is nothing to
					// clean up; just continue the queue.
					if (!isNull _container) then {
						if (_container isKindOf "ReammoBox_F" || {_container isKindOf "CAManBase"}) then {
							if (1000 > random 100000) then {
								private _cside = _container getVariable ["originalside", sideUnknown];
								[_cside, _player, _vehicle] spawn loot_vehicle_fnc_looterAmbush;
							};
							deleteVehicle _container;
						} else {
							clearItemCargoGlobal _container;
							clearMagazineCargoGlobal _container;
							clearWeaponCargoGlobal _container;
							clearBackpackCargoGlobal _container;
							_container setVariable ["LV_isLooted", false, true];
						};
					};

					// Start exactly one next progress bar. The previous bar and this
					// write operation have both fully completed before the queue advances.
					[[_vehicle, _containerList, _player, _ignoreIntel, _total, _nextIndex], _processNext] call _processNext;
				},
				[_vehicle, _container, _player, _containerList, _ignoreIntel, _total, _nextIndex, _processNext, _items, _backpacks, _ammo]
			] call CBA_fnc_waitUntilAndExecute;
		},
		{
			params ["_args", "_elapsedTime", "_totalTime", "_errorCode"];
			_args params ["_vehicle", "_container"];

			// Any progress-bar failure, including Escape, cancels the rest of the
			// queue. Release the current source so another player may loot it.
			if (!isNull _container) then {
				_container setVariable ["LV_isLooted", false, true];
			};
			systemChat format ["LootVehicle: Gathering is interrupted at %1s. Error code: %2", _elapsedTime, _errorCode];
		},
		format ["(%1/%2) Looting %3...", _current, _total, getText (configFile >> "CfgVehicles" >> typeOf _container >> "displayname")],
		_player
	] call teh_actions_fnc_progressBar;
};

[[_targetVehicle, _containerList, _player, _ignoreIntel, _total, 0], _processNext] call _processNext;
