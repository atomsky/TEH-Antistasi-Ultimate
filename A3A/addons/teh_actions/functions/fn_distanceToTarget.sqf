/* Eye-to-body distance for large vehicles; normal object distance otherwise. */
params ["_from", "_target"];
if (isNull _from || {isNull _target}) exitWith {1e10};
if !(_target isKindOf "LandVehicle" || {_target isKindOf "Air"} || {_target isKindOf "Ship"}) exitWith {
    _from distance _target
};

(boundingBoxReal _target) params ["_minimum", "_maximum"];
private _eye = ASLToAGL (eyePos _from);
private _relative = _target worldToModelVisual _eye;
private _point = [
    ((_relative # 0) max (_minimum # 0)) min (_maximum # 0),
    ((_relative # 1) max (_minimum # 1)) min (_maximum # 1),
    ((_relative # 2) max (_minimum # 2)) min (_maximum # 2)
];
_eye distance (_target modelToWorldVisual _point)
