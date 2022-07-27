# NOAA/CIMSS ProbSevere 

ProbSevere is a rapidly updating real-time system, which integrates remotely sensed observations of thunderstorms and mesoscale NWP, producing short-term probabilistic guidance of future severity. Specifically, ProbSevere predicts the probabilities of severe hail, severe wind, tornado, or any severe weather in the next 60 minutes for every storm over the CONUS.

This python module attemps to extend the ProbSevere model by applying various storm motion vectors.


![image](https://user-images.githubusercontent.com/76945789/135806503-02ba51bd-9af2-499a-81b1-9089104fe9a1.png)


![image](https://user-images.githubusercontent.com/76945789/135806799-35f2f394-6e1c-4561-bedc-11a1171b23bc.png)


PSv3 uses a new machine-learning model, and incorporates SPC mesoanalysis, GOES-16 GLM, additional GOES-16 ABI data, and additional MRMS data.
Spatial patterns in 0.64-µm ref., 10.3-µm BT, and GLM flash-extent density are incorporated

PSv3 is more skillful and better-calibrated than PSv2.
The best probability thresholds (i.e., where CSI is maximized) are lower for PSv3 (~40-60%) vs. PSv2 (~60-80%).
Forecasters will notice threatening storms have lower probabilities in v3, compared to v2. 

It may be more difficult to determine what caused a change in the probability.
We are working on display methods for better interpretability for users.

## ProbSevere v3 models

The four models are gradient-boosted decision-tree classifiers

inpust sourcesL MRMS, ENTLN, GOES-East and SPC mesoanalysis


![image](https://user-images.githubusercontent.com/76945789/135807413-ab4a1e03-4b70-4889-aef2-3a77e5287d05.png),![image](https://user-images.githubusercontent.com/76945789/135807429-9da75b62-5a7d-4de5-9ba5-8d27011b0a91.png)

![image](https://user-images.githubusercontent.com/76945789/135807446-aea541f4-7c88-4cc7-8d2a-cb4708410603.png),![image](https://user-images.githubusercontent.com/76945789/135807455-ea2d5bef-b200-43b6-b5f9-b7870c925605.png)


https://cimss.ssec.wisc.edu/satellite-blog/archives/34480

https://journals.ametsoc.org/view/journals/wefo/aop/WAF-D-20-0028.1/WAF-D-20-0028.1.xml



## PSv3 improvement over PSv2


![image](https://user-images.githubusercontent.com/76945789/135807720-978cf8aa-93a0-4061-90a9-730785404d1d.png)


### example 


``` json
{"source":"NOAA/NCEP Central Operations",
 "product":"ProbSevere",
 "validTime":"20220716_230041 UTC",
 "productionTime":"20220716_230226 UTC",                  
 "machine":"vm-bldr-mrms-ops-probsvr1.ncep.noaa.gov",
 "type":"FeatureCollection",
 "features":[
   {"type": "Feature",
   "geometry": {
     "type": "Polygon",
     "coordinates":[[[-80.98,26.74],[-80.96,26.74],[-80.93,26.72],[-80.93,26.70],[-80.96,26.67],[-80.99,26.67],[-81.00,26.68],[-81.00,26.72],[-80.98,26.74]]]
   },
   "models": {
     "probsevere": {
       "PROB":"1",
       "LINE01":"ProbHail: 0%; ProbWind: 1%; ProbTor: 0%",
       "LINE02":"- MESH: 0.00 in.",
       "LINE03":"- VIL Density: 0.91 g/m^3",
       "LINE04":"- Flash Rate: 0 fl/min",
       "LINE05":"- Flash Density (max in last 30 min): 0.03 fl/min/km^2",
       "LINE06":"- Max LLAzShear: 0.002 /s",
       "LINE07":"- 98% LLAzShear: 0.002 /s",
       "LINE08":"- 98% MLAzShear: 0.001 /s",
       "LINE09":"- Norm. vert. growth rate: N/A",
       "LINE10":"- EBShear: 16.3 kts; SRH 0-1km AGL: 27 m^2/s^2",
       "LINE11":"- MUCAPE: 2168 J/kg; MLCAPE: 1690 J/kg; MLCIN: -8 J/kg",
       "LINE12":"- MeanWind 1-3kmAGL: 8.5 kts",
       "LINE13":"- Wetbulb 0C hgt: 14.5 kft AGL",
       "LINE14":"- CAPE -10C to -30C: 325 J/kg; PWAT: 2.5 in.",
       "LINE15":"Avg. beam height (ARL): 6.27 kft / 1.91 km"
     },
     "probtor": {
       "PROB":"0",
       "LINE01":"ProbTor: 0%",
       "LINE02":"- Max LLAzShear: 0.002 /s (weak)",
       "LINE03":"- 98% LLAzShear: 0.002 /s (weak)",
       "LINE04":"- 98% MLAzShear: 0.001 /s (weak)",
       "LINE05":"- Flash Density: 0.03 fl/min/km^2",
       "LINE06":"- SRH 0-1km AGL: 27 m2/s2",
       "LINE07":"- EBShear: 16.3 kts",
       "LINE08":"- MeanWind 1-3kmAGL: 8.5 kts",
       "LINE09":"- MLCAPE/MLCIN: 1690/-8 J/kg",
       "LINE10":"Avg. beam height (ARL): 6.27 kft / 1.91 km"
     },
     "probhail": {
       "PROB":"0",
       "LINE01":"ProbHail: 0%",
       "LINE02":"- MESH: 0.00 in.",
       "LINE03":"- Flash Rate: 0 fl/min",
       "LINE04":"- Norm. vert. growth rate: N/A",
       "LINE05":"- EBShear: 16.3 kts",
       "LINE06":"- CAPE -10C to -30C: 325 J/kg",
       "LINE07":"- PWAT: 2.5 in.",
       "LINE08":"- Wetbulb 0C hgt: 14.5 kft AGL"
     },
     "probwind": {
       "PROB":"1",
       "LINE01":"ProbWind: 1%",
       "LINE02":"- MESH: 0.00 in.",
       "LINE03":"- VIL Density: 0.91 g/m^3",
       "LINE04":"- Flash Rate: 0 fl/min",
       "LINE05":"- 98% LLAzShear: 0.002 /s (weak)",
       "LINE06":"- 98% MLAzShear: 0.001 /s (weak)",
       "LINE07":"- Norm. vert. growth rate: N/A",
       "LINE08":"- EBShear: 16.3 kts",
       "LINE09":"- MeanWind 1-3kmAGL: 8.5 kts",
       "LINE10":"- MUCAPE: 2168 J/kg; MLCAPE: 1690 J/kg"
     }
   },
   "properties": {
     "MUCAPE":"2168",
     "MLCAPE":"1690",
     "MLCIN":"-8",
     "EBSHEAR":"16.3",
     "SRH01KM":"27",
     "MEANWIND_1-3kmAGL":"8.5",
     "MESH":"0.00",
     "VIL_DENSITY":"0.91",
     "FLASH_RATE":"0",
     "FLASH_DENSITY":"0.03",
     "MAXLLAZ":"0.002",
     "P98LLAZ":"0.002",
     "P98MLAZ":"0.001",
     "MAXRC_EMISS":"N/A",
     "MAXRC_ICECF":"N/A",
     "WETBULB_0C_HGT":"14.5",
     "PWAT":"2.5",
     "CAPE_M10M30":"325",
     "LJA":"0.0",
     "SIZE":"50",
     "AVG_BEAM_HGT":"6.27 kft / 1.91 km",
     "MOTION_EAST":"-1.714",
     "MOTION_SOUTH":"-7.32",
     "PS":"0",
     "ID":"362106"
   }},
   ...]
 }

```

## define props

``` json
 "properties": {
   "MUCAPE":"2168",
   "MLCAPE":"1690",
   "MLCIN":"-8",
   "EBSHEAR":"16.3",
   "SRH01KM":"27",
   "MEANWIND_1-3kmAGL":"8.5",
   "MESH":"0.00",
   "VIL_DENSITY":"0.91",
   "FLASH_RATE":"0",
   "FLASH_DENSITY":"0.03",
   "MAXLLAZ":"0.002",
   "P98LLAZ":"0.002",
   "P98MLAZ":"0.001",
   "MAXRC_EMISS":"N/A",
   "MAXRC_ICECF":"N/A",
   "WETBULB_0C_HGT":"14.5",
   "PWAT":"2.5",
   "CAPE_M10M30":"325",
   "LJA":"0.0",
   "SIZE":"50",
   "AVG_BEAM_HGT":"6.27 kft / 1.91 km",
   "MOTION_EAST":"-1.714",
   "MOTION_SOUTH":"-7.32",
   "PS":"0",
   "ID":"362106"
 }
 ```
 
 - cape: convective available potential energy
 - 
 ### MUCAPE (stability)
  most unstable (lowest 300-mb of the atmosphere) -> lifted to LFC .
  
 ### MLCAPE (stability)
  mixed layer (lowest 100mb) -> lifted to LFC.
  
 ### MLCIN (stability)
   mixed layer (lowest 100mb) -> convective INhibition "negative" area on a suding that must be overcome before storm initation can occcur.
   
 ### CAPE_M10M30 (stability)
 
 ### EBSHEAR (SWI)
  The magnitude of the vector wind difference from the effective inflow base upward to 50% of the equilibrium level height for the most unstable parcel in the lowest 300 mb. 
![image](https://user-images.githubusercontent.com/76945789/179429991-569dd3fd-7c5d-4547-b7a6-868217c6a8f1.png)

  
 ### SRH01KM (SWI)
 
 ### MESH (lift)
 
 ### VIL_DENSITY (lift)
 
 ### MAXRC_EMISS (growth)
 
 ### MAXRC_ICECF (growth)
 
 
 ### PWAT (moisture)
 
