params ["_type"];

private _positionOrigin = getMarkerPos [supportMarkerOrigin, true];
private _ammoType = "";
private _roundCount = 0;
private _spread = 0;
private _delay = 0;
private _height = 200;

switch (_type) do {
    case "MORTAR": {
        _ammoType = "Sh_82mm_AMOS";
        _roundCount = 16;
        _spread = 30;
        _delay = 15;
    };
    case "ARTILLERY": {
        _ammoType = "Sh_155mm_AMOS";
        _roundCount = 12;
        _spread = 50;
        _delay = 15;
    };
    case "MLRS": {
        _ammoType = "R_230mm_HE";
        _roundCount = 12;
        _spread = 100;
        _delay = 15;
    };
};

if(!isNil "petros" && {alive petros}) then {
    petros sideChat (localize "STR_chats_barrage_splash_out");
};

private _timeOut = time + _delay;
waitUntil {sleep 1; time > _timeOut };

{
    [petros, "support", localize "STR_comms_mp_splash"] remoteExec ["A3A_fnc_commsMP", _x];
} forEach ([500, _positionOrigin] call SCRT_fnc_common_getNearPlayers);

for "_i" from 1 to _roundCount do {
    private _randomizedPosition = [
        (_positionOrigin select 0) + (random _spread) - (_spread / 2), 
        (_positionOrigin select 1) + (random _spread) - (_spread / 2), 
        (_positionOrigin select 2) + _height
    ];

    private _shell = _ammoType createVehicle _randomizedPosition;
    
    if (_type == "MLRS") then {
        _shell setVectorDirAndUp [[0,0,-1],[0,1,0]];
    };

    _shell setVelocity [0, 0, -100];

    sleep (random 2);
};

isSupportMarkerPlacingLocked = false;
publicVariable "isSupportMarkerPlacingLocked";
