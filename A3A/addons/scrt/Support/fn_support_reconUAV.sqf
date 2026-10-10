params [];

private _positionOrigin = getMarkerPos [supportMarkerOrigin, true];
private _uavType = "B_UAV_02_dynamicLoadout_F"; 

private _factionUAVs = A3A_faction_reb get "vehicleUAVs";
if (!isNil "_factionUAVs" && {count _factionUAVs > 0}) then {
    _uavType = selectRandom _factionUAVs;
};

if(!isNil "petros" && {alive petros}) then {
    petros sideChat (localize "STR_chats_uav_deployed");
};

private _uavGroup = createGroup teamPlayer;
private _uav = createVehicle [_uavType, [(_positionOrigin select 0), (_positionOrigin select 1), 500], [], 0, "FLY"];
createVehicleCrew _uav;
(crew _uav) joinSilent _uavGroup;
_uavGroup setGroupIdGlobal ["Recon UAV"];

_uav flyInHeight 500;
_uav setAutonomous true;

private _wp = _uavGroup addWaypoint [_positionOrigin, 0];
_wp setWaypointType "LOITER";
_wp setWaypointLoiterRadius 500;
_wp setWaypointLoiterType "CIRCLE";

[_uav, _positionOrigin] spawn {
    params ["_uav", "_pos"];
    private _endTime = time + 180;
    while {alive _uav && time < _endTime} do {
        private _enemies = allUnits select {side _x != teamPlayer && side _x != civilian && _x distance2D _pos < 1000};
        {
            teamPlayer reveal [_x, 4];
        } forEach _enemies;
        sleep 5;
    };
    
    if (alive _uav) then {
        _uav move [0,0,1000];
        sleep 60;
        deleteVehicle _uav;
        {deleteVehicle _x} forEach crew _uav;
    };
};

isSupportMarkerPlacingLocked = false;
publicVariable "isSupportMarkerPlacingLocked";
