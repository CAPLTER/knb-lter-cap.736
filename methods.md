We used the SOLWEIG model to estimate Mean Radiant Temperature (MRT).
SOLWEIG requires three surface models --- a Digital Elevation Model
(DEM), a Building Surface Model (BSM), and a Canopy Digital Surface
Model (CDSM) --- along with meteorological forcing data. The surface
models were generated from high-resolution LiDAR Point Cloud (LPC) data
obtained from the USGS. Meteorological inputs, including air
temperature, wind speed, relative humidity, and solar radiation, were
sourced from the Phoenix Encanto weather station which is part of the
AZMet network.

The DEM was derived from ground points only, while the BSM was generated
by masking a full surface model with building footprints from Microsoft.
Non-building areas were filled with DEM values. The CDSM was created by
subtracting the DEM from the full surface model for non-building pixels,
with building pixels set to zero. All pixels with canopy heights less
than or equal to 1.3 m were also set to zero, as they were not
considered vegetation canopy. Direct and diffuse shortwave radiation
components were estimated within SOLWEIG.

For each selected date and hour, SOLWEIG was used to generate 1-m
resolution Tmrt rasters and corresponding shade rasters. The shade
rasters represent areas shaded by buildings and vegetation canopy.

The dataset covers five months from May through September 2025. For each
month, three clear-sky days were selected to represent the early,
middle, and late portions of the month, resulting in 15 selected days.
For each selected day, hourly outputs were generated from 07:00 to 20:00
Mountain Standard Time. The dates can be found in the following table.

  ----------------------------------------------------------------------------------------------------------------------------
  Month                                                                          Dates
  ------------------------------------------------------------------------------ ---------------------------------------------
  [May](https://world-weather.info/forecast/usa/phoenix/may-2025/)               6, 15, 25

  [June](https://world-weather.info/forecast/usa/phoenix/june-2025/)             5, 15, 25

  [July](https://world-weather.info/forecast/usa/phoenix/july-2025/)             5, 14, 26

  [August](https://world-weather.info/forecast/usa/phoenix/august-2025/)         4, 16, 29

  [September](https://world-weather.info/forecast/usa/phoenix/september-2025/)   6, 15, 24
  ----------------------------------------------------------------------------------------------------------------------------
