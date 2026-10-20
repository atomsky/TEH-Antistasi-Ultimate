#include "..\..\dialogues\ids.inc"
#include "..\..\script_component.hpp"
#include "\A3\Ui_f\hpp\defineResinclDesign.inc"

FIX_LINE_NUMBERS()

/*
  Handles click on "Convert" button
*/

disableSerialization;

private _disp    = findDisplay A3A_IDD_MAGCONVERTDIALOG;
private _srcCtrl = _disp displayCtrl A3A_IDC_MAGCONVERT_SOURCE;
private _tgtCtrl = _disp displayCtrl A3A_IDC_MAGCONVERT_TARGET;
private _amtCtrl = _disp displayCtrl A3A_IDC_MAGCONVERT_AMOUNT;

// validate selections
private _srcSel = lbCurSel _srcCtrl;
private _tgtSel = lbCurSel _tgtCtrl;
private _selectedAmount = parseNumber(_amtCtrl lbData (lbCurSel _amtCtrl));

if (_srcSel < 0 || _tgtSel < 0) exitWith { systemChat localize "STR_TEH_MAG_CONVERT_SELECT_BOTH"; };

private _srcClass = _srcCtrl lbData _srcSel;
private _tgtClass = _tgtCtrl lbData _tgtSel;

// remove source mags from jna_dataList
private _magIdx = jna_DataList # IDC_RSCDISPLAYARSENAL_TAB_CARGOMAGALL findIf {_x # 0 isEqualTo _srcClass };
private _count = 0;
if (_magIdx >= 0) then {
    _count = (jna_DataList # IDC_RSCDISPLAYARSENAL_TAB_CARGOMAGALL # _magIdx # 1);
};

if (_count == 0) exitWith { systemChat format [localize "STR_TEH_MAG_CONVERT_SOURCE_UNAVAILABLE",_srcClass]; };

if (_selectedAmount != -1) then {
  if (_count == -1) then {
    _count = _selectedAmount;
  } else {
    _count = _count min _selectedAmount;
  };
};

[IDC_RSCDISPLAYARSENAL_TAB_CARGOMAGALL,_srcClass,_count] call JN_fnc_arsenal_removeItem;

// add new target mags unless "Throw away"
_amountStr = if (_count == -1) then { localize "STR_TEH_MAG_CONVERT_ALL"} else {str _count};
if !(_tgtClass isEqualTo "A3A_TRASH") then {
    [IDC_RSCDISPLAYARSENAL_TAB_CARGOMAGALL,_tgtClass,_count] call JN_fnc_arsenal_addItem;
    systemChat format [localize "STR_TEH_MAG_CONVERT_SUCCESS", _amountStr, _srcClass, _tgtClass];
} else {
    systemChat format [localize "STR_TEH_MAG_CONVERT_DISCARDED", _amountStr, _srcClass, _tgtClass];
};


