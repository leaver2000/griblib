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
