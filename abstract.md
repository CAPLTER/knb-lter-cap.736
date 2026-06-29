This dataset is part of a collection of 1-m resolution Mean Radiant Temperature
(Tmrt) and shade raster files generated using digital surface models and the
Solar and LongWave Environmental Irradiance Geometry (SOLWEIG) model. The
dataset provides hourly Tmrt and shade estimates from 07:00 to 20:00 Mountain
Standard Time for three Phoenix Area Social Survey
([PASS](https://globalfutures.asu.edu/caplter/wp-content/uploads/sites/33/2024/08/PASS2021report_final-1.pdf))
neighborhood areas in metropolitan Phoenix, Arizona, identified as **711**,
**W15**, and **U18**. The data cover **15 clear-sky days** across **five
months** in **2025**, with **three selected days per month** from **May through
September**, representing the transition into, during, and out of the summer
heat season. This dataset particularly features the shade data from the study,
with the Tmrt available at: [placeholder]

For each selected day and hour, the dataset includes both mean radiant
temperature (Tmrt) and shade raster files. The shade rasters represent
shade from buildings and vegetation. Because the PASS neighborhood
boundaries are irregularly shaped, each neighborhood was first enclosed
within a rectangular bounding box. Each bounding box was then expanded
outward by 5 km in all directions to create a buffered study area. These
buffered areas were used to support analysis of route types that
originate within the neighborhoods and extend to destinations outside
them. The raster data cover the full buffered study areas. Neighborhood
boundary maps are also provided with the dataset so that users can
extract Tmrt or shade data specifically within the original neighborhood
boundaries. The unit of Tmrt is degrees Celsius (°C). The shade rasters
are binary, with values of 1 indicating no shade and values of 0
indicating shade.

This dataset extends prior 1-m Tmrt raster products for Maricopa County by
adding multi-day seasonal coverage and paired shade information at the
neighborhood scale. It can support studies of pedestrian heat exposure,
neighborhood-scale heat vulnerability, tree and building shade benefits, and the
design and evaluation of urban heat mitigation strategies.
