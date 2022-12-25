![NDVehicleSystem](https://user-images.githubusercontent.com/86536434/200143075-342da3a9-2304-4001-a1d7-fdb59936f912.png)


## Features:
* Own vehicles and store in garages.
* Land vehicle garages, helicopters, boats, and planes.
* Lock/Unlock vehicles with a key system.
* Share your vehicle keys with players.
* Lockpick vehicles.
* Hotwire vehicles
* Disable vehicle air control.
* Lock traffic & parked vehicles.
* Cruise control.
* Transfer ownership of vehicles.
* Save vehicle wheel angle.

## Exports:

**Server:**
|Export|Description|Parameter(s)|
|-|-|-|
|setVehicleOwned|save a vehicle to a character.|int: **Player source**, table: **vehicle properties**, boolean: **in garage or not**.|
|getVehicles|Get the vehicles a characater owns.|int: **ND Character id**.|
|giveKeys|Give keys vehicle keys to a player.|int: **Vehicle entity**, int: **Player source**, int: **Target player source**.|
|spawnOwnedVehicle|Spawn a vehicle the player owns.|int: **Player source**, int: **vehicle ID**, vec3: **Spawn coords**.|
|returnVehicleToGarage|Give keys vehicle keys to a player.|int: **Player source**, int: **Vehicle entity**, table: **vehicle properties**.|
|transferVehicle|Transfer a vehicle to another player.|int: **Vehicle database ID**, int: **Player source**, int: **Target player source**.|
|saveVehicleProperties|Save the vehicle properties.|int: **Player source**, int: **Vehicle entity**, table: **vehicle properties**.|

**Client:**
|Export|Description|Parameter(s)|
|-|-|-|
|getVehicleOwned|Check if a vehicle is owned by any player.|int: **Vehicle entity**.|
|isVehicleOwned|Check if the player owns the vehicle.|int: **Vehicle entity**.|
|hasVehicleKeys|Check if the player has keys to the vehicle.|int: **Vehicle entity**.|
|getClosestVehicle|Get the closest vehicle the player has keys to, the distance of the vehicle and player, and the coords of the vehicle.|boolean: **Only get owned vehicles or all vehicles with keys to**.|
|getVehicleLocked|Check if the vehicle is locked or unlocked.|int: **Vehicle entity**.|
|setVehicleLocked|Set the vehicle lock status.|int: **Vehicle entity**, boolean: **Locked or unlocked**.|
|lockpickVehicle|Begin lockpicking a nearby vehicle, returns if successful or not.||
|hotwireVehicle|Begin to hotwire current vehicle, returns if successful or not.||
