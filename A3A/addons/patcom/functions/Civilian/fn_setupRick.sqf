#include "dialogUtils.sqf"
params ["_rick"];

_rick setVariable ["TEH_CivRole", "Rick", true];
_rick setVariable ["TEH_RebelLoyalty", true, true];
removeUniform _rick;
removeVest _rick;
removeBackpack _rick;
removeHeadgear _rick;
removeGoggles _rick;

_rick forceAddUniform selectRandom (A3A_faction_civ getOrDefault ["TEH_rickUniforms", ["U_C_Man_casual_3_F"]]);
_rick addBackpack selectRandom (A3A_faction_civ getOrDefault ["TEH_rickBackpacks", ["B_CivilianBackpack_01_Sport_Green_F"]]);

private _rickHeadgears = A3A_faction_civ getOrDefault ["TEH_rickHeadgears", ["H_Bandanna_surfer_grn"]];

if (_rickHeadgears isNotEqualTo []) then {
	_rick addHeadgear selectRandom _rickHeadgears;
};

private _currency = A3A_faction_civ get "currencySymbol";

_rick addAction [
    format [localize "STR_TEH_RICK_ACTION_BUY_PISTOL",_currency],
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        _arguments params ["_sayToCaller"];

        // Pity gun settings. Local to this action on purpose.
        private _price = 300;
        private _loadout = selectRandom (A3A_faction_civ getOrDefault [
            "TEH_civilianHandgunLoadouts",
            [["hgun_Pistol_01_F", "", "", "", ["10Rnd_9x21_Mag"], [], ""]]
        ]);

        private _weapon = _loadout select 0;
        private _magazine = (_loadout select 4) select 0;
        private _magazineCount = 3;
        private _boxClass = "VirtualReammoBox_small_F";

        private _money = _caller getVariable ["moneyX", 0];
        if (_money < _price) exitWith {
            [_target, _caller, format [
                localize "STR_TEH_RICK_PISTOL_INSUFFICIENT_FUNDS",
                _price,
                A3A_faction_civ get "currencySymbol"
            ]] call _sayToCaller;
            false
        };

        _caller setVariable ["moneyX", _money - _price, owner _caller];

        private _expenseText = format [
            localize "STR_comms_mp_givemoney",
            name _caller,
            _price,
            A3A_faction_civ get "currencySymbol"
        ];
        [petros, "income", _expenseText] remoteExec ["A3A_fnc_commsMP", _caller];

        private _dropPos = _target modelToWorld [0, 1.2, 0];

        private _box = _boxClass createVehicle _dropPos;
        _box setDir (getDir _target);

        clearWeaponCargoGlobal _box;
        clearMagazineCargoGlobal _box;
        clearItemCargoGlobal _box;
        clearBackpackCargoGlobal _box;

        _box addWeaponCargoGlobal [_weapon, 1];
        _box addMagazineCargoGlobal [_magazine, _magazineCount];
        _box addBackpackCargoGlobal ["B_LegStrapBag_olive_F",1];

        _box setVariable ["TEH_IntroPistolBox", true, true];
        _box setVariable ["TEH_PurchasedByUID", getPlayerUID _caller, true];

        [_caller, _caller, format [
            localize "STR_TEH_RICK_PISTOL_PURCHASED",
            _price,
            A3A_faction_civ get "currencySymbol"
        ]] call _sayToCaller;

        sleep 1;
        _target playAction "PutDown";
        [_target, _caller, localize "STR_TEH_RICK_PISTOL_BOX_LOCATION"] call _sayToCaller;

        true
    },
    _actionArgs,
    1.5,
    true,
    true,
    "",
    format [
        "%1 && {_target getVariable ['TEH_CivRole', ''] isEqualTo 'Rick'}",
        _commonCondition
    ],
    3,
    false,
    "",
    ""
];

_rick addAction [
    localize "STR_TEH_RICK_ACTION_JOIN_RESISTANCE",
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        _arguments params ["_sayToCaller"];

        if (_caller getVariable ["TEH_Rebel", false]) exitWith {
            [_target, _caller, localize "STR_TEH_RICK_ALREADY_MEMBER"] call _sayToCaller;
            true
        };

         private _oldHandle = missionNamespace getVariable ["TEH_PickleRickMarkerHandle", scriptNull];

        if (!isNull _oldHandle) then {
            terminate _oldHandle;
        };

        deleteMarkerLocal "TEH_PickleRickMarker";

        private _handle = [_target] spawn {
            params ["_rick"];

            private _markerName = "TEH_PickleRickMarker";

            deleteMarkerLocal _markerName;

            private _marker = createMarkerLocal [_markerName, getPosATL _rick];
            _marker setMarkerTypeLocal "n_inf";
            _marker setMarkerColorLocal "ColorIndependent";
            _marker setMarkerTextLocal localize "STR_TEH_RICK_MARKER";
            _marker setMarkerSizeLocal [0.75, 0.75];
            _mrk setMarkerAlphaLocal 1;

            waitUntil {
                sleep 15;

                if (!isNull _rick && {alive _rick}) then {
                    _marker setMarkerPosLocal getPosATL _rick;
                    false
                } else {
                    true
                };
            };

            deleteMarkerLocal _markerName;
            missionNamespace setVariable ["TEH_PickleRickMarkerHandle", scriptNull];
        };

        missionNamespace setVariable ["TEH_PickleRickMarkerHandle", _handle];

        private _primary = primaryWeapon _caller;
        private _vest = vest _caller;
        private _score = _caller getVariable ["score", 0];

        private _primaryType = "";
        if (_primary != "") then {
            private _itemType = [_primary] call BIS_fnc_itemType;
            _primaryType = _itemType param [1, ""];
        };

        private _hasPrimary = _primary != "";
        private _hasValidPrimary = _hasPrimary && {!(_primaryType isEqualTo "Shotgun")};
        private _hasVest = _vest != "";
        private _hasScore = _score > 0;

        private _missing = [];
        private _progress = [];

        if (!_hasPrimary) then {
            _missing pushBack localize "STR_TEH_RICK_JOIN_WEAPON_REQUIRED";
        } else {
            if (!_hasValidPrimary) then {
                _missing pushBack localize "STR_TEH_RICK_JOIN_SHOTGUN_INSUFFICIENT";
            } else {
                _progress pushBack localize "STR_TEH_RICK_JOIN_WEAPON_ACCEPTED";
            };
        };

        if (!_hasVest) then {
            _missing pushBack localize "STR_TEH_RICK_JOIN_VEST_REQUIRED";
        } else {
            _progress pushBack localize "STR_TEH_RICK_JOIN_VEST_ACCEPTED";
        };

        if (!_hasScore) then {
            _missing pushBack localize "STR_TEH_RICK_JOIN_EXPERIENCE_REQUIRED";
        } else {
            _progress pushBack localize "STR_TEH_RICK_JOIN_EXPERIENCE_ACCEPTED";
        };

        if !(_missing isEqualTo []) exitWith {
            private _report = [localize "STR_TEH_RICK_JOIN_NOT_READY"] + _missing + _progress;
            [_target, _caller, _report joinString " "] call _sayToCaller;
            false
        };

        _caller setVariable ["TEH_Rebel", true, true];

        respawnTeamPlayer setMarkerAlphaLocal 1;
        petros setCaptive false;

        [_target, _caller, localize "STR_TEH_RICK_JOIN_ACCEPTED"] call _sayToCaller;

        true
    },
    _actionArgs,
    1.5,
    true,
    true,
    "",
    format [
        "%1 && {_target getVariable ['TEH_CivRole', ''] isEqualTo 'Rick'} && TEH_WarTierZero",
        _commonCondition
    ],
    3,
    false,
    "",
    ""
];