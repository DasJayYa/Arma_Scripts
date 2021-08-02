// To call paste in init: { _x addEventHandler ["SUPPRESSED",{ if (artyFire ==0) then {_callArty = [_this select 0, _this select 2] execVM "functions\AIartyReq.sqf"} }]; } forEach units east;

//Retrieve variables passed across from the eventHandler and create a target marker
_victim = _this select 0;
_caller = leader group _victim;
_shooter = _this select 1;

//Set the public variable to limit the AI to 1 arty request at a time and create the target marker
artyFire = 1;
publicVariable "artyFire";
_mrk = createMarker ["mrk_o_Arty", _shooter];

//Check to see if the targer is the right side, isn't a helicopter or moving fast, the AI actually knows about the player group and is within a reasonable range, and no friendly (well enemy to you) units in the vacinity prior to calling in artillery. Will exit the script and reset the request environment if target is invalid
if !( ((side _shooter)==west || (side _shooter)==independent) && ({ _x distance _shooter <100} count units east)==0 && (_caller distance _shooter)<1000 && isTouchingGround _shooter && (east knowsAbout _shooter)>3 && (speed _shooter)<10 ) exitWith
{
	sleep 10;
	artyFire = 0;
	publicVariable "artyFire";
	deleteMarker "mrk_o_Arty";
};

//Find all mortars in 3km of the target location, then removes any that don't have ammo or aren't capable of firing at the target coordinates (too close or too far) from the list of possible artillery providers
_availableArty = nearestObjects [getMarkerPos "mrk_o_Arty", ["O_G_Mortar_01_F"], 4000];
{
	if ( (_x ammo "mortar_82mm")==0 || !((getMarkerPos "mrk_o_Arty") inRangeOfArtillery [[_x] ,"mortar_82mm"]) && (_x distance (getMarkerPos "mrk_o_Arty"))<200 ) then
	{
		_availableArty = _availableArty - [_x]
	};
} forEach _availableArty;
sleep 0.2;
_artyPiece = _availableArty select 0; //selects the nearest valid artillery provider to the target

//Exit the script if no valid artillery providers found, resetting the request environment
if ( (count [_artyPiece])==0 ) exitWith
{
	sleep 10;
	artyFire = 0;
	publicVariable "artyFire";
	deleteMarker "mrk_o_Arty";
};

sleep 10; //sleep to simulate the time I estimate it could take to transmit the coordinates IRL

//Quick double check to make sure the AI requesting support is actually still alive and the target is still in the vacinity of original target coordinates and exits script if no longer valid, resetting the request environment
if ( !alive _caller || (_shooter distance (getMarkerPos "mrk_o_Arty"))>100 ) exitWith
{
	sleep 10;
	artyFire = 0;
	publicVariable "artyFire";
	deleteMarker "mrk_o_Arty";
};

sleep random [10,20,30]; //Everything is confrimed as valid, now a final sleep between 10 to 30 seconds that allows the players one last chance to move

//Action time. Now we command the artillery provider to fire up to 8 rounds at target coordinates with a simulated margin of error up to a 50 meter radius around the target coordinates
_artyPiece commandArtilleryFire
[
	[
		(getMarkerPos "mrk_o_Arty" select 0) + (random 50),
		(getMarkerPos "mrk_o_Arty" select 1) + (random 50),
		0
	],
	"8Rnd_82mm_Mo_shells",
	random 8
];

sleep (random 240); //Now wait up to 4 minutes

//exit script and reset the request environment
artyFire = 0;
publicVariable "artyFire";
deleteMarker "mrk_o_Arty";