
# ND_VehicleSystem


## Exports:

**Server:**
|Export|Description|Parameter(s)|
|-|-|-|
|saveVehicle|save a vehicle to a character.|int: **Player source**, table: **vehicle properties**, boolean: **in garage or not**.|
|getVehicles|Get the vehicles a characater owns.|int: **ND Character id**|
|giveKeys|Give keys vehicle keys to a player.|int: **Vehicle entity**, int: **Player source**, int: **Target player source**|

**Client:**
|Export|Description|Parameter(s)|
|-|-|-|
|getVehicleOwned|Check if a vehicle is owned by any player.|int: **Vehicle entity**|
|isVehicleOwned|Check if the player owns the vehicle.|int: **Vehicle entity**|
|hasVehicleKeys|Check if the player has keys to the vehicle.|int: **Vehicle entity**|
|getClosestVehicles|Get the closest vehicle the player has keys to.|boolean: **Only get owned vehicles or all vehicles with keys to**.|
|lockpickVehicle|Start lockpicking a nearby vehicle, returns if successful or not.||
|hotwireVehicle|Start to hotwire current vehicle, returns if successful or not.||
