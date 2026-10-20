params ["_unit"];

private _loadouts = (A3A_customUnitTypes getVariable ["loadouts_civ_militia_Man", []]) select 0;
_unit setUnitLoadout selectRandom _loadouts;

_unit setVariable ["TEH_IsGopnik", true, true];
_unit setVariable ["spawner", false, true];
_unit setVariable ["TEH_GopnikActivated", false, true];

if ("TEH_banditUniforms" in A3A_faction_civ) then {
	private _banditUniforms = A3A_faction_civ get "TEH_banditUniforms";

	if (_banditUniforms isNotEqualTo []) then {
		removeUniform _unit;
		_unit forceAddUniform selectRandom _banditUniforms;
	};
};

if ("TEH_banditHeadgears" in A3A_faction_civ) then {
	private _banditHeadgears = A3A_faction_civ get "TEH_banditHeadgears";

	removeHeadgear _unit;

	if (_banditHeadgears isNotEqualTo []) then {
		_unit addHeadgear selectRandom _banditHeadgears;
	};
};

private _banditHead = selectRandom (A3A_faction_civ getOrDefault ["TEH_banditHeads", ["RussianHead_1", "RussianHead_2", "RussianHead_3", "RussianHead_4", "RussianHead_5"]]);
private _banditVoice = selectRandom (A3A_faction_civ getOrDefault ["TEH_banditVoices", ["male01rus", "male02rus", "male03rus"]]);

[_unit, createHashMapFromArray [["face", _banditHead],["speaker", _banditVoice]]] call A3A_fnc_setIdentity;

_unit setCaptive true;
_unit setBehaviour "SAFE";
_unit setCombatMode "GREEN";
_unit allowFleeing 0.4;

_unit addAction [
    localize "STR_TEH_GOPNIK_ACTION_HELLO",
    {
        params ["_target", "_caller"];

        private _captiveLines = [
            "(Angry Russian) Иди отсюда, пока по шее не получил.",
            "(Angry Russian) Слышь, гражданский, проходи мимо.",
            "(Angry Russian) Чё смотришь? Дорогу забыл?",
            "(Angry Russian) Вали по-тихому, пока настроение нормальное.",
            "(Angry Russian) Не стой рядом. У нас тут культурный отдых.",
            "(Angry Russian) Тебе тут не рады, понял?",
            "(Angry Russian) Давай ногами работай, пока целый.",
            "(Angry Russian) Проходи, мужик. Просто проходи.",
            "(Angry Russian) Не отсвечивай, и всё будет ровно.",
            "(Angry Russian) Ты нас не видел, мы тебя не трогали."
        ];

        private _armedLines = [
            "(Cautious Russian) Слышь, давай без беспредела.",
            "(Cautious Russian) Спокойно, командир. Мы тут просто стоим.",
            "(Cautious Russian) Без резких движений, понял?",
            "(Cautious Russian) Давай разойдёмся красиво.",
            "(Cautious Russian) Тихо-тихо, герой местный.",
            "(Cautious Russian) Не начинай, и мы не начнём.",
            "(Cautious Russian) Держи дистанцию, военный.",
            "(Cautious Russian) У нас тут свои дела, у тебя свои."
        ];

        private _lines = if (captive _caller) then {
            _captiveLines
        } else {
            _armedLines
        };

        [_target, selectRandom _lines] remoteExec ["globalChat", _caller];
        systemChat localize "STR_TEH_GOPNIK_HOSTILE_MESSAGE";

        true
    },
    nil,
    1.5,
    true,
    true,
    "",
    "alive _target && alive _this && {_this distance _target < 3} && {!(_target getVariable ['TEH_GopnikActivated', false])}",
    3,
    false,
    "",
    ""
];

_unit addEventHandler ["FiredNear", {
    params ["_unit", "_firer", "_distance"];

    if (!local _unit) exitWith {};
    if (!alive _unit) exitWith {};
    if (_unit getVariable ["TEH_GopnikActivated", false]) exitWith {};
    if (_distance > 100) exitWith {};

    _unit setVariable ["TEH_GopnikActivated", true, true];
    _unit removeEventHandler [_thisEvent, _thisEventHandler];

    [_unit, _firer] spawn {
        params ["_unit", "_firer"];

        sleep (0.5 + random 2.5);

        if (!alive _unit) exitWith {};

        private _isPrimary = random 1 < 0.5;
        private _loadout = if (_isPrimary) then {
            selectRandom (A3A_faction_civ getOrDefault [
                "TEH_civilianPrimaryLoadouts",
                [
                    ["sgun_HunterShotgun_01_sawedoff_F", "", "", "", ["2Rnd_12Gauge_Pellets", "2Rnd_12Gauge_Pellets", "2Rnd_12Gauge_Pellets", "2Rnd_12Gauge_Pellets", "2Rnd_12Gauge_Pellets"], [], ""],
                    ["sgun_HunterShotgun_01_F", "", "", "", ["2Rnd_12Gauge_Pellets", "2Rnd_12Gauge_Pellets", "2Rnd_12Gauge_Pellets", "2Rnd_12Gauge_Pellets", "2Rnd_12Gauge_Pellets"], [], ""]
                ]
            ])
        } else {
            selectRandom (A3A_faction_civ getOrDefault [
                "TEH_civilianHandgunLoadouts",
                [
                    ["hgun_Pistol_01_F", "", "", "", ["10Rnd_9x21_Mag", "10Rnd_9x21_Mag", "10Rnd_9x21_Mag", "10Rnd_9x21_Mag"], [], ""],
                    ["hgun_P07_F", "", "", "", ["16Rnd_9x21_Mag", "16Rnd_9x21_Mag", "16Rnd_9x21_Mag"], [], ""]
                ]
            ])
        };

        _loadout params ["_weapon", "_muzzle", "_pointer", "_optic", "_magazines", "_secondaryAmmo", "_bipod"];

        _unit setCaptive false;

        {
            _unit addMagazine _x;
        } forEach _magazines;

        _unit addWeapon _weapon;

        if (_isPrimary) then {
            {
                if (_x != "") then {
                    _unit addPrimaryWeaponItem _x;
                };
            } forEach [_muzzle, _pointer, _optic, _bipod];
        } else {
            {
                if (_x != "") then {
                    _unit addHandgunItem _x;
                };
            } forEach [_muzzle, _pointer, _optic];
        };

        _unit selectWeapon _weapon;
        _unit allowFleeing 0.1;

        if (!isNull _firer && {alive _firer} && (leader (group _unit) == _unit)) then {
            private _group = group _unit;
            private _searchPos = getPosATL _firer;

            _unit reveal [_firer, 2.5];
            _unit doTarget _firer;
            _unit doMove _searchPos;

            private _wp = _group addWaypoint [_searchPos, 30];
            _wp setWaypointType "SAD";
            _wp setWaypointBehaviour "COMBAT";
            _wp setWaypointCombatMode "RED";
            _wp setWaypointSpeed "FULL";
            _wp setWaypointCompletionRadius 3;

            _group setCurrentWaypoint _wp;
        };
    };
}];
