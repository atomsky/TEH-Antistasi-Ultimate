/* this procedure is called when "Quick Resupply" (or however it's named) is used on the Arsenal box
   adds missing ACE medicine (doesn't replace existing)
   reloads magazines in the inventory (by technically replacing with new mags) */
#include "tehBulletPile.inc"
params ["_veh"];

cache = {
    params ["_map","_key","_value"];
    private _current = _map getOrDefault [_key, 0];
    _map set [_key, _current + _value];
};

//Tally the meds.
private _meds = createHashMapFromArray [
["ACE_morphine", 2],
["ACE_epinephrine", 2],
["ACE_fieldDressing", 8],
["ACE_splint", 2],
["ACE_salineIV_500", 1],
["ACE_plasmaIV_500", 1],
["ACE_bloodIV_500", 1]];

{
	switch (true) do {
		case (_x in _meds): {[_meds, _x, -1] call cache;};
		case (_x in ["ACE_fieldDressing","ACE_packingBandage","ACE_elasticBandage","ACE_quikclot"]): { [_meds, "ACE_fieldDressing", -1] call cache; };
		case ("salineIV" in _x): { [_meds,"ACE_salineIV_500",-1] call cache;};
		case ("plasmaIV" in _x): { [_meds, "ACE_plasmaIV_500", -1] call cache;};
		case ("bloodIV" in _x): { [_meds,"ACE_bloodIV_500", -1] };
	};
} forEach itemCargo player;

if (TEH_civStart isNotEqualTo 1 || tierWar > 1) then {
    {
        for "_i" from 1 to (_meds get _x) do {
            player addItem _x;
        };
    } forEach _meds;
};

//tallies
private _magBox = createHashMap;
private _ammoBox = createHashMap;
private _needed = createHashMap;

private _disposableMagazines = ["CBA_FakeLauncherMagazine"];
{
    private _mag = (compatibleMagazines (configName _x)) select 0;
    if (_mag != "") then { _disposableMagazines pushBackUnique _mag; };
} forEach configProperties [configFile >> "CBA_DisposableLaunchers", "isArray _x"];

private _invNonEmptyMags = +magazinesAmmo player; //array copy to avoid iteration issues
private _loadedMags = (magazinesAmmoFull player) select { _x#2 };

//tally needed ammo to _needed
{
    if !(_x#0 in _disposableMagazines) then {
        private _ammoName = getText(configFile >> "CfgMagazines" >> _x#0 >> "ammo");
        if (_ammoName != "") then {
            private _cap = getNumber (configfile >> "CfgMagazines" >> _x#0 >> "count");
            [_needed, _ammoName,_cap] call cache;
        };
    };
} forEach _loadedMags;

{
    if !(_x in _disposableMagazines) then {
        private _ammoName = getText(configFile >> "CfgMagazines" >> _x >> "ammo");
        if (_ammoName != "") then {
            private _cap = getNumber (configfile >> "CfgMagazines" >> _x >> "count");
            [_needed,_ammoName,_cap] call cache;
        };
    };
} forEach (magazineCargo player);

//tally loaded ammo to _ammoBox
{
    private _oldMag = _x#0;
    if !(_oldMag in _disposableMagazines) then {
        private _ammoName = getText(configFile >> "CfgMagazines" >> _oldMag >> "ammo");
        if (_ammoName != "") then {
            [_ammoBox,_ammoName,_x#1] call cache;
        };
    };
} forEach _invNonEmptyMags + _loadedMags;

//check what we need from the arsenal
private _enoughAmmo = true;
{
    private _neededAmmo = _needed get _x;
    private _loaded = _ammoBox getOrDefault [_x,0];
    private _ammoName = _x;
    private _ammoIdx = jna_dataList # IDC_RSCDISPLAYARSENAL_TAB_CARGOBULLET findif { _x # 0 isEqualTo _ammoName};
    private _ammoBin = 0;
    if (_ammoIdx > -1) then {
        _ammoBin = jna_dataList # IDC_RSCDISPLAYARSENAL_TAB_CARGOBULLET # _ammoIdx # 1;
    };

    if (_neededAmmo - _loaded > _ammoBin && _ammoBin >= 0) then {
        systemChat format ["Not enough %1 ammo to reload all magazines", _x];
        _enoughAmmo = false;
    };
} forEach _needed;

if (not _enoughAmmo) exitWith {["Quick Resupply", "Not enough ammo in the arsenal, try to repack manually."] call A3A_fnc_customHint;};

//count mags in the inventory containers (not loaded)
private _allmags = +magazineCargo player;
{
   [_magBox,_x,1] call cache;
   player removeMagazine _x;
} forEach _allmags;

// PROCESS LOADED MAGS
{        
    private _loadedMag = _x#0;
    //_x#3 is weapon slot of sort
    switch (_x#3) do {
        case 1: {
            player removePrimaryWeaponItem _loadedMag;
            player addPrimaryWeaponItem _loadedMag;
        };
        case 2: {
            player removeHandgunItem _loadedMag;
            player addHandgunItem _loadedMag;
        };
    };
} forEach _loadedMags;

//reload inventory mags
{
    player addMagazine _x; 
} forEach _allmags;

//commit difference from the arsenal
{
    private _neededAmmo = _needed get _x;
    private _loaded = _ammoBox getOrDefault [_x,0];
    [IDC_RSCDISPLAYARSENAL_TAB_CARGOBULLET,_x,(_neededAmmo - _loaded)] call JN_fnc_arsenal_removeItem;

} forEach _needed;

if (isNil "_veh") then {
    _veh = [vehicle player, objNull] select (vehicle player == player);
};

if (isNull _veh || _veh == player) exitWith {};

[_veh] call A3A_fnc_empty;
waitUntil {sleep 0.1; count itemCargo _veh == 0 };

[_veh] remoteExec ['JN_fnc_arsenal_turretLoad', 2];

//Loading starter kit
_primarymag = (primaryWeaponMagazine player) select 0;

if (_primarymag != "") then {
    _ammo = getText (configfile >> "CfgMagazines" >> _primarymag >> "ammo");
    _bullets = 600;
    _ammocount = getNumber (configfile >> "CfgMagazines" >> _primarymag >> "count");
    _magcount = floor (_bullets / _ammocount);
    _bullets = _magcount * _ammocount;
    _magAvailable = [jna_dataList select IDC_RSCDISPLAYARSENAL_TAB_CARGOMAGALL, _primarymag] call jn_fnc_arsenal_itemCount;
    _bulAvailable = [jna_dataList select IDC_RSCDISPLAYARSENAL_TAB_CARGOBULLET, _ammo] call jn_fnc_arsenal_itemCount;
    if ((_magAvailable < 0 || _magAvailable >= _magcount) && (_bulAvailable < 0 || _bulAvailable >= _bullets)) then {
        [IDC_RSCDISPLAYARSENAL_TAB_CARGOMAGALL, _primarymag, _magcount] call JN_fnc_arsenal_removeItem;
        [IDC_RSCDISPLAYARSENAL_TAB_CARGOBULLET, _ammo, _bullets] call JN_fnc_arsenal_removeItem;
        _veh addMagazineCargoGlobal [_primarymag, _magcount];
    };
};

if (TEH_civStart isNotEqualTo 1 || tierWar > 1) then {
    _veh addItemCargoGlobal ["Toolkit", 1];
    _veh addItemCargoGlobal ["MiniGrenade", 10];
    _veh addItemCargoGlobal ["SmokeShell", 10];
};

if (A3A_hasACEMedical) then {
    if (TEH_civStart isNotEqualTo 1 || tierWar > 1) then {
        _veh addItemCargoGlobal ["ACE_fieldDressing",32];

        _veh addItemCargoGlobal ["ACE_morphine",10];
        _veh addItemCargoGlobal ["ACE_epinephrine",10];
        _veh addItemCargoGlobal ["ACE_adenosine",5];

        _veh addItemCargoGlobal ["ACE_plasmaIV_500",5];
        _veh addItemCargoGlobal ["ACE_salineIV_500",5];
        _veh addItemCargoGlobal ["ACE_bloodIV_500",5];

        _veh addItemCargoGlobal ["ACE_tourniquet",5];
        _veh addItemCargoGlobal ["ACE_splint",5];
    };
} else {
    if (TEH_civStart isNotEqualTo 1 || tierWar > 1) then {
        _veh addItemCargoGlobal ["Medikit", 1];
        _veh addItemCargoGlobal ["FirstAidKit",12];
    };
};

_veh setPlateNumber (name player);

if ((_veh isKindOf "Tank") || (_veh isKindOf "Wheeled_APC_F")) then {

    _veh addEventHandler ["HandleDamage", {
        params ["_veh", "_selection", "_damage", "_source", "_projectile", "_hitIndex"];

        if (_damage isEqualTo 0) exitWith { 0 };
        _dmg = damage _veh;
        if (_dmg < 0.51) exitWith { _damage };
        if (_dmg >= 1) then {
            if ((random 1) < 0.5) exitWith { _damage };
        };

        waitUntil { _veh getVariable["canDamage",true]; }; 

        private _hpData = getAllHitPointsDamage _veh; 
        private _hpNames = _hpData select 1;
        private _hpValues = []+(_hpData select 2); 

        _veh setVariable ["canDamage", false]; 
        _veh setDamage 0.51; 

        { 
            private _val = _x; 
            _veh setHit [_hpNames select _forEachIndex, _val]; 
        } forEach _hpValues; 
        
        _veh setVariable["canDamage", true]; 

        //continue damage le component.
        _damage;
    }];

    systemChat "Tankiness is over 9000";
};