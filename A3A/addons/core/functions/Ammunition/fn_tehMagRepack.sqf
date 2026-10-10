params ["_unit"];

//arma is weird
private _isBelt = {
	(getText (configFile >> "CfgMagazines" >> _this >> "nameSound") == "mgun");
};

// Primary mag class (first element)
private _pwMags = primaryWeaponMagazine _unit;
if (count _pwMags == 0) exitWith {systemChat "TEH: Can't process, your primary weapon is unloaded.";};
//forEach mag - for double ammo guns, like type115
{
	//store primary mag info
	private _primaryMag = _x;
	private _primaryCap = getNumber (configFile >> "CfgMagazines" >> _primaryMag >> "count");
	private _primaryAmmo = getText (configFile >> "CfgMagazines" >> _primaryMag >> "ammo");
	private _primaryName = getText (configFile >> "CfgMagazines" >> _primaryMag >> "displayName");
	private _primaryBelt = _primaryMag call _isBelt;

	//check if we can work with primary ammo
	private _tool = (("ACE_DefusalKit" in (itemCargo player)) or ("ToolKit" in (itemCargo player)));
	if (_primaryBelt and !_tool) exitWith {systemChat "TEH: A Defusal Kit or a Toolkit in needed to link or unlink ammo belts";};
	if (_primaryCap == 1) exitWith { systemChat format["TEH: %1 is a single shell, no need to repack.",_primaryName]; };
	// Main loop: try to fill targets until done or cannot progress
	private _stopFlag = false;
	private _exitBreak = 0;
	private _warningBelt = false;
	private _warningMagToBelt = false;

	while { !_stopFlag } do {
		_exitBreak = _exitBreak + 1;

		// all unloaded mags (we only consider unloaded mags to avoid touching currently loaded mags)
		private _allMags = (magazinesAmmoCargo uniformContainer _unit) + (magazinesAmmoCargo vestContainer _unit) + (magazinesAmmoCargo backpackContainer _unit);

		private _targets = []; // mags of same class that are not full (we want to fill these)
		private _sources = []; // mags of other classes with the same ammo we can draw from

		{
			private _cls = _x select 0;
			private _cnt = _x select 1;

			if (_cls == _primaryMag) then {
				if (_cnt < _primaryCap) then {
					_targets pushBack _x;
				};
			} else {
				private _ammoS = getText (configFile >> "CfgMagazines" >> _cls >> "ammo");
				private _sourceBelt = _cls call _isBelt;
				_warningBelt = (_warningBelt or _sourceBelt);
				_warningMagToBelt = (_warningMagToBelt or (_primaryBelt && !_sourceBelt));
				//add source if 1)compatible ammo, 2) not a belt or there is a tool, 3) primary is not a belt or both are belts.
				if (_ammoS == _primaryAmmo && _cnt > 0 && (!_sourceBelt || _tool) && (!_primaryBelt || _sourceBelt)) then {
					_sources pushBack _x;
				};
			};
		} forEach _allMags;

		//check findings
		if (_warningBelt and !_tool and _exitBreak == 1) then {systemChat "TEH: A Defusal Kit or a Toolkit in needed to link or unlink ammo belts";};
		if (_warningMagToBelt and _exitBreak == 1) then {systemChat format ["TEH: Only belts can be linked to the %1, not magazines",_primaryName];};
		if (count _sources == 0) then { _targets = _targets select {_x#1 > 0};};
		if (count _targets == 0) exitWith { systemChat format ["TEH: All the %1 are reloaded",_primaryName]; };
		if (count _targets == 1 && count _sources == 0) exitWith { systemChat format ["TEH: Not enough ammo to reload the %1",_primaryName]; };

		_targets = [_targets, [], {_x#1}, "DESCEND"] call BIS_fnc_sortBy;
		_sources = [_sources, [], {_x#1}, "ASCEND"] call BIS_fnc_sortBy;

		private _cycletarget = _targets select 0;
		private _targetClass = _cycletarget select 0;
		private _targetCount = _cycletarget select 1;
		private ["_cyclesource", "_sourceClass", "_sourceCount"];

		if (count _sources > 0) then {
			_cyclesource = (_sources select 0);
		} else {
			_cyclesource = _targets select -1;
		};

		_sourceClass = (_cyclesource select 0);
		_sourceCount = (_cyclesource select 1);
		
		// compute transfer delta (can't exceed sourceCount or the target's missing capacity)
		private _missing = _primaryCap - _targetCount;
		private _delta = _missing min _sourceCount;
		
		private _duration = _delta * 1.5;
		if (_primaryBelt && _sourceClass call _isBelt) then {
			_duration = 3;
		};
		// Run a progress bar for transfer time: delta * 1.5 (as requested)

		_unit setVariable ["TehRepack",1];
		// On completion: actually modify the two magazine instances safely
		[
			format ["Adding %1 bullets from %2 to %3",_delta,getText (configFile >> "CfgMagazines" >> _sourceClass >> "displayName"),getText (configFile >> "CfgMagazines" >> _targetClass >> "displayName")],
			_duration,
			{
				params ["_args"];
				private _unit = _args select 5;
				_unit isEqualTo player && {alive _unit} && {lifeState _unit isNotEqualTo "INCAPACITATED"} && {isNull objectParent _unit}
			},
			{
				params ["_args"];
				private ["_tClass","_tOrig","_sClass","_sOrig","_d","_unit"];
				_tClass = _args select 0;
				_tOrig   = _args select 1;
				_sClass  = _args select 2;
				_sOrig   = _args select 3;
				_d       = _args select 4;
				_unit	   = _args select 5;

				// Reduce source instance by _d (may become 0)
				private _sNew = _sOrig - _d;
				[_unit, _sClass, _sOrig, _sNew] call A3A_fnc_tehMagRemove;

				// Increase target instance by _d
				private _tNew = _tOrig + _d;
				[_unit, _tClass, _tOrig, _tNew] call A3A_fnc_tehMagRemove;

				_unit setVariable ["TehRepack",0];
			},
			{
				params ["_args"];
				private _unit = _args select 5;
				_unit setVariable ["TehRepack",-1];
			},
			[ _targetClass, _targetCount, _sourceClass, _sourceCount, _delta, _unit ]
		] call CBA_fnc_progressBar;

		waitUntil { sleep 0.1;
			switch (_unit getVariable ["TehRepack",1]) do {
				case (-1): {
					_stopFlag = true;
					true;
				};
				case (0): { true };
				default { false };
			}
		};
	};
} forEach _pwMags;
