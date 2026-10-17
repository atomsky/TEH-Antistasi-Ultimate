/*
	Function: HALs_store_fnc_addActionTrader
	Author: HallyG
	Add an open store action to all targets.

	Argument(s):
	0: Trader <OBJECT>
	1: Target (Default: false) <ARRAY, GROUP, NUMBER, OBJECT, SIDE, STRING, BOOLEAN>

	Return Value:
	None

	Example:
	[trader1, west] call HALs_store_fnc_addActionTrader;
__________________________________________________________________*/
params [
	["_trader", objNull, [objNull]],
	["_target", false, [0, objNull, "", sideUnknown, grpNull, [], false]]
];

if (isNull _trader) exitWith {};
if (isNil {_trader getVariable "HALs_store_trader_type"}) exitWith {};

if (_target isEqualType false) then {
	if (hasInterface) then {
		[
			_trader,
			localize "STR_HALS_STORE_OPEN_ACTION",
			"\a3\Ui_F_Oldman\Data\IGUI\Cfg\HoldActions\holdAction_market_ca.paa",
			"\a3\Ui_F_Oldman\Data\IGUI\Cfg\HoldActions\holdAction_market_ca.paa",
			"alive _target && _this distance _target < 3 && isNull objectParent _this",
			"_this distance _target < 3",
			{},
			{},
			{
				params ["_trader", "_caller", "_actionId", "_arguments"];

				[_trader] call HALs_store_fnc_openStore;
			}, {}, [], 0.5, nil, false, false
		] call BIS_fnc_holdActionAdd;

		_trader addAction [
			"Buy 1000 primary rounds",
			{
				params ["_target", "_caller", "_actionId", "_args"];

				private _bulk_ammo_count = 1000;
				private _bulk_normal_price = 2;
				private _bulk_other_price = 6;

				private _primary = primaryWeapon _caller;
				if (_primary == "") exitWith {
					["Buy ammo", "You need a primary weapon."] call A3A_fnc_customHint;
				};

				private _state = weaponState _caller;
				_state params ["_weapon", "_muzzle", "_fireMode", "_magazine", "_ammoCount"];

				if (_weapon != _primary || {_magazine == ""}) exitWith {
					["Buy ammo", "Load a magazine into your primary weapon first."] call A3A_fnc_customHint;
				};

				private _magCfg = configFile >> "CfgMagazines" >> _magazine;
				if (!isClass _magCfg) exitWith {
					["Buy ammo", "Unknown magazine type."] call A3A_fnc_customHint;
				};

				private _ammoName = getText (_magCfg >> "ammo");
				if (_ammoName == "") exitWith {
					["Buy ammo", "Unknown ammo type."] call A3A_fnc_customHint;
				};

				private _ammoCfg = configFile >> "CfgAmmo" >> _ammoName;
				if (!isClass _ammoCfg) exitWith {
					["Buy ammo", "Unknown ammo config."] call A3A_fnc_customHint;
				};

				private _classText = toLower (_magazine + " " + _ammoName);

				private _is40mm = (_classText find "_40mm") >= 0;
				private _indirectHitRange = getNumber (_ammoCfg >> "indirectHitRange");
				private _submunitionAmmo = getText (_ammoCfg >> "submunitionAmmo");
				private _isGrenadeCore = _ammoName isKindOf ["GrenadeCore", configFile >> "CfgAmmo"];

				if (
					_is40mm
					|| {_indirectHitRange > 0}
					|| {_submunitionAmmo != ""}
					|| {_isGrenadeCore}
				) exitWith {
					["Buy ammo", "Trader doesn't sell it in bulk."] call A3A_fnc_customHint;
				};

				private _normalTokens = [
					"_545x",
					"_556x",
					"_57x",
					"_65x",
					"_68x",
					"_762x",
					"_9x",
					"_9mm",
					"_45acp",
					"_300blk",
					"baf_556",
					"baf_762"
				];

				private _isNormal = false;
				{
					if ((_classText find _x) >= 0) exitWith {
						_isNormal = true;
					};
				} forEach _normalTokens;

				private _pricePerRound = [_bulk_other_price, _bulk_normal_price] select _isNormal;
				private _price = _bulk_ammo_count * _pricePerRound;

				private _money = _caller getVariable ["moneyX", 0];
				if (_money < _price) exitWith {
					[
						"Buy ammo",
						format [
							"You need %1%2 to buy 1000 rounds.",
							_price,
							A3A_faction_civ get "currencySymbol"
						]
					] call A3A_fnc_customHint;
				};

				_caller setVariable ["moneyX", _money - _price, owner _caller];

				private _expenseText = format [
					localize "STR_comms_mp_givemoney",
					name _caller,
					_price,
					A3A_faction_civ get "currencySymbol"
				];
				[petros, "income", _expenseText] remoteExec ["A3A_fnc_commsMP", _caller];

				private _ammoQuantity = _bulk_ammo_count;
				//FIXME: IDC_RSCDISPLAYARSENAL_TAB_CARGOBULLET
				[27, _ammoName, _ammoQuantity] call jn_fnc_arsenal_addItem;

				[
					"Buy ammo",
					format [
						"Bought %1 rounds of %2 for %3%4. Package is delivered to the Arsenal.",
						_ammoQuantity,
						 ([_magCfg] call JN_fnc_arsenal_tehAmmoDisplayName),
						_price,
						A3A_faction_civ get "currencySymbol"
					]
				] call A3A_fnc_customHint;
			},
			nil,
			1.5,
			true,
			true,
			"",
			"alive _target && alive _this",
			5
		];
	};
} else {
	if (isServer) then {
		[_trader] remoteExecCall ["HALs_store_fnc_addActionTrader", _target, _trader];
	};
};