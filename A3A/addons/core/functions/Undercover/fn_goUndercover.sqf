/*
Maintainer: Wurzel0701
    Activates undercover if possible and controls its status till undercover is broken/ended

Arguments:
    <NIL>

Return Value:
    <NIL>

Scope: Local
Environment: Scheduled
Public: Yes
Dependencies:
    <HashMap> A3A_faction_civ
    <HashMap> A3A_faction_reb
    <ARRAY> controlsX
    <ARRAY> airportsX
    <ARRAY> outposts
    <ARRAY> seaports
    <ARRAY> undercoverVehicles
    <BOOL> A3A_hasACE
    <SIDE> Occupants
    <SIDE> Invaders
    <ARRAY> detectionAreas
    <NAMESPACE> sidesX
    <SIDE> teamPlayer
    <NUMBER> aggressionOccupants
    <NUMBER> aggressionInvaders
    <NUMBER> tierWar

Example:
    [] call A3A_fnc_goUndercover;
*/
#include "..\..\script_component.hpp"
FIX_LINE_NUMBERS()

private _result = [] call A3A_fnc_canGoUndercover;

if(!(_result select 0)) exitWith
{
    if((_result select 1) == "Spotted by enemies") then
    {
        if !(isNull (objectParent player)) then
        {
            (objectParent player) setVariable ["A3A_reported", true, true];
            {
                if ((isPlayer _x) && (captive _x)) then
                {
                    [_x, false] remoteExec["setCaptive", _x];
                };
            } forEach ((crew(objectParent player)) + (assignedCargo(objectParent player)) - [player]);
        };
    };
};

if (_result select 0 isEqualTo false) exitWith {["Undercover", _result select 1] call A3A_fnc_customHint};

private _layer = ["A3A_infoCenter"] call BIS_fnc_rscLayer;
[(localize "STR_antistasi_dialogs_radio_comm_undercover"), 0, 0, 4, 0, 0, _layer] spawn bis_fnc_dynamicText;

player setCaptive true;
[] spawn A3A_fnc_statistics;
if (player == leader group player) then
{
    {
        if ((!isplayer _x) && (local _x) && (_x getVariable["owner", _x] == player)) then
        {
            [_x] spawn A3A_fnc_undercoverAI;
        };
    } forEach units group player;
};

private _secureBases = (
    (airportsX + outposts + seaports + milbases + (controlsX select {isOnRoad(getMarkerPos _x)})) select {sidesX getVariable [_x, sideUnknown] != teamPlayer}
) + (milAdministrationsX select {sidesX getVariable [_x,sideUnknown] == Occupants});

private _lastBaseInside = "";
private _reason = "";

[CBA_EVENT_CLIENT_UNDERCOVER_CHANGED, [true]] call FUNCMAIN(triggerLocalEvent);

private _headgear = "";
private _armoredHeadgear = false;
private _uniform = "no uniform?";
private _civUniforms = (A3A_faction_civ get "uniforms")+TEH_whitelistCivilianUniforms;
private _allowedUniform = false;
private _primary = "";
private _visiblePrimary = false;
private _aiming = false;
private _aimStart = 0;
private _personnelCheckCd = 0;


while {_reason == ""} do
{
    private _healingTarget = objNull;
    if !(isNil {player getVariable "ace_medical_treatment_endInAnim"}) then
    {
        _healingTarget = currentAceTarget;
    };

    sleep 1;

    if (!captive player) exitWith
    {
        _reason = "Reported";
    };

    //equipment check only when changed
    if (headgear player != _headgear) then {
        _headgear = headgear player;
        _armoredHeadgear = _headgear in allArmoredHeadgear;
    };
    
    if (uniform player != _uniform) then {
        _uniform = uniform player;
        _allowedUniform = ((_uniform in _civUniforms) && (_allowedUniform isNotEqualTo ""));
    };

    if (primaryWeapon player != _primary) then {
        _visiblePrimary = true;
        _primary = primaryWeapon player;
        
        if (_primary isEqualTo "" or _primary isEqualTo "sgun_HunterShotgun_01_sawedoff_F") then { _visiblePrimary = false; };

        private _barrel = getNumber(configfile >> "CfgWeapons" >> _primary >> "ACE_barrelLength");

        if (!isNil "_barrel") then {
            if (_barrel < 222) exitWith { _visiblePrimary = false; };

            private _reload = getText(configfile >> "CfgWeapons" >> _primary >> "reloadAction");
            //P90 and bullpup rifles
            if (_barrel < 333 and _reload in ["GestureReload_smg_03","GestureReloadTRG"]) exitWith { _visiblePrimary = false; };
        };

        if ((primaryWeaponItems player # 0) isNotEqualTo "") then {
            _visiblePrimary = true;
        };
        
        if (_visiblePrimary) then {
           ["Undercover", "Unable to conceal the primary weapon - nearby enemies will break your cover. Only some short rifles/SMGs without suppressors can be concealed."] call A3A_fnc_customHint;
        };
    };

    if ((primaryWeaponItems player # 0) isNotEqualTo "") then {
        _visiblePrimary = true;
    };
    
    if (animationState player find "_aim" != -1) then {
        if (_aimStart > 1) then {
            _aiming = true;
        } else {
            _aimStart = _aimStart + 1;
        };
    } else {
        _aiming = false;
        _aimStart = 0;
    };
    
    //finding a reason
    private _veh = objectParent player;
    if !(isNull _veh) then
    {
        private _vehType = typeOf _veh;
        if (!(_vehType in undercoverVehicles)) exitWith
        {
            _reason = "VNoCivil"
        };

        if (_veh getVariable ["A3A_reported", false]) exitWith
        {
            _reason = "VCompromised"
        };

        if (_veh getVariable ["SA_Tow_Ropes", []] isNotEqualTo []) exitWith
        {
            _reason = "VTowRopes"
        };

        if (A3A_hasACE) then
        {
            if (((position player nearObjects["DemoCharge_Remote_Ammo", 5]) select 0) mineDetectedBy Occupants) exitWith
            {
                _reason = "SpotBombTruck";
            };
            if (((position player nearObjects["SatchelCharge_Remote_Ammo", 5]) select 0) mineDetectedBy Occupants) exitWith
            {
                _reason = "SpotBombTruck";
            };
        };

        if(_reason != "") exitWith {};

        if(_veh getVariable ["NoFlyZoneDetected", ""] != "") exitWith
        {
            _reason = "NoFly";
        };

        if (_vehType isKindOf "Land") then
        {
            if (!(isOnRoad position _veh) && {count (_veh nearRoads 50) == 0}) then
            {
                private _checkOccDistance = 75 * aggressionLevelOccupants;
                private _checkInvDistance = 100 * aggressionLevelInvaders;

                if (((units Occupants) inAreaArray [_veh, _checkOccDistance, _checkOccDistance]) select {_x knowsAbout _veh > 1 && _x call A3A_fnc_canFight} isNotEqualTo []) then
                {
                    _reason = "Highway";
                };
                if (((units Invaders) inAreaArray [_veh, _checkInvDistance, _checkInvDistance]) select {_x knowsAbout _veh > 1 && _x call A3A_fnc_canFight} isNotEqualTo []) then
                {
                    _reason = "Highway";
                };
            };

            //handgun is fine
            if ( player getVariable["compromised",-1] > 0 || _aiming || _visiblePrimary || (secondaryWeapon player != "")  || (vest player != "") || _armoredHeadgear || (!_allowedUniform) || (hmd player != "") ) exitWith
            {
                if ({((side _x == Invaders) or (side _x == Occupants)) and (_x knowsAbout _veh > 2) and (_x distance _veh < 75) and _x call A3A_fnc_canFight} count allUnits > 0) then
                {
                    _reason = "clothes2";
                };
            };
        };
    }
    else
    {
        if (_healingTarget != objNull && {side _healingTarget != civilian && {_healingTarget isKindOf "Man"}}) exitWith
        {
            if ({((side _x == Invaders) or(side _x == Occupants)) and (_x knowsAbout player > 1.4) and (_x distance player < 350) and _x call A3A_fnc_canFight} count allUnits > 0) then
            {
                _reason = "BadMedic2";
            }
            else
            {
                _reason = "BadMedic";
            };
        };
        if ((primaryWeapon player != "") || (secondaryWeapon player != "") || (handgunWeapon player != "") || (vest player != "") || _armoredHeadgear || (!_allowedUniform) || (hmd player != "") ) exitWith
        {
            if ({((side _x == Invaders) or (side _x == Occupants)) and (_x knowsAbout player > 1.4) and (_x distance player < 350) and _x call A3A_fnc_canFight} count allUnits > 0) then
            {
                _reason = "clothes2"
            }
            else
            {
                _reason = "clothes"
            };
        };
        if (dateToNumber date < (player getVariable ["compromised", 0])) exitWith
        {
            _reason = "Compromised";
        };
        if (!isNull (player getVariable ["SA_Tow_Ropes_Vehicle", objNull])) exitWith
        {
            _reason = "TowRopes";
        };
    };
    if (_reason != "") exitWith {};

    // Don't do location checks on air vehicles. AirspaceControl handles that.
    if (!isNull _veh and { _veh isKindOf "Air" }) then { continue };

    private _base = [_secureBases, player] call BIS_fnc_nearestPosition;
    // If player is _onDetectionMarker, the detectionArea they are in should also be less than 700m away from _base (which should only be an airport).
    private _onDetectionMarker = detectionAreas findIf {player inArea _x && (_base in airportsX) && {((getMarkerPos _x) distance2D (getMarkerPos _base)) <= 700}} != -1;
    private _onBaseMarker = player inArea _base;
    private _baseSide = sidesX getVariable [_base, sideUnknown];
    private _enemyPresent = false;
    if (_onBaseMarker && _personnelCheckCd <= 0) then {
        _personnelCheckCd = 10;
        _enemyPresent = (allUnits findIf {
            alive _x
            && {_x inArea _base}
            && {side group _x == _baseSide}
            && {[_x] call A3A_fnc_canFight}
            && {!(_x getVariable ["incapacitated", false])}
            && {!(_x getVariable ["surrendered", false])}
            && {!captive _x}
        }) != -1;
    };
    
    _personnelCheckCd = _personnelCheckCd - 1;

    if ((_onBaseMarker || _onDetectionMarker) && (_baseSide != teamPlayer) && (_base != _lastBaseInside) && _enemyPresent) then
    {
        if (_base in airportsX || _onDetectionMarker) exitWith
        {
            _reason = "Airport";
        };
        if ("outpost" in _base || _onDetectionMarker) exitWith
        {
            _reason = "Outpost";
        };
        if ("seaport" in _base || _onDetectionMarker) exitWith
        {
            _reason = "Seaport";
        };
        if ("milbase" in _base || _onDetectionMarker) exitWith
        {
            _reason = "Milbase";
        };

        //checkpoints do contraband checks
        private _luggage = vehicle player;
        {
            if (!(_x in ["ToolKit","Medikit","FirstAidKit"])) exitWith { _reason = "Roadblock2"; };
        } forEach itemCargo _luggage;

        if ((weaponCargo _luggage) isNotEqualTo [] or (magazineCargo _luggage) isNotEqualTo []) then {
            _reason = "Roadblock";
        };

        {
            if ((weaponCargo _x) isNotEqualTo [] or (magazineCargo _x) isNotEqualTo [] or _x getVariable ["hiddenLoadout", false]) exitWith {
                _reason = "Roadblock";
            };
        } forEach crew _luggage;
        
        
        private _roadblocks = controlsX select {isOnRoad(getMarkerPos _x)};
        if (!(_base in _roadblocks || _onDetectionMarker)) then {
            _reason = ""; //can't catch if not a roadblock
        };

        _lastBaseInside = _base; // Don't check this base again once we passed the check
    };
};

if (captive player) then
{
    player setCaptive false;
};

if !(isNull (objectParent player)) then
{
    {
        if (isPlayer _x) then
        {
            [_x, false] remoteExec["setCaptive", _x];
        }
    } forEach((assignedCargo(vehicle player)) + (crew(vehicle player)) - [player]);
};

private _layer = ["A3A_infoCenter"] call BIS_fnc_rscLayer;
[localize "STR_A3A_fn_undercover_goUn_off", 0, 0, 4, 0, 0, _layer] spawn bis_fnc_dynamicText;
[] spawn A3A_fnc_statistics;

switch (_reason) do
{
    case "Reported":
    {
        ["Undercover", localize "STR_A3A_fn_undercover_goUn_reported"] call A3A_fnc_customHint;
        if (vehicle player != player) then
        {
            (objectParent player) setVariable ["A3A_reported", true, true];
        }
        else
        {
            player setVariable["compromised", (dateToNumber[date select 0, date select 1, date select 2, date select 3, (date select 4) + 30])];
        };
    };
    case "VNoCivil":
    {
        ["Undercover", localize "STR_A3A_fn_undercover_goUn_entered_veh1"] call A3A_fnc_customHint;
    };
    case "VCompromised":
    {
        ["Undercover", localize "STR_A3A_fn_undercover_goUn_entered_veh2"] call A3A_fnc_customHint;
    };
    case "VTowRopes":
    {
        ["Undercover", localize "STR_A3A_fn_undercover_goUn_no_towrope1"] call A3A_fnc_customHint;
    };
    case "TowRopes":
    {
        ["Undercover", localize "STR_A3A_fn_undercover_goUn_no_towrope2"] call A3A_fnc_customHint;
    };
    case "SpotBombTruck":
    {
        ["Undercover", localize "STR_A3A_fn_undercover_goUn_no_explo"] call A3A_fnc_customHint;
        (objectParent player) setVariable ["A3A_reported", true, true];
    };
    case "Highway":
    {
        ["Undercover", localize "STR_A3A_fn_undercover_goUn_no_distance"] call A3A_fnc_customHint;
    };
    case "clothes":
    {
        ["Undercover", localize "STR_A3A_fn_undercover_goUn_no_reason_1"] call A3A_fnc_customHint;
    };
    case "clothes2":
    {
        ["Undercover", localize "STR_A3A_fn_undercover_goUn_no_reason_2"] call A3A_fnc_customHint;
        player setVariable["compromised", dateToNumber[date select 0, date select 1, date select 2, date select 3, (date select 4) + 30]];
        if (objectParent player != player) then {
            (objectParent player) setVariable ["A3A_reported", true, true];
        };
    };
    case "BadMedic":
    {
        ["Undercover", localize "STR_A3A_fn_undercover_goUn_no_reason_3"] call A3A_fnc_customHint;
    };
    case "BadMedic2":
    {
        ["Undercover", localize "STR_A3A_fn_undercover_goUn_no_reason_4"] call A3A_fnc_customHint;
        player setVariable["compromised", dateToNumber[date select 0, date select 1, date select 2, date select 3, (date select 4) + 30]];
    };
    case "Compromised":
    {
        ["Undercover", localize "STR_A3A_fn_undercover_goUn_leftveh"] call A3A_fnc_customHint;
    };
    case "Airport"; case "Roadblock"; case "Roadblock2"; case "Outpost"; case "Seaport"; case "Milbase":
    {
        private _text = switch (_reason) do {
            case "Airport": {localize "STR_A3A_fn_undercover_goUn_trespass"};
            case "Outpost": {localize "STR_A3A_fn_undercover_goUn_detect_outp"};
            case "Milbase": {localize"STR_A3A_fn_undercover_goUn_detect_milb"};
            case "Seaport": {localize "STR_A3A_fn_undercover_goUn_detect_outp"};
            case "Roadblock": {localize "STR_A3A_fn_undercover_goUn_detect_roadb"};
            case "Roadblock2": {localize "STR_A3A_fn_undercover_goUn_detect_roadb_contraband"};
        };
        ["Undercover", _text] call A3A_fnc_customHint;

        if !(isNull objectParent player) then
        {
            (objectParent player) setVariable ["A3A_reported", true, true];
        }
        else
        {
            player setVariable["compromised", (dateToNumber[date select 0, date select 1, date select 2, date select 3, (date select 4) + 30])];
        };
    };
    case "NoFly":
    {
        private _veh = objectParent player;
        private _detectedBy = _veh getVariable "NoFlyZoneDetected";
        ["Undercover", format [localize "STR_A3A_fn_undercover_goUn_detect_airspace", [_detectedBy] call A3A_fnc_localizar]] call A3A_fnc_customHint;
        _veh setVariable ["A3A_reported", true, true];
        _veh setVariable ["NoFlyZoneDetected", nil, true];
    };
    default
    {
        Error_1("Unknown reason given, was %1", _reason);
        ["Undercover", "STR_A3A_fn_undercover_goUn_Error"] call A3A_fnc_customHint;
    };
};

[CBA_EVENT_CLIENT_UNDERCOVER_CHANGED, [false, _reason]] call FUNCMAIN(triggerLocalEvent);

nil;
