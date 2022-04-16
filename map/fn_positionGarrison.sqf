/*
	Author: AgentChiggins

	Description:
		Will create an infantry garrison within a 100m radius of the defined position (no static defences are created), with garrison size automatically determined by location type. Two groups are created, a static group and a patrol group. Prior to contact, static units will remain in location, and patrol units will patrol the building.
		Upon contact static group will either remain static or move to threat. Patrol group will move to the threat. Both groups will automatically man any static defences in the area.

	Parameter(s):
		0: logic type

	Returns:
		boolean

	Examples:
		Place a location logic (either base, FOB, Camp or Outpost)
		In logic init paste: [this] spawn ACH_fnc_positionGarrison
		Or call via script: { [_x] spawn ACH_fnc_positionGarrison } forEach (nearestObjects [<area or building>, ["LocationBase_F","LocationFOB_F","LocationCamp_F","LocationOutpost_F"], 100 ]);
*/
if (!isServer) exitWith {};

private _logic = _this select 0;
private _unitArray = [
						"O_G_Soldier_SL_F",
						"O_G_Soldier_AR_F",
						"O_G_Soldier_GL_F",
						"O_G_Soldier_LAT2_F",
						"O_G_Soldier_M_F",
						"O_G_Soldier_F",
						"O_G_Soldier_F",
						"O_G_medic_F"
					];

switch (typeOf _logic) do
{
	case "LocationBase_F":
	{
		_logic setVariable ["_garrisonSize",random [30,40,60],true];
	};

	case "LocationFOB_F":
	{
		_logic setVariable ["_garrisonSize",random [18,26,32],true];
	};

	case "LocationCamp_F":
	{
		_logic setVariable ["_garrisonSize",random [10,16,20],true];
	};

	default
	{
		_logic setVariable ["_garrisonSize",random [4,6,8],true];
	};
};


private _garrisonGroup = createGroup [east, true];
private _patrolGroup = createGroup [east, true];

[_garrisonGroup, _logic] call BIS_fnc_taskDefend;
[_patrolGroup, _logic] call BIS_fnc_taskDefend;

private _buildings = nearestObjects [_logic, ["house"], 100 ];
private _buildingPositions = [];

while {count _buildings >0} do
{
	_selectedBuilding = _buildings select 0;
	_buildingPositions = _buildingPositions + ([_selectedBuilding] call BIS_fnc_buildingPositions);

	_buildings = _buildings - [_selectedBuilding];
};

while { ( (count units _garrisonGroup)+(count units _patrolGroup) )<(_logic getVariable "_garrisonSize") && count _buildingPositions >0 } do
{
	if ( (count _buildingPositions)>0 ) then
	{
		_selectedPos = selectRandom _buildingPositions;
		if ( ({(_x distance _selectedPos)<5} count units side _garrisonGroup)==0 ) then
		{
			_taskType = selectRandom [1,2,3];
			switch (_taskType) do
			{
				case 3:
				{
					(selectRandom _unitArray) createUnit [_logic, _patrolGroup,"this setPosATL _selectedPos;this addEventHandler ['SUPPRESSED',{ if ( isNil { hcLeader group (_this select 0) getVariable 'artyRequested' } && !isPlayer (_this select 0) ) then { _callArty = [_this select 0, _this select 2] spawn ACH_fnc_npcArtyRequester}; }];"];
				};
				default
				{
					(selectRandom _unitArray) createUnit [_logic, _garrisonGroup,"if ( (selectRandom [0,1]) == 1 ) then { [this, 'STAND', 'ASIS'] call BIS_fnc_ambientAnimCombat; } else { this forceSpeed 0 }; this setDir (random 360); this setPosATL _selectedPos;this addEventHandler ['SUPPRESSED',{ if ( isNil { hcLeader group (_this select 0) getVariable 'artyRequested' } && !isPlayer (_this select 0) ) then { _callArty = [_this select 0, _this select 2] spawn ACH_fnc_npcArtyRequester}; }];"];
					_buildingPositions = _buildingPositions - [_selectedPos];
				};
			};
			sleep 0.2;
		}
		else
		{
			_buildingPositions = _buildingPositions - [_selectedPos];
		};
	};
};

