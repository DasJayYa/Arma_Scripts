/*
	Author: AgentChiggins

	Description:
		Allows AI group leaders to request an artillery fire mission when suppressed by the enemy, on the enemy location. Functions on client side. Will detect if the unit is a High Command subordinate to a player, at which point the request will be made to the player High Command Commander.

	Parameter(s):
		0: unit suppressed (do not change)
		1: unit suppressing the caller (do not change)

	Returns:
		boolean

	Examples:
		Spawn via eventhandler: _unit addEventHandler ["SUPPRESSED",{ if ( isNil { hcLeader group (_this select 0) getVariable "artyRequested" } && !isPlayer (_this select 0) ) then { _callArty = [_this select 0, _this select 2] spawn ACH_fnc_npcArtyRequester}; }];
*/

private _victim = _this select 0;
private _caller = hcLeader group _victim;
private _side = side _victim;
private _shooter = _this select 1;
private _availableArty = [];
private _targetLocation = position _shooter;

_caller setVariable ["artyRequested",true,true];


if !(
     	( [_side, side _shooter] call BIS_fnc_sideIsEnemy )==true
		and
		({ _victim distance _shooter <100 } count units _side)==0
		and
		({ _victim distance _shooter <100 } count units civilian)==0
		and
		(_victim distance _shooter)<1200
		and
		isTouchingGround _shooter
		and
		(_side knowsAbout _shooter)>1
		and
		(speed _shooter)<10
	) exitWith
			{
				_caller setVariable ["artyRequested",nil,true];
			};

if ( isPlayer _caller ) exitWith
{
	{
		_victim sideChat format ["%1, this is %1 we are under heavy fire. Request artillery support at grid %3",groupID group _caller,groupID group _victim,mapGridPosition _shooter];
	} remoteExec ["call",_side];

	{
		_Mrk = createMarkerLocal ["reqMark",position _shooter];
		"reqMark" setMarkerTypeLocal "Contact_circle3";
		"reqMark" setMarkerTextLocal format ["%1 artillery request target",groupID group _victim];
		hint format ["%1 is requesting a fire mission at grid %2. Call for artillery support via support radio (0-8)"];
		_mrk_Delete = [] spawn {
									sleep 60;
                                	deleteMarkerLocal "reqMark";
                                	player setVariable ["artyRequested",nil,true];
                            	};
    } remoteExec ["call",_caller];
};

{
	_caller sideChat format ["%1, %2 is under heavy fire. Request fire mission on grid %3",[_side,"HQ"],groupID group _victim,mapGridPosition _shooter];
} remoteExec ["call",_side];

_availableArty = nearestObjects [position _shooter, ["B_Mortar_01_F","I_Mortar_01_F","O_Mortar_01_F","I_G_Mortar_01_F","O_G_Mortar_01_F","B_MBT_01_arty_F","B_MBT_01_mlrs_F","O_MBT_02_arty_F"], 10000];
{
	if (
			(vehicle _x  ammo (currentWeapon vehicle _x ))==0
			or
			!(_targetLocation inRangeOfArtillery [[_x], (vehicle _x) currentMagazineTurret [0]])
			or
			(_x distance _targetLocation)<200
			or
			side _x != _side
			or
			!isNil { _x getVariable "artyFire" }
			or
			isPlayer (leader group _x)
		) then
			{
				_availableArty = _availableArty - [_x];
			};
} forEach _availableArty;
sleep 0.2;

if ( count _availableArty == 0 ) exitWith
{
	_caller setVariable ["artyRequested",nil,true];
	{
		[_side, "HQ"] sideChat format ["Negative that request %1, no supports available at this time.",groupID (group _caller)]
	} remoteExec ["call",_side];
};

_selectedArty = _availableArty select 0;
_artyETA = _selectedArty getArtilleryETA [_targetLocation, (vehicle _selectedArty) currentMagazineTurret [0]];
_selectedArty setVariable ["artyFire",true,true];
sleep (random [10,15,20]);

{
	_selectedArty sideChat format ["Target coordinates received, confirming target grid, %1. ETA %2",mapGridPosition _shooter, _artyETA];
	_mrk = createMarkerLocal ["artyMark", _targetLocation];
	"artyMark" setMarkerTypeLocal "hd_warning_noShadow";
	"artyMark" setMarkerTextLocal "Friendly artillery inbound";
} remoteExec ["call",_side];

_ammoCount = (vehicle _selectedArty  ammo (currentWeapon vehicle _selectedArty ));
_selectedArty commandArtilleryFire
[
	[
		(position _shooter select 0) + (random 20),
		(position _shooter select 1) + (random 20),
		0
	],
	vehicle _selectedArty currentMagazineTurret [0],
	random [ _ammoCount \ 4, _ammoCount \2, _ammoCount ]
];
{ _selectedArty, "Rounds Complete" }  remoteExec ["sideChat",_side];
sleep _artyETA;

{ _selectedArty, "Splash" }  remoteExec ["sideChat",_side];
sleep (selectRandom [90,150,300]);

_selectedArty setVariable ["artyFire",nil,true];
_caller setVariable ["artyRequested",nil,true];
{ deleteMarkerLocal "artyMark" } remoteExec ["call", _side];