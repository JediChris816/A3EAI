private ["_unitGroup", "_waypoint", "_vehicle", "_endTime", "_vehiclePos", "_nearUnits", "_vehPos", "_despawnPos", "_reinforcePos","_vehicleArmed","_paraDrop","_reinforceTime"];

_unitGroup = _this;

if !((typeName _unitGroup) isEqualTo "GROUP") exitWith {diag_log format ["A3EAI Error: Invalid group %1 provided to %2.",_unitGroup,__FILE__];};

_vehicle = _unitGroup getVariable ["assignedVehicle",objNull];
_vehicleArmed = _vehicle getVariable ["ArmedVehicle",false];
_reinforcePos = _unitGroup getVariable ["ReinforcePos",[0,0,0]];

if (_vehicleArmed) then {
	_waypoint = [_unitGroup,0];
	_waypoint setWaypointStatements ["true",""];
	_waypoint setWaypointType "SAD";
	_waypoint setWaypointBehaviour "AWARE";
	_waypoint setWaypointCombatMode "YELLOW";

	if (local _unitGroup) then {
		_unitGroup setCurrentWaypoint _waypoint;
	} else {
		A3EAI_setCurrentWaypoint_PVC = _waypoint;
		A3EAI_HCObjectOwnerID publicVariableClient "A3EAI_setCurrentWaypoint_PVC";
	};
	
	_reinforceTime = call {
		private ["_unitLevel"];
		_unitLevel = _unitGroup getVariable ["unitLevel",-1];
		if (_unitLevel isEqualTo 3) exitWith {A3EAI_airReinforcementDuration3};
		if (_unitLevel isEqualTo 2) exitWith {A3EAI_airReinforcementDuration2};
		if (_unitLevel isEqualTo 1) exitWith {A3EAI_airReinforcementDuration1};
		if (_unitLevel isEqualTo 0) exitWith {A3EAI_airReinforcementDuration0};
		0
	};
	
	if (A3EAI_debugLevel > 1) then {diag_log format ["A3EAI Extended Debug: Group %1 is now reinforcing for %2 seconds.",_unitGroup,_reinforceTime];};

	_unitGroup setSpeedMode "LIMITED";
	_endTime = diag_tickTime + _reinforceTime;
	while {(diag_tickTime < _endTime) && {(_unitGroup getVariable ["GroupSize",-1]) > 0} && {(_unitGroup getVariable ["unitType",""]) isEqualTo "air_reinforce"}} do {
		if (local _unitGroup) then {
			_vehiclePos = getPosATL _vehicle;
			_vehiclePos set [2,0];
			_nearUnits = _vehiclePos nearEntities [["Epoch_Male_F","Epoch_Female_F","LandVehicle"],250];
			if ((count _nearUnits) > 5) then {_nearUnits resize 5};
			{
				if ((isPlayer _x) && {(_unitGroup knowsAbout _x) < 3}) then {
					_unitGroup reveal [_x,3];
					if (({if ("EpochRadio0" in (assignedItems _x)) exitWith {1}} count (crew (vehicle _x))) > 0) then {
						[_x,[31+(floor (random 5)),[name (leader _unitGroup)]]] call A3EAI_radioSend;
					};
				};
			} forEach _nearUnits;
		};
		uiSleep 15;
	};
	_unitGroup setSpeedMode "NORMAL";

	if (A3EAI_debugLevel > 1) then {diag_log format ["A3EAI Extended Debug: Group %1 reinforcement timer complete.",_unitGroup];};
} else {
	_paraDrop = [_unitGroup,_vehicle,objNull] spawn A3EAI_heliParaDrop;
	waitUntil {uiSleep 0.1; scriptDone _paraDrop};
};

if (((_unitGroup getVariable ["GroupSize",-1]) < 1) or {!((_unitGroup getVariable ["unitType",""]) isEqualTo "air_reinforce")}) exitWith {
	if (A3EAI_debugLevel > 1) then {diag_log format ["A3EAI Extended Debug: Group %1 (type: %2) is no longer reinforcing, reinforce timer exited.",_unitGroup,(_unitGroup getVariable ["unitType","unknown"])];};
};

_vehPos = (getPosATL _vehicle);
_despawnPos = [_vehPos,2000,random(360),1] call SHK_pos;

if (A3EAI_debugLevel > 1) then {diag_log format ["A3EAI Extended Debug: %1 Vehicle %2 (pos %3) assigned despawn pos %4.",_unitGroup,(typeOf _vehicle),_vehPos,_despawnPos];};

_waypoint = _unitGroup addWaypoint [_despawnPos,0];
_waypoint setWaypointType "MOVE";
_waypoint setWaypointBehaviour "CARELESS";
if (_vehicleArmed) then {_waypoint setWaypointCombatMode "BLUE";};
if (local _unitGroup) then {
	_unitGroup setCurrentWaypoint _waypoint;
} else {
	A3EAI_setCurrentWaypoint_PVC = _waypoint;
	A3EAI_HCObjectOwnerID publicVariableClient "A3EAI_setCurrentWaypoint_PVC";
};

waitUntil {uiSleep 15; (((getPosATL _vehicle) distance _vehPos) > 1200) or {!(alive _vehicle)}};

_unitGroup call A3EAI_cleanupReinforcementGroup;
A3EAI_reinforcedPositions = A3EAI_reinforcedPositions - _reinforcePos;

true
