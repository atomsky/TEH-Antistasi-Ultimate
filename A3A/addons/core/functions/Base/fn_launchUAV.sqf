private _launched = false;
{
	//TODO: add arsenal include and change # 5 to a constant
	private _dronePack = _x;
	private _droneId = jna_dataList # 5 findIf { _x # 0 isEqualTo _dronePack };
	
	if (_droneId > 0 && !_launched) then {
		private _droneCount = jna_dataList # 5 # _droneId # 1;
		if (_droneCount > 1) then {
			jna_dataList # 5 # _droneId set [1, _droneCount - 1];
		
			UAVreconTimer = time + 1200;
			publicVariable "UAVreconTimer";
			_launched = true;
		};
	};
} forEach ["I_UAV_01_backpack_F","O_UAV_01_backpack_F","I_E_UAV_01_backpack_F","B_UAV_01_backpack_F"];

if (_launched) then {
	systemChat localize "STR_TEH_UAV_LAUNCHED";
} else { 
	systemChat localize "STR_TEH_UAV_NO_BACKPACKS";
};