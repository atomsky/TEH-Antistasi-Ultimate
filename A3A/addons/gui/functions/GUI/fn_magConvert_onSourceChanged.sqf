#include "..\..\dialogues\ids.inc"
#include "..\..\script_component.hpp"
FIX_LINE_NUMBERS()

/*
  Called from onLBSelChanged as: _this call A3A_fnc_magConvert_onSourceChanged;
  _this is: [_ctrl, _selIndex]
*/
params ["_ctrl", "_selIndex"];

// parent display and target control
private _disp    = ctrlParent _ctrl;
private _tgtCtrl = _disp displayCtrl A3A_IDC_MAGCONVERT_TARGET;

// validate selection
if (_selIndex < 0) exitWith { lbClear _tgtCtrl; };

// read selected source mag class (uses lbData)
private _srcClass = _ctrl lbData _selIndex;
if (_srcClass isEqualTo "") exitWith { lbClear _tgtCtrl; };

// get model from CfgMagazines
private _model = getText (configFile >> "CfgMagazines" >> _srcClass >> "model");

// clear target combo
lbClear _tgtCtrl;

// nothing to do if no model
if (_model isEqualTo "") exitWith {};

// brute-force scan all magazine classes and add those with same model
private _allMags = "true" configClasses (configFile >> "CfgMagazines");
{
    private _magClass = configName _x;
    private _magModel = getText (_x >> "model");

    if (_magModel isEqualTo _model && { _magModel != "\A3\weapons_F\ammo\mag_univ.p3d" }) then {
        private _dispName = getText (_x >> "displayName");
        if (_dispName isEqualTo "") then { _dispName = _magClass; };

        private _idx = _tgtCtrl lbAdd _dispName;
        _tgtCtrl lbSetData [_idx, _magClass];
    };
} forEach _allMags;

// add "Throw away" option
private _idx = _tgtCtrl lbAdd localize "STR_TEH_MAG_CONVERT_DISCARD_OPTION";
_tgtCtrl lbSetData [_idx, "A3A_TRASH"];

// auto-select first entry if present
if ((lbSize _tgtCtrl) > 0) then { _tgtCtrl lbSetCurSel 0; };
