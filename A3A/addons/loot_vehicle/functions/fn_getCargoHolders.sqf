/* Nearby cargo recipients formerly drawn from ACE cargo's holder-type list. */
params ["_origin", "_source"];
(nearestObjects [
    _origin,
    ["Car", "Air", "Tank", "Ship", "Cargo_base_F", "Land_PaperBox_closed_F"],
    LootVehicleDistance
]) select {
    _x != _source && {([_source, _x] call teh_actions_fnc_distanceToTarget) < LootVehicleDistance}
}
