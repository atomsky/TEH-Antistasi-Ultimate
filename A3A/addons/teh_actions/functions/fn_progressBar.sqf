/*
    TEH wrapper with the callback shape used by loot_vehicle:
    [time, args, success, failure, title, caller, condition]
    Callbacks receive [args, elapsed, total, code]. Codes: 0 complete,
    1 cancelled/replaced, 2 caller died/changed, 3 condition failed.
*/
params ["_duration", "_arguments", "_success", "_failure", "_title", "_caller", ["_condition", {true}]];
private _context = [_arguments, _success, _failure, _caller, _condition];
[
    _title,
    _duration,
    {
        params ["_context", "_ok", "_elapsed", "_total"];
        _context params ["_args", "_success", "_failure", "_caller", "_condition"];
        _caller isEqualTo player && {alive _caller} && {lifeState _caller isNotEqualTo "INCAPACITATED"}
            && {isNull objectParent _caller}
            && {[_args, _elapsed, _total, -1] call _condition}
    },
    {
        params ["_context", "_ok", "_elapsed", "_total"];
        _context params ["_args", "_success"];
        [_args, _elapsed, _total, 0] call _success;
    },
    {
        params ["_context", "_ok", "_elapsed", "_total", "_cbaCode"];
        _context params ["_args", "_success", "_failure", "_caller"];
        private _code = if (_cbaCode isEqualTo 2) then {
            [3, 2] select (!alive _caller || {!(_caller isEqualTo player)})
        } else {
            1
        };
        [_args, _elapsed, _total, _code] call _failure;
    },
    _context
] call CBA_fnc_progressBar;
