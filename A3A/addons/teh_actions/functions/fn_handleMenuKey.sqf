#include "\a3\ui_f\hpp\defineDIKCodes.inc"

/* Enter or Space activates the current row (the first row on open). */
params ["_display", "_key"];
if !(_key in [DIK_RETURN, DIK_NUMPADENTER, DIK_SPACE]) exitWith {false};
if (isNull (_display displayCtrl 96002)) exitWith {false};

[] call teh_actions_fnc_executeInteraction;
true
