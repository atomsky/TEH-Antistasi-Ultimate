#include "tehBulletPile.inc"

params["_item",["_arrayCargo",jna_dataList]];

private _ammoCapacity = getNumber (configfile >> "CfgMagazines" >> _item >> "count");
private _ammoName = getText(configFile >> "CfgMagazines" >> _item >> "ammo");

if (_ammoName == "") exitWith {
    [IDC_RSCDISPLAYARSENAL_TAB_CARGOBULLET, _ammoName, _ammoCapacity];
};

private _ammoIdx = _arrayCargo # IDC_RSCDISPLAYARSENAL_TAB_CARGOBULLET findif { _x # 0 isEqualTo _ammoName};
private _ammoBin = -1;
private _ammoToLoad = 0;
if (_ammoIdx > -1) then {
    _ammoBin = _arrayCargo # IDC_RSCDISPLAYARSENAL_TAB_CARGOBULLET # _ammoIdx # 1;
    if (( _ammoBin != -1) and (_ammoBin < _ammoCapacity)) then {
        _ammoToLoad = _ammoBin;
    } else {
        _ammoToLoad = _ammoCapacity;
    };
};

//unfortunately removeItem takes its time, thus we need a predictive system to post ammo counter
if not (isNil "_display") then {
    if (_ammoIdx < 0 || _ammoBin == _ammoToLoad) then {
            ['showMessage',[_display,"No ammo left"]] call bis_fnc_arsenal;
    } else {
        if (_ammoBin < 1000 && _ammoBin != -1) then {
            ['showMessage',[_display,format["%1 ammo left",_ammoBin - _ammoToLoad]]] call bis_fnc_arsenal;
        };
    };
};

[IDC_RSCDISPLAYARSENAL_TAB_CARGOBULLET, _ammoName, _ammoToLoad];