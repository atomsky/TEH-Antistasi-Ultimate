/*
    Author:
        MaxxLite / TEH

    Description:
        Adds local civilian dialog actions.

    Params:
        _unit <Default: ObjNull>

    Scope:
        Client

    Environment:
        Unscheduled

    Usage:
        [_unit] call A3A_fnc_dialogCiv;
*/

#include "..\..\script_component.hpp"
#include "dialogUtils.sqf"
FIX_LINE_NUMBERS()

params [["_unit", objNull]];

if (isNull _unit) exitWith {false};



_unit addAction [
    localize "STR_TEH_CIVILIAN_ACTION_HELLO",
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        _arguments params ["_sayToCaller"];

        private _question = selectRandom [
            localize "STR_TEH_CIVILIAN_HELLO_VARIANT_01",
            localize "STR_TEH_CIVILIAN_HELLO_VARIANT_02",
            localize "STR_TEH_CIVILIAN_HELLO_VARIANT_03",
            localize "STR_TEH_CIVILIAN_HELLO_VARIANT_04"
        ];

        [_caller, _caller, _question] call _sayToCaller;

        _target disableAI "PATH";
        _target lookAt _caller;
        _target playActionNow (selectRandom ["GestureHi","GestureHiB","GestureHiC"]);
        sleep 1;
        private _playerHeadgear = headgear _caller;
        private _targetHeadgear = headgear _target;
        
        //Шапочное знакомство
        if (TEH_WarTierZero && !(_caller getVariable ["TEH_Rebel", false]) && {!(_target getVariable ["TEH_RebelLoyalty", false])} && _playerHeadgear != "" && {_playerHeadgear isEqualTo _targetHeadgear}) then {
            _target setVariable ["TEH_RebelLoyalty", true, true];

            [_target, _caller, selectRandom [
                localize "STR_TEH_CIVILIAN_HAT_GREETING_01",
                localize "STR_TEH_CIVILIAN_HAT_GREETING_02",
                localize "STR_TEH_CIVILIAN_HAT_GREETING_03",
                localize "STR_TEH_CIVILIAN_HAT_GREETING_04",
                localize "STR_TEH_CIVILIAN_HAT_GREETING_05",
                localize "STR_TEH_CIVILIAN_HAT_GREETING_06",
                localize "STR_TEH_CIVILIAN_HAT_GREETING_07"
            ]] call _sayToCaller;
        } else {
            [_target, _caller, selectRandom [
                localize "STR_TEH_CIVILIAN_GREETING_01",
                localize "STR_TEH_CIVILIAN_GREETING_02",
                localize "STR_TEH_CIVILIAN_GREETING_03"
            ]] call _sayToCaller;
        };

        _target setVariable ["TEH_DialogStarted", true, true];

        _target spawn {
            params ["_target"];
            sleep 60;
            if (alive _target) then {
                _target enableAI "PATH";
                _target doWatch objNull;
            };
        };
    },
    _actionArgs,
    1.5,
    true,
    true,
    "",
    "alive _target && {alive _this} && {isNull objectParent _this} && {!(_target getVariable ['TEH_DialogStarted', false])}",
    10,
    false,
    "",
    ""
];

_unit addAction [
    localize "STR_TEH_CIVILIAN_ACTION_ASK_CITY",
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        _arguments params ["_sayToCaller"];

        [_caller, _caller, selectRandom [
            localize "STR_TEH_CIVILIAN_ASK_CITY"
        ]] call _sayToCaller;
        _target lookAt _caller;

        sleep 1;

        if (_target getVariable ["TEH_RebelLoyalty", false]) then {
            _target playActionNow "gestureNod";
            [_target, _caller, selectRandom [
                localize "STR_TEH_CIVILIAN_CITY_LOYAL_01",
                localize "STR_TEH_CIVILIAN_CITY_LOYAL_02",
                localize "STR_TEH_CIVILIAN_CITY_LOYAL_03",
                localize "STR_TEH_CIVILIAN_CITY_LOYAL_04",
                localize "STR_TEH_CIVILIAN_CITY_LOYAL_05",
                localize "STR_TEH_CIVILIAN_CITY_LOYAL_06",
                localize "STR_TEH_CIVILIAN_CITY_LOYAL_07",
                localize "STR_TEH_CIVILIAN_CITY_LOYAL_08",
                localize "STR_TEH_CIVILIAN_CITY_LOYAL_09",
                localize "STR_TEH_CIVILIAN_CITY_LOYAL_10"
            ]] call _sayToCaller;
        } else {
            //_target playActionNow "gesturePoint";
            [_target, _caller, selectRandom [
                localize "STR_TEH_CIVILIAN_CITY_NEUTRAL_01",
                localize "STR_TEH_CIVILIAN_CITY_NEUTRAL_02",
                localize "STR_TEH_CIVILIAN_CITY_NEUTRAL_03",
                localize "STR_TEH_CIVILIAN_CITY_NEUTRAL_04",
                localize "STR_TEH_CIVILIAN_CITY_NEUTRAL_05",
                localize "STR_TEH_CIVILIAN_CITY_NEUTRAL_06",
                localize "STR_TEH_CIVILIAN_CITY_NEUTRAL_07",
                localize "STR_TEH_CIVILIAN_CITY_NEUTRAL_08",
                localize "STR_TEH_CIVILIAN_CITY_NEUTRAL_09",
                localize "STR_TEH_CIVILIAN_CITY_NEUTRAL_10"
            ]] call _sayToCaller;
        };
    },
    _actionArgs,
    1.5,
    true,
    true,
    "",
    _commonCondition,
    3,
    false,
    "",
    ""
];

_unit addAction [
    localize "STR_TEH_CIVILIAN_ACTION_ASK_SOLDIERS",
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        _arguments params ["_sayToCaller"];

        [_caller, _caller, selectRandom [
            localize "STR_TEH_CIVILIAN_ASK_SOLDIERS_01",
            localize "STR_TEH_CIVILIAN_ASK_SOLDIERS_02",
            localize "STR_TEH_CIVILIAN_ASK_SOLDIERS_03"
        ]] call _sayToCaller;
        _target lookAt _caller;
        sleep 1;

        if (_target getVariable ["TEH_CivSoldierIntelDone", false]) exitWith {
            [_target, _caller, localize "STR_TEH_CIVILIAN_SOLDIER_INTEL_EXHAUSTED"] call _sayToCaller;
            false
        };

        if (_target getVariable ["TEH_noIntel",true]) exitWith {
            [_target, _caller, selectRandom [
                localize "STR_TEH_CIVILIAN_NO_ENEMY_01",
                localize "STR_TEH_CIVILIAN_NO_ENEMY_02",
                localize "STR_TEH_CIVILIAN_NO_ENEMY_03"
            ]] call _sayToCaller;
        };

        if !(_target getVariable ["TEH_RebelLoyalty", false]) exitWith {
            _target playActionNow "gesturePoint";
            _target setVariable ["TEH_CivSoldierIntelDone", true, true];
            _target setVariable ["TEH_CivSoldierIntelSucceeded", false, true];
            if (random 100 > 66) then {
                [_target, _caller, selectRandom [
                    localize "STR_TEH_CIVILIAN_SOLDIER_REFUSAL_01",
                    localize "STR_TEH_CIVILIAN_SOLDIER_REFUSAL_02",
                    localize "STR_TEH_CIVILIAN_SOLDIER_REFUSAL_03"
                ]] call _sayToCaller;
            } else {
                [_target, _caller, selectRandom [
                    localize "STR_TEH_CIVILIAN_CALL_GUARDS",
                    localize "STR_TEH_CIVILIAN_CALL_POLICE",
                    localize "STR_TEH_CIVILIAN_CALL_ARREST"
                ]] call _sayToCaller;
                _caller setCaptive false;
            };

            false
        };

        _target playActionNow "GesturePutDown";
        sleep 1;

        private _revealedZone = false;
        if ((missionNamespace getVariable ["hideEnemyMarkers", false]) && {!(isNil "A3U_fnc_revealRandomZones")} && {random 100 < 35}) then {
            [1, "A civilian has revealed a zone"] call A3U_fnc_revealRandomZones;
            _revealedZone = true;
        };

        if (_revealedZone) then {
            [_target, _caller, selectRandom [
                localize "STR_TEH_CIVILIAN_ZONE_INTEL_01",
                localize "STR_TEH_CIVILIAN_ZONE_INTEL_02",
                localize "STR_TEH_CIVILIAN_ZONE_INTEL_03"
            ]] call _sayToCaller;
        } else {
            private _intel = ["Civilian", Occupants] call A3A_fnc_selectIntel;
            private _intelMessage = switch (_intel) do {
                case 502: {selectRandom ["STR_antistasi_actions_talk_with_civ_success_dealer1", "STR_antistasi_actions_talk_with_civ_success_dealer2"]};
                case 301: {selectRandom ["STR_antistasi_actions_talk_with_civ_success_traitor1", "STR_antistasi_actions_talk_with_civ_success_traitor2"]};
                case 302: {selectRandom ["STR_antistasi_actions_talk_with_civ_success_money1", "STR_antistasi_actions_talk_with_civ_success_money2"]};
                case 102: {selectRandom ["STR_antistasi_actions_talk_with_civ_success_decryption1", "STR_antistasi_actions_talk_with_civ_success_decryption2"]};
                default {"STR_antistasi_actions_talk_with_civ_fail1"};
            };

            [_target, _caller, localize _intelMessage] call _sayToCaller;
        };

        _target setVariable ["TEH_CivSoldierIntelDone", true, true];
        _target setVariable ["TEH_CivSoldierIntelSucceeded", true, true];

        true
    },
    _actionArgs,
    1.5,
    true,
    true,
    "",
    _commonCondition,
    3,
    false,
    "",
    ""
];

_unit addAction [
    localize "STR_TEH_CIVILIAN_ACTION_ASK_FIREARMS",
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        _arguments params ["_sayToCaller", "_getUnitTown", "_getTownVar", "_setTownVar", "_findTownCivs", "_describeContact"];

        [_caller, _caller, selectRandom [
            localize "STR_TEH_CIVILIAN_ASK_FIREARMS_01",
            localize "STR_TEH_CIVILIAN_ASK_FIREARMS_02",
            localize "STR_TEH_CIVILIAN_ASK_FIREARMS_03"
        ]] call _sayToCaller;

        _target lookAt _caller;
        sleep 1;

        // Non-loyal civilians either refuse or call for help.
        if !(_target getVariable ["TEH_RebelLoyalty", false]) exitWith {
            if (random 100 < 33) then {
                [_target, _caller, selectRandom [
                    "Guards! Guards!",
                    "Malden Police, arrest this man!",
                    "Stop right there criminal scum!"
                ]] call _sayToCaller;

                _caller setCaptive false;
            } else {
                [_target, _caller, selectRandom [
                    localize "STR_TEH_CIVILIAN_FIREARMS_REFUSAL_01",
                    localize "STR_TEH_CIVILIAN_FIREARMS_REFUSAL_02",
                    localize "STR_TEH_CIVILIAN_FIREARMS_REFUSAL_03",
                    localize "STR_TEH_CIVILIAN_FIREARMS_REFUSAL_04",
                    localize "STR_TEH_CIVILIAN_FIREARMS_REFUSAL_05"
                ]] call _sayToCaller;
            };

            false
        };

        private _town = [_target] call _getUnitTown;
        private _joe = [_town, "CacheLead", objNull] call _getTownVar;
        private _bob = [_town, "CacheContact", objNull] call _getTownVar;

        // Loyal Joe points the player to Bob and turns Bob into a valid rebel contact.

        if (_target isEqualTo _joe && {!isNull _bob} && {alive _bob}) exitWith {
            private _dist = _bob distance2D getMarkerPos _town;
            private _distDesc = if (_dist < 100) then {
                                    localize "STR_TEH_CIVILIAN_BOB_LOCATION_CENTER"
                                } else {
                                    if (_dist < 200) then {
                                        localize "STR_TEH_CIVILIAN_BOB_LOCATION_EDGE"
                                    } else {
                                        localize "STR_TEH_CIVILIAN_BOB_LOCATION_OUTSIDE"
                                    };
                                };
            private _description = [_bob] call _describeContact;

            if (_joe getVariable ["TEH_CacheUsed",false]) then {
                [_target, _caller, format [
                    localize "STR_TEH_CIVILIAN_BOB_CACHE_REPEAT",
                    _distDesc, _description
                ]] call _sayToCaller;
            } else {
                _bob setVariable ["TEH_RebelLoyalty", true, true];
                _bob setVariable ["TEH_CacheContactUnlocked", true, true];
                _joe setVariable ["TEH_CacheUsed",true,true];

                [_target, _caller, format [
                    localize "STR_TEH_CIVILIAN_BOB_CACHE_LEAD",
                    _distDesc, _description
                ]] call _sayToCaller;
            };

            true
        };

        // Loyal Bob stops here. The next action is the password.
        if (_target isEqualTo _bob) exitWith {
            [_target, _caller, localize "STR_TEH_CIVILIAN_BOB_PASSWORD_PROMPT"] call _sayToCaller;
            true
        };

        // Pickle Rick stops here.
        if (_target getVariable ["TEH_CivRole","none"] isEqualTo "Rick") exitWith {
            private _rickFirearmsLines = [
                localize "STR_TEH_CIVILIAN_RICK_FIREARMS_01",
                localize "STR_TEH_CIVILIAN_RICK_FIREARMS_02",
                localize "STR_TEH_CIVILIAN_RICK_FIREARMS_03",
                localize "STR_TEH_CIVILIAN_RICK_FIREARMS_04",
                localize "STR_TEH_CIVILIAN_RICK_FIREARMS_05",
                localize "STR_TEH_CIVILIAN_RICK_FIREARMS_06"
            ];
            [_target, _caller, selectRandom _rickFirearmsLines] call _sayToCaller;
            true
        };

        // Ordinary loyal civilians use pre-rolled arms info.
        private _role = _target getVariable ["TEH_CivRole", ""];
        if (_role isEqualTo "") exitWith {
            private _armsInfo = _target getVariable ["TEH_ArmsInfo", "none"];

            switch (_armsInfo) do {
                case "bandits": {
                    [_target, _caller, selectRandom [
                        localize "STR_TEH_CIVILIAN_ARMS_BANDITS_01",
                        localize "STR_TEH_CIVILIAN_ARMS_BANDITS_02",
                        localize "STR_TEH_CIVILIAN_ARMS_BANDITS_03"
                    ]] call _sayToCaller;
                };

                case "rick": {
                    [_target, _caller, selectRandom [
                        localize "STR_TEH_CIVILIAN_ARMS_RICK_01",
                        localize "STR_TEH_CIVILIAN_ARMS_RICK_02",
                        localize "STR_TEH_CIVILIAN_ARMS_RICK_03"
                    ]] call _sayToCaller;
                };

                case "bob": {
                    [_target, _caller, selectRandom [
                        localize "STR_TEH_CIVILIAN_ARMS_BOB_01",
                        localize "STR_TEH_CIVILIAN_ARMS_BOB_02",
                        localize "STR_TEH_CIVILIAN_ARMS_BOB_03"
                    ]] call _sayToCaller;
                };

                case "none";
                default {
                    [_target, _caller, selectRandom [
                        localize "STR_TEH_CIVILIAN_ARMS_NONE_01",
                        localize "STR_TEH_CIVILIAN_ARMS_NONE_02",
                        localize "STR_TEH_CIVILIAN_ARMS_NONE_03"
                    ]] call _sayToCaller;
                };
            };

            true
        };

        // Loyal, but has some other role that does not handle firearms.
        [_target, _caller, selectRandom [
            localize "STR_TEH_CIVILIAN_ARMS_OTHER_01",
            localize "STR_TEH_CIVILIAN_ARMS_OTHER_02",
            localize "STR_TEH_CIVILIAN_ARMS_OTHER_03"
        ]] call _sayToCaller;

        false
    },
    _actionArgs,
    1.5,
    true,
    true,
    "",
    _commonCondition,
    3,
    false,
    "",
    ""
];

private _currency = A3A_faction_civ get "currencySymbol";

_unit addAction [
    format [localize "STR_TEH_CIVILIAN_ACTION_BRIBE",_currency],
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        _arguments params ["_sayToCaller"];

        private _price = missionNamespace getVariable ["TEH_CivBribePrice", 150];

        private _money = _caller getVariable ["moneyX", 0];
        if (_money < _price) exitWith {
            [_target, _caller, format [localize "STR_TEH_CIVILIAN_BRIBE_INSUFFICIENT_FUNDS", _price]] call _sayToCaller;
            false
        };

        _caller setVariable ["moneyX", _money - _price, (owner _caller)];
        _target setVariable ["TEH_RebelLoyalty", true, true];

		private _expenceText = format [
			localize "STR_comms_mp_givemoney",
			name _caller,
			_price, 
			A3A_faction_civ get "currencySymbol"
		];		
		[petros, "income", _expenceText] remoteExec ["A3A_fnc_commsMP", _caller];

        [_caller, _caller, format [localize "STR_TEH_CIVILIAN_BRIBE_PAID", _price]] call _sayToCaller;
        
        _target lookAt _caller;
        sleep 1;
        _target playActionNow "gestureNod";
        [_target, _caller, localize "STR_TEH_CIVILIAN_BRIBE_ACCEPTED"] call _sayToCaller;

        true
    },
    _actionArgs,
    1.5,
    true,
    true,
    "",
    _commonCondition,
    3,
    false,
    "",
    ""
];

_unit addAction [
    localize "STR_TEH_CIVILIAN_ACTION_MEDICAL_HELP",
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        _arguments params ["_sayToCaller"];

        private _aceMedicalKit = [
            "ACE_fieldDressing",
            "ACE_packingBandage",
            "ACE_morphine",
            "ACE_tourniquet"
        ];

        private _callerItems = items _caller;

        private _hasVanillaKit = "FirstAidKit" in _callerItems;
        private _hasAceKit = (_aceMedicalKit findIf { !(_x in _callerItems) }) == -1;

        [_caller, _caller, localize "STR_TEH_CIVILIAN_MEDICAL_HELP_OFFER"] call _sayToCaller;

        _target lookAt _caller;
        sleep 1;

        if (!_hasVanillaKit && {!_hasAceKit}) exitWith {
            [_target, _caller, selectRandom [
                localize "STR_TEH_CIVILIAN_MEDICAL_REQUIRED_01",
                localize "STR_TEH_CIVILIAN_MEDICAL_REQUIRED_02",
                localize "STR_TEH_CIVILIAN_MEDICAL_REQUIRED_03"
            ]] call _sayToCaller;

            false
        };

        if (_hasVanillaKit) then {
            _caller removeItem "FirstAidKit";
        } else {
            {
                _caller removeItem _x;
            } forEach _aceMedicalKit;
        };

        _target setVariable ["TEH_RebelLoyalty", true, true];



        sleep 1;
        _target playActionNow "gestureNod";
        [_target, _caller, selectRandom [
            localize "STR_TEH_CIVILIAN_MEDICAL_THANKS_01",
            localize "STR_TEH_CIVILIAN_MEDICAL_THANKS_02",
            localize "STR_TEH_CIVILIAN_MEDICAL_THANKS_03",
            localize "STR_TEH_CIVILIAN_MEDICAL_THANKS_04"
        ]] call _sayToCaller;

        true
    },
    _actionArgs,
    1.5,
    true,
    true,
    "",
    _commonCondition + " && {!(_target getVariable ['TEH_RebelLoyalty', false])}",
    3,
    false,
    "",
    ""
];

true
