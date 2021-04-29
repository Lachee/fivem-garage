# Simple ESX Garage
Customised version of a Garage Script for SkullFace's server. It provides functionality to store vehicles at different locations around Los Santos.

**Features**
- Easy to use UI
- Highly configurable 
- Store vehicles in garages across the map to be kept safely
- Optional Vehicle recovery with customisable cost ( so the vehicles are not lost when disconnected )
- Optional Vehicle towing ( teleports vehicles from the street if no players inside )
- Optional ability to take out vehicles from any garage, regardless of stored garage

<video src="https://i.lu.je/2021/0YmegSETIa.mp4"></video>
Watch an [Example MP4](https://i.lu.je/2021/0YmegSETIa.mp4) ( hosted on my CDN )

![Image showing the new circle markers](https://i.lu.je/2021/FiveM_GTAProcess_a1Ufh3YSCc.jpg)


## Via Git ( recommended )
From your resouces directory for the ESX server:
```
git clone https://github.com/Lachee/fivem-garage.git "[lachee]/lachee-garage"
```

Then in you server cfg:
- `ensure lachee-garage`

**Dont forget to remove the previous `[esx]/esx_garage` script**

**Dont forget to run the `.sql` in the `sql/` folder**

