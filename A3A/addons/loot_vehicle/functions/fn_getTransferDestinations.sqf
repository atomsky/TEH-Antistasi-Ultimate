/* The old ACE submenu listed nearby vehicles with inventory capacity. */
params ["_source"];
(nearestObjects [_source, ["LandVehicle", "Air", "Ship"], LootVehicleDistance]) select {
    _x != _source
    && {([_source, _x] call teh_actions_fnc_distanceToTarget) < LootVehicleDistance}
    && {
        private _cfg = configOf _x;
        (getNumber (_cfg >> "transportMaxBackpacks")
            + getNumber (_cfg >> "transportMaxMagazines")
            + getNumber (_cfg >> "transportMaxWeapons")) > 0
    }
}
