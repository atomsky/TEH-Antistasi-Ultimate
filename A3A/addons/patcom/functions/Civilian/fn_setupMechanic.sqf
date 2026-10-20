//Returns mechanics car to be cleared after the town is despawned
#include "dialogUtils.sqf"

params ["_mechanic","_mechanicsCar"];

removeAllWeapons _mechanic;
removeAllItems _mechanic;
removeAllAssignedItems _mechanic;
removeUniform _mechanic;
removeVest _mechanic;
removeBackpack _mechanic;
removeHeadgear _mechanic;
removeGoggles _mechanic;

_mechanic forceAddUniform selectRandom (A3A_faction_civ getOrDefault ["TEH_mechanicUniforms", ["U_C_Mechanic_01_F"]]);

private _mechanicHeadgears = A3A_faction_civ getOrDefault ["TEH_mechanicHeadgears", ["H_Cap_red"]];

if (_mechanicHeadgears isNotEqualTo []) then {
	_mechanic addHeadgear selectRandom _mechanicHeadgears;
};

private _currency = A3A_faction_civ get "currencySymbol";

_mechanic addAction [
    format [localize "STR_TEH_MECHANIC_ACTION_REPAIR",_currency],
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        _arguments params ["_sayToCaller"];

        private _price = 150;
        private _currency = A3A_faction_civ get "currencySymbol";

        private _nearbyCars = nearestObjects [_caller, ["Car"], 50] select {
            alive _x
            && {_x getVariable ["ownerSide", sideUnknown] == teamPlayer}
        };

        if (_nearbyCars isEqualTo []) exitWith {
            [_target, _caller, format [
                localize "STR_TEH_MECHANIC_NO_CAR",
                _price,
                _currency
            ]] call _sayToCaller;

            false
        };

        private _money = _caller getVariable ["moneyX", 0];
        if (_money < _price) exitWith {
            [_target, _caller, format [
                localize "STR_TEH_MECHANIC_INSUFFICIENT_FUNDS",
                _price,
                _currency
            ]] call _sayToCaller;

            false
        };

        private _vehicle = _nearbyCars # 0;

        _caller setVariable ["moneyX", _money - _price, owner _caller];

        private _expenseText = format [
            localize "STR_comms_mp_givemoney",
            name _caller,
            _price,
            _currency
        ];
        [petros, "income", _expenseText] remoteExec ["A3A_fnc_commsMP", _caller];

        // Full repair. setDamage should cover normal cases, hitpoints loop is here for modded/odd vehicles.
        _vehicle setDamage 0;

        private _hitPoints = (getAllHitPointsDamage _vehicle) param [0, []];
        {
            _vehicle setHitPointDamage [_x, 0];
        } forEach _hitPoints;

        [_target, _caller, format [
            localize "STR_TEH_MECHANIC_REPAIR_COMPLETE",
            _price,
            _currency
        ]] call _sayToCaller;

        true
    },
    _actionArgs,
    1.5,
    true,
    true,
    "",
    "alive _this && alive _target",
    3,
    false,
    "",
    ""
];

// Put mechanic into the car, then kick him out so he ends up naturally near it.
_mechanic disableAI "PATH";
_mechanic setUnitPos "MIDDLE";
_mechanic moveInDriver _mechanicsCar;
[_mechanic] allowGetIn false;
moveOut _mechanic;

_mechanic setDir ([_mechanic, _mechanicsCar] call BIS_fnc_dirTo);
_mechanic doWatch (getPosATL _mechanicsCar);
doStop _mechanic;

// Semi-broken, but not a burning wreck.
_mechanicsCar setFuel (0.1 + random 0.35);
_mechanicsCar setDamage (0.66);

private _hitPoints = (getAllHitPointsDamage _mechanicsCar) param [0, []];

if ("HitEngine" in _hitPoints) then {
    _mechanicsCar setHitPointDamage ["HitEngine", 0.35 + random 0.35];
};

private _wheelHitPoints = _hitPoints select {
    (toLowerANSI _x) find "wheel" != -1
};

if !(_wheelHitPoints isEqualTo []) then {
    _mechanicsCar setHitPointDamage [selectRandom _wheelHitPoints, 0.65 + random 0.3];
};
_mechanicsCar lock true;

_mechanicsCar;