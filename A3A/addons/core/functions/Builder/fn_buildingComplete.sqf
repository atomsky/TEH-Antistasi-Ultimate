#include "..\..\script_component.hpp"
FIX_LINE_NUMBERS()

/*
Description:
    Server-side function to complete or cancel a construction

Environment: Server, unscheduled
Arguments:
    1. <object> Plank object to complete construction for
    2. <bool> True if completed, false if cancelled
*/

params ["_target", ["_finished", true]];

//remove from list
A3A_unbuiltObjects deleteAt (A3A_unbuiltObjects find _target);
publicVariable "A3A_unbuiltObjects";

private _buildClass = _target getVariable "A3A_build_class";
private _buildDir = _target getVariable "A3A_build_dir";
private _buildPos = _target getVariable "A3A_build_pos";
private _buildPrice = _target getVariable["A3A_build_price", 10];
private _repairObj = _target getVariable["A3A_build_repairObj", objNull];

deleteVehicle _target; //delete the plank object

private _runCallback = {
    params[["_object", objNull, [objNull]], ["_callbackName", "", [""]], ["_params", [], [[]]]];

    if !assert(!isNull _object) exitWith {};

    if isText(configOf _object >> _callbackName) then {
        //diag_log format["A3A_fnc_buildingComplete(%1): calling %2 with params %3", typeOf _object, _callbackName, _params];
        ([_object] + _params) call compile getText(configOf _object >> _callbackName);
    };

    nil;
};

// Cancel case
if (!_finished) exitWith {
    if (_buildPrice > 0) then {
        [0, _buildPrice] spawn A3A_fnc_resourcesFIA;
    };
};

// Repair case, just call the repair function
if (!isNull _repairObj) exitWith {
    _repairObj call A3A_fnc_repairRuinedBuilding;
    [_repairObj, QGVAR(onBuildingRepaired)] call _runCallback;
};

// Construction case, spawn the building
private _building = createVehicle [_buildClass, [0,0,0], [], 0, "CAN_COLLIDE"];
_building setPosWorld _buildPos;
_building setVectorDirAndUp _buildDir;
if (typeOf _building  in ["A3AU_RebHelipad_Square_F","A3AU_RebHelipad_Circle_F"]) then {
    [_building] call A3A_fnc_terrainCleaner;
};

if (_building isKindOf "Land_Scaffolding_New_F") then {
	_scaffold = _building;
	[_scaffold, [
		localize "STR_TEH_ACTION_ALIGN_PLATFORMS",                             // Action title
		{
			params ["_target", "_caller"];
			[_target] call A3A_fnc_alignPlatforms;
		},
		nil,                                        // Arguments
		4,                                          // Priority
		false,                                      // ShowWindow
		true,                                       // HideOnUse
		"",                                         // Shortcut
		"(isPlayer _this) && (_this == vehicle _this)",  // on foot, player only
		10                                    // Distance to appear
	]] remoteExec ["addAction", 0, _scaffold];
};

_building setVariable ["A3A_building", true, true];            // Used to identify removable buildings

A3A_buildingsToSave pushBack _building; ///could move terrain smoothing here
publicVariable "A3A_buildingsToSave";

// Allowing flagpole construction is probably not a good idea due to how markerChange handles flags atm
if (_className isEqualTo (A3A_faction_reb get "flag")) then {
    _building setFlagTexture (A3A_faction_reb get "flagTexture");
};

[_building, QGVAR(onBuildingCompleted)] call _runCallback;

nil;
