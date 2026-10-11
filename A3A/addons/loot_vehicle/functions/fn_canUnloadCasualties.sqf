/* Show only when an occupied vehicle has no crew member able to fight. */
params ["_vehicle"];
if (isNull _vehicle || {isNil "A3A_fnc_canFight"}) exitWith {false};

private _crew = crew _vehicle;
!(_crew isEqualTo []) && {
    _crew findIf {alive _x && {[_x] call A3A_fnc_canFight}} == -1
}
