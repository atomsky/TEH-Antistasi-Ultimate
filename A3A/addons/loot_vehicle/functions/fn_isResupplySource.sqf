/* Only faction-defined ammo trucks can offer quick resupply. */
params ["_source"];
private _class = typeOf _source;
_class in (A3A_faction_occ get "vehiclesAmmoTrucks")
    || {_class in (A3A_faction_inv get "vehiclesAmmoTrucks")}
