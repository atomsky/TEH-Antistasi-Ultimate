#include "..\..\script_component.hpp"
FIX_LINE_NUMBERS()

if (!hasInterface) exitWith {};

params ["_flag","_typeX"];

private _actionX = -1;

switch _typeX do
{
    case "take":
    {
        removeAllActions _flag;
        _actionX = _flag addAction [format["<img image='\A3\ui_f\data\igui\cfg\actions\takeflag_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", (localize "STR_antistasi_actions_take_flag")], A3A_fnc_mrkWIN,nil,6,true,true,"","((isPlayer _this) and (_this == _this getVariable ['owner',objNull])) or (_this isKindOf 'SoldierGB')",4];
        _flag setUserActionText [_actionX,(localize "STR_antistasi_actions_take_flag"),"<t size='2'><img image='\A3\ui_f\data\igui\cfg\actions\takeflag_ca.paa'/></t>"];
    };
    case "unit":
    {
        if (playerRecruitAI isEqualTo 1) then 
        {
            _flag addAction [
                format ["<img image='\a3\ui_f\data\igui\cfg\simpletasks\types\meet_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", localize "STR_antistasi_actions_recruit_units"],
                {
                    if ([getPosATL player] call A3A_fnc_enemyNearCheck) then {
                        [localize "STR_antistasi_actions_unit_recruitment", localize "STR_antistasi_actions_unit_recruitment_distance_check_failure"] call A3A_fnc_customHint;
                    } else { 
                        [] spawn A3A_fnc_unit_recruit; 
                    };
                },nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])",4
            ];
        };
    };
    case "vehicle":
    {
        _flag addAction [
            format ["<img image='a3\ui_f\data\igui\cfg\simpletasks\types\truck_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", localize "STR_antistasi_actions_buy_vehicle"], 
            {
                if ([getPosATL player] call A3A_fnc_enemyNearCheck) then {
                    [localize "STR_antistasi_actions_buy_vehicle", localize "STR_antistasi_actions_buy_vehicle_distance_check_failure"] call A3A_fnc_customHint
                } else {
                    createDialog "A3A_BuyVehicleDialog";
                };
            },nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])",4
        ];
    };
    case "petros":
    {
        petros addAction [
            format ["<img image='\A3\ui_f\data\igui\cfg\simpleTasks\types\talk_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", localize "STR_antistasi_actions_request_mission"], {
                #ifdef UseDoomGUI
                    ERROR("Disabled due to UseDoomGUI Switch.")
                #else
                    createDialog "missionMenu";
                #endif
            },
            nil,0,false,true,"","([_this] call A3A_fnc_isMember or _this == theBoss) and (petros == leader group petros)",4
        ];
        petros addAction [localize "STR_antistasi_actions_move_this_asset", A3A_fnc_carryItem,nil,0,false,true,"","(_this == theBoss) and (petros == leader group petros) and (isNull objectParent _this) and !(call A3A_fnc_isCarrying)"];
        petros addAction [format ["<img image='a3\ui_f\data\igui\cfg\actions\takeflag_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", localize "STR_antistasi_actions_build_hq"], A3A_fnc_buildHQ,nil,0,false,true,"","(_this == theBoss) and (petros != leader group petros)",4];
    };
    case "truckX":
    {
        actionX = _flag addAction [
            format [
                "<img image='\A3\ui_f\data\igui\cfg\actions\unloadVehicle_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", 
                localize "STR_antistasi_transfer_ammobox_to_truck"
            ], A3A_fnc_transfer, nil, 6, true, true, "", "(isPlayer _this) and (_this == _this getVariable ['owner',objNull])"
        ];
    };
    case "heal":
    {
        if (player != _flag) then
        {
            _actionX = _flag addAction [
                format [
                    (format ["<img size='1.8' <img image='\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_revive_ca.paa' /> <t>%1</t>", localize "STR_antistasi_actions_revive"]), 
                    name _flag
                ], A3A_fnc_actionRevive,nil,6,true,true,"","!(_this getVariable [""helping"",false]) and (isNull attachedTo _target)",4
            ];
            _flag setUserActionText [_actionX,format [(localize "STR_antistasi_actions_revive"), name _flag],"<t size='2'><img image='\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_revive_ca.paa'/></t>"];

            if (reviveKitsEnabled) then {
                [
                    _flag,
                    format [localize "STR_antistasi_actions_crk_use", name _flag],
                    "a3\missions_f_exp\data\img\lobby\ui_campaign_lobby_background_tablet_button_revive02_ca.paa",
                    "a3\missions_f_exp\data\img\lobby\ui_campaign_lobby_background_tablet_button_revive02_ca.paa",
                    "'A3AP_SelfReviveKit' in (backpackItems player) && _this distance _target < 4 && (isPlayer _this) and (_this == _this getVariable ['owner',objNull]) and (isNull attachedTo _target) and !(_this getVariable [""helping"",false]);",
                    "'A3AP_SelfReviveKit' in (backpackItems player) && _this distance _target < 4 && (isPlayer _this) and (_this == _this getVariable ['owner',objNull]) and (isNull attachedTo _target) and !(_this getVariable [""helping"",false]);",
                    {},
                    {},
                    {
                        params ["_target", "_caller", "_actionId", "_arguments"];
                        [_caller, _target] call SCRT_fnc_common_revive;
                        [_target, _actionId] call BIS_fnc_holdActionRemove;
                    }, {}, [], 2, 0, false, false
                ] call BIS_fnc_holdActionAdd;
            };
        };
    };
    case "heal1":
    {
        if (player != _flag) then
        {
            _actionX = _flag addAction [
                format [(format ["<img size='1.8' <img image='\a3\ui_f\data\igui\cfg\simpletasks\types\help_ca.paa' /> <t>%1</t>", localize "STR_antistasi_actions_revive"]), name _flag], 
                A3A_fnc_actionRevive,
                nil,
                6,true,false,"","!(_this getVariable [""helping"",false]) and (isNull attachedTo _target)",4
            ];
            _flag setUserActionText [_actionX,format [(localize "STR_antistasi_actions_revive"),name _flag],"<t size='2'><img image='\a3\ui_f\data\igui\cfg\simpletasks\types\help_ca.paa'/></t>"];

            _actionX = _flag addAction [
                format [(format ["<img size='1.8' <img image='\a3\ui_f\data\igui\cfg\actions\take_ca.paa' /> <t>%1</t>", localize "STR_antistasi_actions_carry"]),name _flag], 
                A3A_fnc_carry,nil,5,true,false,"",
                "(isPlayer _this) and (_this == _this getVariable ['owner',objNull]) and (isNull attachedTo _target) and !(_this getVariable [""helping"",false]) and !(call A3A_fnc_isCarrying);",4
            ];
            _flag setUserActionText [_actionX,format [localize "STR_antistasi_actions_carry", name _flag],"<t size='2'><img image='\a3\ui_f\data\igui\cfg\actions\take_ca.paa'/></t>"];
            if (reviveKitsEnabled) then {
                [
                    _flag,
                    format [localize "STR_antistasi_actions_crk_use", name _flag],
                    "a3\missions_f_exp\data\img\lobby\ui_campaign_lobby_background_tablet_button_revive02_ca.paa",
                    "a3\missions_f_exp\data\img\lobby\ui_campaign_lobby_background_tablet_button_revive02_ca.paa",
                    "'A3AP_SelfReviveKit' in (backpackItems player) && _this distance _target < 4 && (isPlayer _this) and (_this == _this getVariable ['owner',objNull]) and (isNull attachedTo _target) and !(_this getVariable [""helping"",false]);",
                    "'A3AP_SelfReviveKit' in (backpackItems player) && _this distance _target < 4 && (isPlayer _this) and (_this == _this getVariable ['owner',objNull]) and (isNull attachedTo _target) and !(_this getVariable [""helping"",false]);",
                    {},
                    {},
                    {
                        params ["_target", "_caller", "_actionId", "_arguments"];
                        [_caller, _target] call SCRT_fnc_common_revive;
                        [_target, _actionId] call BIS_fnc_holdActionRemove;
                    }, {}, [], 2, 0, false, false
                ] call BIS_fnc_holdActionAdd;
            };

            [_flag] call A3A_Logistics_fnc_addLoadAction;
        };
    };
    case "heal2":
    {
        _actionX = _flag addAction [
            format [
                (format ["<img size='1.8' <img image='\a3\ui_f\data\igui\cfg\simpletasks\types\help_ca.paa' /> <t>%1</t>", localize "STR_antistasi_actions_revive"]), 
                name _flag
            ], A3A_fnc_actionRevive,nil,6,true,false,"","!(_this getVariable [""helping"",false]) and (isNull attachedTo _target)",4];
        _flag setUserActionText [_actionX,format [(localize "STR_antistasi_actions_revive"),name _flag],"<t size='2'><img image='\a3\ui_f\data\igui\cfg\simpletasks\types\help_ca.paa'/></t>"];
    };
    case "remove":
    {
        if (player == _flag) then
        {
            if (isNil "actionX") then
            {
                removeAllActions _flag;
                if (player == player getVariable ["owner",player]) then {[] call SA_Add_Player_Tow_Actions};
            }
            else
            {
                _flag removeAction actionX;
            };
        }
        else
        {
            removeAllActions _flag;
        };
    };
    case "refugee":
    {
        _flag addAction [format [
            "<img image='\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", 
            localize "STR_antistasi_actions_free_prisoner"
        ], A3A_fnc_liberateRefugee,nil,6,true,true,"","(isPlayer _this) && (_this == _this getVariable ['owner',objNull]) && alive _target",4];
    };
    case "deserter":
    {
        _flag addAction [format [
            "<img image='\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", 
            localize "STR_antistasi_actions_free_prisoner"
        ], A3A_fnc_liberateDeserter,nil,6,true,true,"","(isPlayer _this) && (_this == _this getVariable ['owner',objNull]) && alive _target",4];
    };
    case "prisonerX":
    {
        _flag addAction [format [
            "<img image='\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", 
            localize "STR_antistasi_actions_free_prisoner"
        ], A3A_fnc_liberatePOW,nil,6,true,true,"","(isPlayer _this) && (_this == _this getVariable ['owner',objNull]) && alive _target",4];
    };
    case "prisonerFlee":
    {
        _flag addAction [format [
            "<img image='\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", 
            localize "STR_antistasi_actions_free_prisoner"
        ], A3A_fnc_liberateFlee,nil,6,true,true,"","(isPlayer _this) && (_this == _this getVariable ['owner',objNull]) && alive _target",4];
    };
    case "townVIP":
    {
        _flag addAction [format [
            "<img image='\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", 
            localize "STR_antistasi_actions_protect_vip"
        ], A3A_fnc_liberateVIP,nil,6,true,true,"","(isPlayer _this) && (_this == _this getVariable ['owner',objNull]) && alive _target",4];
    };
    case "captureX":
    {
        // Uses the optional param to determine whether the call of captureX is a release or a recruit
        _flag addAction [format ["<img image='\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", localize "STR_release_action"], { _this spawn A3A_fnc_captureX; },[false, false],6,true,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])",4];
        _flag addAction [format ["<img image='a3\missions_f_oldman\data\img\holdactions\holdaction_follow_start_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", localize "STR_recruit_to_faction_action"], { _this spawn A3A_fnc_captureX; },[true,false],0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])",4];
        if (recruitToPlayerSquad) then {
            _flag addAction [format ["<img image='a3\missions_f_oldman\data\img\holdactions\holdaction_follow_start_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", localize "STR_recruit_to_squad_action"], { _this spawn A3A_fnc_captureX; },[true,true],0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])",4];
        };
        _flag addAction [format ["<img image='\a3\missions_f_oldman\data\img\holdactions\holdaction_talk_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", localize "STR_interrogate_action"], A3A_fnc_interrogate, nil, 0, false, true, "", "(isPlayer _this) and (_this == _this getVariable ['owner',objNull]) and (_target getVariable ['canBeInterrogated', false])",4];
        _flag addAction [format ["<img image='\a3\ui_f_oldman\data\igui\cfg\holdactions\map_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", localize "STR_reveal_action"],SCRT_fnc_common_reveal,false,6,true,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])",4];
    };
    case "captureRivals":
    {
        _flag addAction [format ["<img image='a3\ui_f\data\igui\cfg\holdactions\holdaction_secure_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", localize "STR_imprison_action"], { _this spawn SCRT_fnc_rivals_imprison; },false,6,true,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])",4];
        _flag addAction [format ["<img image='a3\missions_f_oldman\data\img\holdactions\holdaction_talk_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", localize "STR_interrogate_action"], A3A_fnc_interrogateRivals, nil, 0, false, true, "", "(isPlayer _this) and (_this == _this getVariable ['owner',objNull]) and (_target getVariable ['canBeInterrogated', false])",4];
        _flag addAction [format ["<img image='a3\ui_f_oldman\data\igui\cfg\holdactions\map_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", localize "STR_reveal_action"],SCRT_fnc_common_reveal,false,6,true,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])",4];
    };
    case "seaport":
    {
        // No additional actions assigned.
    };
    case "garage":
    {
        [_flag] call HR_GRG_fnc_initGarage;
    };
    case "SDKFlag":
    {
#ifdef UseDoomGUI
        if (true) exitWith { ERROR("Disabled due to UseDoomGUI Switch.") };
#endif
        removeAllActions _flag;
        if (playerRecruitAI isEqualTo 1) then {
            _flag addAction [
                format ["<img image='\a3\ui_f\data\igui\cfg\simpletasks\types\meet_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", localize "STR_antistasi_actions_recruit_units"], 
                {
                    if ([getPosATL player] call A3A_fnc_enemyNearCheck) then {
                        [localize "STR_antistasi_actions_unit_recruitment", localize "STR_antistasi_actions_unit_recruitment_distance_check_failure"] call A3A_fnc_customHint;
                    } else { 
                        [] spawn A3A_fnc_unit_recruit; 
                    };
                },nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])",4
            ];
        };
        _flag addAction [
            format ["<img image='a3\ui_f\data\igui\cfg\simpletasks\types\truck_ca.paa' size='1.6' shadow=2 /> <t>%1</t>",  localize "STR_antistasi_actions_buy_vehicle"], 
            {
                if ([getPosATL player] call A3A_fnc_enemyNearCheck) then {
                    [localize "STR_antistasi_dialogs_buy_vehicle_frame_text", localize "STR_antistasi_actions_buy_vehicle_distance_check_failure"] call A3A_fnc_customHint;
                } else {
                    createDialog "A3A_BuyVehicleDialog";
                }
            },nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])",4
        ];
        [_flag] call HR_GRG_fnc_initGarage;
        _flag addAction [
            (format ["<img image='%1' size='1.6' shadow=2/>", "\A3\Ui_f\data\IGUI\Cfg\Actions\reload_ca.paa"] + format["<t size='1'> %1</t>", "Quick resupply"]),
            { 
                [vehicle player] call JN_fnc_arsenal_quickReload;
            },
            [],
            15,
            true,
            false,
            "",
            "alive _target"
        ];
    };
    case "Intel_Small":
    {
        _flag addAction [
            format ["<img image='\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_search_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", localize "STR_search_intel_text"],
            A3A_fnc_searchIntelOnLeader,
            nil,
            4,
            true,
            false,
            "",
            "!([_target] call A3A_fnc_canFight) && !(_target getVariable ['intelSearchDone', false]) && isPlayer _this",
            4
        ];
    };
    case "Intel_Medium":
    {
        _flag addAction [format ["<img image='a3\ui_f\data\igui\cfg\holdactions\holdaction_search_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", localize "STR_antistasi_actions_take_intel"], A3A_fnc_searchIntelOnDocument, nil, 4, true, false, "", "isPlayer _this", 4];
    };
    case "Intel_Large":
    {
        _flag addAction [format ["<img image='a3\ui_f\data\igui\cfg\holdactions\holdaction_hack_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", localize "STR_antistasi_actions_download_intel"], A3A_fnc_searchIntelOnLaptop, nil, 4, true, false, "", "isPlayer _this", 4];
    };
    case "Intel_Encrypted":
    {
        _flag addAction [format ["<img image='a3\ui_f\data\igui\cfg\holdactions\holdaction_hack_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", localize "STR_antistasi_actions_decipher_intel"], A3A_fnc_searchEncryptedIntel, nil, 4, true, false, "", "isPlayer _this", 4];
    };
    case "Intel_Rivals_Laptop":
    {
        _flag addAction [
            format ["<img image='\a3\ui_f\data\igui\cfg\holdactions\holdaction_hack_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", localize "STR_millaptop_getdata_text"],
            SCRT_fnc_rivals_searchDataOnLaptop,
            nil,
            4,
            true,
            false,
            "",
            "isPlayer _this && (_target getVariable ['laptopSearchDone', false] != true)",
            4
        ];
    };
    case "Move_Outpost_Static":
    {
        _flag addAction [localize "STR_antistasi_actions_move_static_weapon_emplacement", SCRT_fnc_common_moveOutpostStatic, nil, 4, true, false, "", "isPlayer _this", 4];
    };

    #define VEHICLE_STATIC_COND(aiFlagVar1) \
        QUOTE((isPlayer _this) && {isNull objectParent _this} && {_this call A3A_fnc_isMember} && {[ARR_2(_target,aiFlagVar1)] call A3A_fnc_canAIMountVehicle})
    case "static":
    {
        _flag addAction [localize "STR_antistasi_actions_move_static_allow_ai", A3A_fnc_unlockStatic, nil, 1, false, true, "", VEHICLE_STATIC_COND(true), 4];
        _flag addAction [localize "STR_antistasi_actions_move_static_prevent_ai", A3A_fnc_lockStatic, nil, 1, false, true, "", VEHICLE_STATIC_COND(false), 4];
        _flag addAction [localize "STR_antistasi_actions_move_this_asset", A3A_fnc_carryItem, nil, 1.5, false, true, "", QUOTE(
            (isPlayer _this) && {isNull objectParent _this} && {_this call A3A_fnc_isMember} &&
            {_target getVariable[ARR_2(QQUOTE(ownerSide),teamPlayer)] == teamPlayer} && {locked _target < 2} && {isNull attachedTo _target} &&
            {crew _target isEqualTo []} && {!(call A3A_fnc_isCarrying)}
        ), 4];
    };
    case "vehiclestatic":
    {
        _flag addAction [localize "STR_antistasi_actions_move_vehicle_allow_ai", A3A_fnc_unlockStatic, nil, 1, false, true, "", VEHICLE_STATIC_COND(true), 4];
        _flag addAction [localize "STR_antistasi_actions_move_vehicle_prevent_ai", A3A_fnc_lockStatic, nil, 1, false, true, "", VEHICLE_STATIC_COND(false), 4];
    };
    #undef VEHICLE_STATIC_COND

    case "rivals_quest":
    {
        _flag addAction [
            format ["<img image='\a3\ui_f\data\igui\cfg\holdactions\holdaction_hack_ca.paa' size='1.6' shadow=2 /> <t>%1</t>", localize "STR_millaptop_getdata_text"],
            SCRT_fnc_rivals_searchDataOnLaptopTask,
            nil,
            4,
            true,
            false,
            "",
            "isPlayer _this && (_target getVariable ['laptopSearchDone', false] != true)",
            4
        ];
    };
    
    case "spotting":
    {
        _flag addAction [
            "<t color='#ffaa00'>Reveal target</t>",
            {
                params ["_target", "_caller"];

                private _contact = cursorObject;
                if (isNull _contact) exitWith { systemChat "PMR: Nothing to see here."; };
                if !(_contact isKindOf "AllVehicles") exitWith { systemChat "PMR: Nothing to see here."; };

                private _desc = "";

                if (_contact isKindOf "CAManBase") then {
                    private _getItemName = {
                        params ["_class", "_fallback"];
                        if (_class isEqualTo "") exitWith {_fallback};

                        private _name = getText (configFile >> "CfgWeapons" >> _class >> "displayName");
                        if (_name isEqualTo "") then {_class} else {_name};
                    };

                    private _uniformName = [uniform _contact, "ordinary civilian clothes"] call _getItemName;
                    private _vestName = [vest _contact, ""] call _getItemName;
                    private _headgearName = [headgear _contact, ""] call _getItemName;

                    private _parts = [format [" He wears %1", _uniformName]];
                    if (_vestName isNotEqualTo "") then {_parts pushBack format ["with %1", _vestName]};
                    if (_headgearName isNotEqualTo "") then {_parts pushBack format ["and %1 on his head", _headgearName]};

                    _desc = _parts joinString ", "
                };

                private _cside = side _contact;
                player reveal _contact;
                if !(_cside == Occupants || _cside == Invaders) exitWith {
                    player reveal _contact;

                    systemChat format ["PMR: You're looking at %1 %2.%3", side _contact, getText (configFile >> "CfgVehicles" >> typeOf _contact >> "displayname"),_desc];
                };

                {
                    [_x, [_contact,4]] remoteExec ["reveal", 2];
                } forEach ((getPosATL _caller) nearObjects ["Land", 500] select { side _x == side _caller });

                systemChat format ["PMR: Spotted enemy %1!%2", getText (configFile >> "CfgVehicles" >> typeOf _contact >> "displayname"),_desc];
            },
            nil,
            1.5,
            true,
            true,
            "",  // no shortcut
            "(currentWeapon player) isKindOf ['Binocular', configFile >> 'CfgWeapons']",
            -1
        ];

    };

    case "zip":
    {
        if (_flag getVariable ["TEH_hasStabilizeAction", false]) exitWith {};

        _flag setVariable ["TEH_hasStabilizeAction", true];

        _flag addAction [
            "<t color='#ff7700'>Take prisoner</t>",
            {
                params ["_target", "_caller"];

                private _zipTieClass = "ACE_CableTie";

                private _targetHasZipTie = _zipTieClass in (items _target);
                private _callerHasZipTie = _zipTieClass in (items _caller);

                if (!_targetHasZipTie && !_callerHasZipTie) exitWith {
                    ["Take prisoner", "Cable tie not found"] call A3A_fnc_customHint;
                };

                [
                    "Stabilizing the prisoner",
                    10,
                    {
                        params ["_args"];
                        _args params ["_target", "_caller"];

                        _caller isEqualTo player
                        && {alive _target}
                        && {alive _caller}
                        && {lifeState _caller isNotEqualTo "INCAPACITATED"}
                        && {isNull objectParent _caller}
                        && {_caller distance _target < 3}
                        && {[_target] call ace_medical_fnc_isInjured}
                    },
                    {
                        params ["_args"];
                        _args params ["_target", "_caller", "_zipTieClass"];

                        private _targetHasZipTie = _zipTieClass in (items _target);
                        private _callerHasZipTie = _zipTieClass in (items _caller);

                        if (!_targetHasZipTie && {!_callerHasZipTie}) exitWith {
                            ["Take prisoner", "Cable tie not found"] call A3A_fnc_customHint;
                        };

                        if (_targetHasZipTie) then {
                            _target removeItem _zipTieClass;
                        } else {
                            _caller removeItem _zipTieClass;
                        };

                        [_target, _caller] call ace_medical_fnc_fullHeal;
                    },
                    {},
                    [_target, _caller, _zipTieClass]
                ] call CBA_fnc_progressBar;
            },
            nil,
            1.5,
            true,
            true,
            "",
            "alive _target && (_target getVariable ['incapacitated', false])",
            2
        ];
    };

    case "stabilize":
    {
        if (_flag getVariable ["TEH_hasStabilizeAction", false]) exitWith {};

        _flag setVariable ["TEH_hasStabilizeAction", true];

        _flag addAction [
            "<t color='#007700'>Heal</t>",
            {
                params ["_target", "_caller"];

                [
                    "Stabilizing comrade",
                    30,
                    {
                        params ["_args"];
                        _args params ["_target", "_caller"];

                        _caller isEqualTo player
                        && {alive _target}
                        && {alive _caller}
                        && {lifeState _caller isNotEqualTo "INCAPACITATED"}
                        && {isNull objectParent _caller}
                        && {_caller distance _target < 3}
                        && {[_target] call ace_medical_fnc_isInjured}
                    },
                    {
                        params ["_args"];
                        _args params ["_target", "_caller"];

                        [_target, _caller] call ace_medical_fnc_fullHeal;
                    },
                    {},
                    [_target, _caller]
                ] call CBA_fnc_progressBar;
            },
            nil,
            1.5,
            true,
            true,
            "",
            "alive _target && (_target getVariable ['incapacitated', false])",
            2
        ];
    };

    case "arrest":
    {
        _flag addAction [
            "<t color='#770077'>Surrender!</t>",
            {
                params ["_target", "_caller"];
                _target setVariable ["surrendered", false, true];
                [_target] call A3A_fnc_surrenderAction;
            },
            nil,
            1.5,
            true,
            true,
            "",  // no shortcut
            "alive _target && canMove _target && (isNil {_target getVariable 'A3U_PoW_unitType'});",
            25
        ];

    };
};

_actionX
