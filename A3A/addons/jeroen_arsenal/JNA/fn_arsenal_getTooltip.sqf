#include "\A3\Ui_f\hpp\defineResinclDesign.inc"
#include "tehBulletPile.inc"

params ["_item"];

private _itemType = _item call BIS_fnc_itemType;
_itemType params ["_itemTypeCategory", "_itemTypeName"];

// Cache only config-derived item properties. Arsenal ammunition stock is dynamic.
if !(_item in jna_tooltips) then {
    private _line = {
        params ["_label", "_value"];
        format ["%1: %2", _label, _value]
    };

    // Modded coefficient fields may be strings such as "0.7f".
    private _configScalarText = {
        params ["_cfg"];

        if (isNumber _cfg) exitWith { str (getNumber _cfg) };
        if (isText _cfg) exitWith {
            private _value = getText _cfg;
            if (_value != "" && {toLower (_value select [(count _value) - 1, 1]) == "f"}) then {
                _value select [0, (count _value) - 1]
            } else {
                _value
            }
        };
        ""
    };

    private _partLabel = {
        params ["_part"];
        switch (_part) do {
            case "Abdomen": { localize "STR_TEH_STATS_PART_ABDOMEN" };
            case "Arms": { localize "STR_TEH_STATS_PART_ARMS" };
            case "Chest": { localize "STR_TEH_STATS_PART_CHEST" };
            case "Diaphragm": { localize "STR_TEH_STATS_PART_DIAPHRAGM" };
            case "Face": { localize "STR_TEH_STATS_PART_FACE" };
            case "Hands": { localize "STR_TEH_STATS_PART_HANDS" };
            case "Head": { localize "STR_TEH_STATS_PART_HEAD" };
            case "Legs": { localize "STR_TEH_STATS_PART_LEGS" };
            case "Neck": { localize "STR_TEH_STATS_PART_NECK" };
            case "Pelvis": { localize "STR_TEH_STATS_PART_PELVIS" };
            default { _part };
        }
    };

    private _protectionValue = {
        params ["_armor", "_passthrough"];
        str _armor + " (" + str (_passthrough * 100) + "% " + localize "STR_TEH_STATS_PASSTHROUGH" + ")"
    };

    // Shared CfgAmmo section for launchers and explosive magazines.
    private _ammoStats = {
        params ["_ammoName"];
        private _ammoCfg = configFile >> "CfgAmmo" >> _ammoName;
        private _subName = getText (_ammoCfg >> "submunitionAmmo");
        private _subCfg = configFile >> "CfgAmmo" >> _subName;

        [
            [localize "STR_TEH_STATS_DIRECT_DAMAGE", str (getNumber (_ammoCfg >> "hit"))] call _line,
            [localize "STR_TEH_STATS_DIRECT_PENETRATION", str (getNumber (_ammoCfg >> "caliber"))] call _line,
            [localize "STR_TEH_STATS_SUBMUNITION_DAMAGE", str (getNumber (_subCfg >> "hit"))] call _line,
            [localize "STR_TEH_STATS_SUBMUNITION_PENETRATION", str ([getNumber (_subCfg >> "caliber"), 1] call BIS_fnc_cutDecimals)] call _line,
            "",
            [localize "STR_TEH_STATS_SPLASH_DAMAGE", str (getNumber (_ammoCfg >> "indirectHit"))] call _line,
            [localize "STR_TEH_STATS_SPLASH_RADIUS", str (getNumber (_ammoCfg >> "indirectHitRange")) + " m"] call _line,
            [localize "STR_TEH_STATS_MAX_SPEED", str (getNumber (_ammoCfg >> "maxSpeed")) + " m/s"] call _line
        ]
    };

    private _lines = [
        [localize "STR_TEH_STATS_ITEM_CODE", _item] call _line
    ];

    switch (_itemTypeName) do {
        case "AssaultRifle";
        case "MachineGun";
        case "SniperRifle";
        case "Shotgun";
        case "Rifle";
        case "SubmachineGun";
        case "Handgun": {
            _lines pushBack "";
            private _weaponCfg = configFile >> "CfgWeapons" >> _item;
            private _barrelCfg = _weaponCfg >> "ACE_barrelLength";

            if (isNumber _barrelCfg) then {
                private _barrelMm = getNumber _barrelCfg;
                _lines pushBack ([
                    localize "STR_TEH_STATS_BARREL_LENGTH",
                    str _barrelMm + " mm / " + str ([_barrelMm / 25.4, 1] call BIS_fnc_cutDecimals) + " in"
                ] call _line);
            } else {
                _lines pushBack ([localize "STR_TEH_STATS_BARREL_LENGTH", localize "STR_TEH_STATS_NEEDS_ACE"] call _line);
            };

            private _magazines = getArray (_weaponCfg >> "magazines");
            private _magName = if (_magazines isEqualTo []) then { "" } else { _magazines # 0 };
            private _magDisplayName = getText (configFile >> "CfgMagazines" >> _magName >> "displayName");
            private _dexterity = getNumber (_weaponCfg >> "dexterity") * 5;

            _lines pushBack ([localize "STR_TEH_STATS_DEFAULT_AMMO", _magDisplayName] call _line);
            _lines pushBack ([localize "STR_TEH_STATS_HANDLING", str _dexterity + "/10"] call _line);
        };

        case "Launcher";
        case "MissileLauncher";
        case "RocketLauncher": {
            _lines pushBack "";
            private _weaponCfg = configFile >> "CfgWeapons" >> _item;
            private _magazines = getArray (_weaponCfg >> "magazines");
            private _magName = if (_magazines isEqualTo []) then { "" } else { _magazines # 0 };

            if (_magName == "CBA_FakeLauncherMagazine") then {
                _lines pushBack (localize "STR_TEH_STATS_NO_DATA");
            } else {
                private _ammoName = getText (configFile >> "CfgMagazines" >> _magName >> "ammo");
                _lines append ([_ammoName] call _ammoStats);
            };

            private _lockTime = getNumber (_weaponCfg >> "weaponLockDelay");
            if (_lockTime > 0) then {
                _lines pushBack "";
                _lines pushBack ([localize "STR_TEH_STATS_LOCK_TIME", str _lockTime + " s"] call _line);
            };
        };

        case "Headgear";
        case "Vest": {
            private _itemInfoCfg = configFile >> "CfgWeapons" >> _item >> "ItemInfo";
            private _hitpoints = configProperties [_itemInfoCfg >> "HitpointsProtectionInfo", "isClass _x", true];
            private _hasProtection = false;

            if (_itemTypeName == "Vest") then { _lines pushBack "" };

            {
                private _part = configName _x;
                if (_part != "Body") then {
                    _lines pushBack ([
                        [_part] call _partLabel,
                        [getNumber (_x >> "armor"), getNumber (_x >> "passthrough")] call _protectionValue
                    ] call _line);
                    _hasProtection = true;
                };
            } forEach _hitpoints;

            if (_itemTypeName == "Vest") then {
                if (_hasProtection) then { _lines pushBack "" };
                private _containerClass = getText (_itemInfoCfg >> "containerClass");
                private _capacity = getNumber (configFile >> "CfgVehicles" >> _containerClass >> "maximumLoad");
                _lines pushBack ([localize "STR_TEH_STATS_CAPACITY", str _capacity] call _line);
            };
        };

        case "Uniform": {
            _lines pushBack "";
            private _itemInfoCfg = configFile >> "CfgWeapons" >> _item >> "ItemInfo";
            private _uniformClass = getText (_itemInfoCfg >> "uniformClass");
            private _hitpointsCfg = configFile >> "CfgVehicles" >> _uniformClass >> "HitPoints";
            private _allowed = [
                "HitAbdomen", "HitArms", "HitChest", "HitDiaphragm", "HitFace",
                "HitHands", "HitHead", "HitLegs", "HitNeck", "HitPelvis"
            ];
            private _hasProtection = false;

            {
                private _part = configName _x;
                if (_part in _allowed) then {
                    _lines pushBack ([
                        [_part select [3]] call _partLabel,
                        [getNumber (_x >> "armor"), getNumber (_x >> "passthrough")] call _protectionValue
                    ] call _line);
                    _hasProtection = true;
                };
            } forEach configProperties [_hitpointsCfg, "isClass _x", true];

            if (_hasProtection) then { _lines pushBack "" };
            private _containerClass = getText (_itemInfoCfg >> "containerClass");
            private _capacity = getNumber (configFile >> "CfgVehicles" >> _containerClass >> "maximumLoad");
            _lines pushBack ([localize "STR_TEH_STATS_CAPACITY", str _capacity] call _line);
        };

        case "Backpack": {
            _lines pushBack "";
            private _capacity = getNumber (configFile >> "CfgVehicles" >> _item >> "maximumLoad");
            _lines pushBack ([localize "STR_TEH_STATS_CAPACITY", str _capacity] call _line);
        };

        case "AccessoryMuzzle": {
            private _itemInfoCfg = configFile >> "CfgWeapons" >> _item >> "ItemInfo";
            private _muzzleLines = [];
            private _pendingSeparator = false;

            // Keep the same selected fields, order and formatting as TEH Extra Item Info.
            // A separator is emitted only when both surrounding groups have values.
            {
                if ((count _x) == 1 && {(_x # 0) == "separator"}) then {
                    _pendingSeparator = (count _muzzleLines) > 0;
                } else {
                    _x params ["_section", "_property", "_label", "_format"];
                    private _valueText = [_itemInfoCfg >> _section >> _property] call _configScalarText;

                    if (_valueText != "") then {
                        private _value = parseNumber _valueText;
                        private _displayValue = switch (_format) do {
                            case "reduction": {
                                str ([((1 - _value) * 100), 1] call BIS_fnc_cutDecimals) + "%"
                            };
                            default {
                                str ([_value * 100, 1] call BIS_fnc_cutDecimals) + "%"
                            };
                        };

                        if (_pendingSeparator) then {
                            _muzzleLines pushBack "";
                            _pendingSeparator = false;
                        };
                        _muzzleLines pushBack ([_label, _displayValue] call _line);
                    };
                };
            } forEach [
                ["AmmoCoef", "visibleFire", localize "STR_TEH_STATS_FLASH_REDUCTION", "reduction"],
                ["AmmoCoef", "visibleFireTime", localize "STR_TEH_STATS_FLASH_DURATION_REDUCTION", "reduction"],
                ["AmmoCoef", "audibleFire", localize "STR_TEH_STATS_SOUND_REDUCTION", "reduction"],
                ["AmmoCoef", "audibleFireTime", localize "STR_TEH_STATS_SOUND_DURATION_REDUCTION", "reduction"],
                ["separator"],
                ["AmmoCoef", "hit", localize "STR_TEH_STATS_DAMAGE_MODIFIER", "percent"],
                ["AmmoCoef", "airFriction", localize "STR_TEH_STATS_AIR_FRICTION_MODIFIER", "percent"],
                ["MagazineCoef", "initSpeed", localize "STR_TEH_STATS_INIT_SPEED_MODIFIER", "percent"],
                ["MuzzleCoef", "dispersionCoef", localize "STR_TEH_STATS_DISPERSION_MODIFIER", "percent"],
                ["MuzzleCoef", "recoilCoef", localize "STR_TEH_STATS_RECOIL_MODIFIER", "percent"],
                ["MuzzleCoef", "recoilProneCoef", localize "STR_TEH_STATS_RECOIL_PRONE_MODIFIER", "percent"],
                ["MuzzleCoef", "fireLightCoef", localize "STR_TEH_STATS_FIRE_LIGHT_MODIFIER", "percent"]
            ];

            _lines append _muzzleLines;
        };

        case "AccessorySights": {
            private _optics = configProperties [
                configFile >> "CfgWeapons" >> _item >> "ItemInfo" >> "OpticsModes",
                "isClass _x", true
            ];
            {
                private _mode = configName _x;
                private _zoom = 0.25 / getNumber (_x >> "opticsZoomMin");
                _lines pushBack ([_mode, "x" + str ([_zoom, 1] call BIS_fnc_cutDecimals)] call _line);
            } forEach _optics;
        };

        case "Bullet": {
            private _magCfg = configFile >> "CfgMagazines" >> _item;
            private _ammoName = getText (_magCfg >> "ammo");
            private _ammoCfg = configFile >> "CfgAmmo" >> _ammoName;
            private _ammoHit = getNumber (_ammoCfg >> "hit");
            private _ammoCal = getNumber (_ammoCfg >> "caliber");
            private _magSpeed = getNumber (_magCfg >> "initSpeed");
            private _typicalSpeed = getNumber (_ammoCfg >> "typicalSpeed");
            private _bulletMassCfg = _ammoCfg >> "ACE_bulletMass";

            // This resolver belongs to JNA/TEH and is always available here.
            private _bulletName = [_item] call JN_fnc_arsenal_tehAmmoDisplayName;
            if (_bulletName isEqualType "" && {_bulletName != ""}) then {
                _lines pushBack ([localize "STR_TEH_STATS_BULLET", _bulletName] call _line);
            } else {
                _lines pushBack ([localize "STR_TEH_STATS_BULLET_CODE", _ammoName] call _line);
            };

            _lines pushBack ([localize "STR_TEH_STATS_BULLET_DAMAGE", str ([_ammoHit, 1] call BIS_fnc_cutDecimals)] call _line);
            _lines pushBack ([localize "STR_TEH_STATS_BULLET_PENETRATION", str ([_ammoCal, 2] call BIS_fnc_cutDecimals)] call _line);
            _lines pushBack "";
            _lines pushBack ([localize "STR_TEH_STATS_MUZZLE_SPEED_REF", str _magSpeed + " m/s"] call _line);

            if (isNumber _bulletMassCfg) then {
                private _bulletMass = getNumber _bulletMassCfg;
                _lines pushBack ([
                    localize "STR_TEH_STATS_MUZZLE_ENERGY_REF",
                    str floor ((_bulletMass * _magSpeed * _magSpeed) / 2000) + " J"
                ] call _line);
            } else {
                _lines pushBack ([localize "STR_TEH_STATS_MUZZLE_ENERGY_REF", localize "STR_TEH_STATS_NEEDS_ACE"] call _line);
            };

            _lines pushBack ([localize "STR_TEH_STATS_TYPICAL_SPEED", str _typicalSpeed + " m/s"] call _line);
            if (_magSpeed > 0 && {_typicalSpeed > 0}) then {
                _lines pushBack ([
                    localize "STR_TEH_STATS_DAMAGE_MULTIPLIER_REF",
                    str round ((_magSpeed / _typicalSpeed) * 100) + "%"
                ] call _line);
            };
        };

        case "Rocket";
        case "Missile";
        case "Shell";
        case "Grenade": {
            _lines pushBack "";
            private _ammoName = getText (configFile >> "CfgMagazines" >> _item >> "ammo");
            _lines append ([_ammoName] call _ammoStats);
        };
        default {};
    };

    // Generic CfgWeapons tail: weapon muzzle velocity overrides and inertia.
    private _weaponCfg = configFile >> "CfgWeapons" >> _item;
    private _isWeapon = _itemTypeCategory == "Weapon";
    private _isAttachment = _itemTypeName in [
        "AccessoryMuzzle", "AccessorySights", "AccessoryPointer", "AccessoryBipod"
    ];

    if (_isWeapon) then {
        private _initSpeedCfg = _weaponCfg >> "initSpeed";
        if (isNumber _initSpeedCfg) then {
            private _initSpeed = getNumber _initSpeedCfg;
            if (_initSpeed != 0) then {
                _lines pushBack "";
                if (_initSpeed > 0) then {
                    _lines pushBack ([localize "STR_TEH_STATS_INIT_SPEED", str _initSpeed + " m/s"] call _line);
                } else {
                    _lines pushBack ([
                        localize "STR_TEH_STATS_INIT_SPEED_MODIFIER",
                        str ([-_initSpeed * 100, 1] call BIS_fnc_cutDecimals) + "%"
                    ] call _line);
                };
            };
        };
    };

    if (_isWeapon || _isAttachment) then {
        private _inertiaCfg = _weaponCfg >> "inertia";
        if (isNumber _inertiaCfg) then {
            private _inertia = getNumber _inertiaCfg;
            if (_inertia != 0) then {
                private _inertiaText = str _inertia;
                private _inertiaLabel = localize "STR_TEH_STATS_INERTIA";
                if (_isAttachment) then {
                    _inertiaLabel = localize "STR_TEH_STATS_INERTIA_MODIFIER";
                    if (_inertia > 0) then { _inertiaText = "+" + _inertiaText };
                };
                _lines pushBack ([_inertiaLabel, _inertiaText] call _line);
            };
        };
    };

    // Fixed estimated metric weight for all inventory item types (1 mass unit = 50 g).
    // Preserve EII's precedence across the different config branches.
    private _mass = 0;
    private _hasMass = false;
    private _magazineCfg = configFile >> "CfgMagazines" >> _item;
    private _vehicleCfg = configFile >> "CfgVehicles" >> _item;
    private _glassesCfg = configFile >> "CfgGlasses" >> _item;

    if (isClass _magazineCfg && {isNumber (_magazineCfg >> "mass")}) then {
        _mass = getNumber (_magazineCfg >> "mass");
        _hasMass = true;
    } else {
        if (isClass _glassesCfg && {isNumber (_glassesCfg >> "mass")}) then {
            _mass = getNumber (_glassesCfg >> "mass");
            _hasMass = true;
        } else {
            if (isClass _vehicleCfg && {isNumber (_vehicleCfg >> "mass")}) then {
                _mass = getNumber (_vehicleCfg >> "mass");
                _hasMass = true;
            } else {
                if (isClass _weaponCfg) then {
                    private _itemMassCfg = _weaponCfg >> "ItemInfo" >> "mass";
                    private _weaponMassCfg = _weaponCfg >> "WeaponSlotsInfo" >> "mass";
                    private _directMassCfg = _weaponCfg >> "mass";

                    if (isNumber _itemMassCfg) then {
                        _mass = getNumber _itemMassCfg;
                        _hasMass = true;
                    } else {
                        if (isNumber _weaponMassCfg) then {
                            _mass = getNumber _weaponMassCfg;
                            _hasMass = true;
                        } else {
                            if (isNumber _directMassCfg) then {
                                _mass = getNumber _directMassCfg;
                                _hasMass = true;
                            };
                        };
                    };
                };
            };
        };
    };

    if (_hasMass) then {
        private _weightKg = _mass * 0.05;
        private _decimals = if (_weightKg < 1) then { 2 } else { 1 };
        _lines pushBack ([
            localize "STR_TEH_STATS_WEIGHT_EST",
            str ([_weightKg, _decimals] call BIS_fnc_cutDecimals) + " kg"
        ] call _line);
    };

    jna_tooltips set [_item, _lines joinString "\n"];
};

// Arsenal-only dynamic tail. Keep its original stock source and compact counters.
private _amounts = "";
if (_itemTypeName isEqualTo "Bullet") then {
    private _ammo = getText (configFile >> "CfgMagazines" >> _item >> "ammo");
    private _bulletCargo = jna_dataList # IDC_RSCDISPLAYARSENAL_TAB_CARGOBULLET;
    private _ammoIdx = _bulletCargo findIf { _x # 0 isEqualTo _ammo };

    if (_ammoIdx > -1) then {
        private _ammoLeft = _bulletCargo # _ammoIdx # 1;
        private _countText = "";

        if (_ammoLeft == -1) then {
            _countText = "[   ∞  ]";
        } else {
            private _suffix = "";
            private _prefix = "";

            if (_ammoLeft > 999) then {
                _ammoLeft = round (_ammoLeft / 1000);
                _suffix = "k";
                _prefix = switch true do {
                    case (_ammoLeft >= 100): { _ammoLeft = 99; "" };
                    case (_ammoLeft >= 10): { "" };
                    case (_ammoLeft >= 0): { "0" };
                };
            } else {
                _prefix = switch true do {
                    case (_ammoLeft >= 100): { "" };
                    case (_ammoLeft >= 10): { "0" };
                    case (_ammoLeft >= 0): { "00" };
                };
            };
            _countText = "[ " + _prefix + str _ammoLeft + _suffix + " ]";
        };

        _amounts = format [localize "STR_TEH_JNA_AMMO_LEFT", _countText];
    } else {
        _amounts = localize "STR_TEH_JNA_NO_AMMO_LEFT";
    };

    _amounts = "\n\n" + _amounts;
};

(jna_tooltips get _item) + _amounts;
