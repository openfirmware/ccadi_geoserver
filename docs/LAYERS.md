# Layers Setup for GeoServer

Here is a list of some of the remote data sources that have been tested with GeoServer. Each item will list the configuration details needed to add to GeoServer, as well as information about the source and any issues with cascading through GeoServer to clients.

I plan to use this as a reference for re-setting up layers, as well as tracking down potential issues when re-serving data.

## Data Store: Arctic SDI WMS

`http://basemap.arctic-sdi.org/mapcache/wms/?request=GetCapabilities&service=wms&version=1.1.1`

Added as a test of cascading their WMS.

### Layer: Arctic SDI Base Map

Start by using the New Layer interface to publish `arctic_cascading`.

#### GeoServer OpenLayer Client

Works as expected, displaying in `EPSG:3571`.

#### QGIS 3.22 (Linux)

Works as expected, displaying in `EPSG:3571`.

## Data Store: Arctic SDI WMTS

`http://basemap.arctic-sdi.org/mapcache/wmts/?request=GetCapabilities&service=wmts`

Added as a test of cascading their WMTS. Due to the errors found below, I recommend using the WMS instead of the WMTS.

### Layer: Arctic SDI Base Map

Start by using the New Layer interface to publish `arctic_cascading`.

#### GeoServer OpenLayer Client

The map is rendered with an **error**:

```
Error rendering coverage on the fast path
java.lan.RuntimeException: No tiles were found in requested extent
No tiles were found in requested extent
```

#### QGIS 3.16 (MacOS)

**Error:** For WMS from this GeoServer, QGIS adds the layer but the map remains empty. Changing from `EPSG:4326` to `EPSG:3571` projection has no effect.

## Data Store: Arctic Web Map (as WMS)

`http://tiles.arcticconnect.ca/mapproxy/service?REQUEST=GetCapabilities`

Arctic Web Map is the custom polar-focused map tiles and data (from OpenStreetMap Contributors and others). It is available via a web API for XYZ slippy tiles system (using the `mod_tile` system) or via WMS/WMTS (using the `mapproxy` system). We will use the latter to cascade.

Note: Using the WMTS data source instead is not recommended. It seems to cause clients to get repeated attribution labels across the map tiles. Rendering from the WMS to this GeoServer's WMS/WMTS/GWC is less "buggy" and has higher map image quality (no scaling/interpolation).

### Layer: Arctic Web Map v2

Start by using the New Layer interface to publish `awm2`. In the layer configuration, ensure the SRS is `EPSG:3573`. The bounding boxes can use "Compute from data" and "Compute from native bounds".

WMS Attribution should be "ArcticConnect, OpenStreetMap Contributors".

Tile caching can be configured with GeoWebCache (GWC), although you should start by having an `EPSG:3573` gridset created in GWC. To use this tile cache, the GeoWebCache endpoint must be used instead of the standard GeoServer WMS/WMTS.

#### GeoServer OpenLayer Client

Map renders fine with WMS 1.1.1.

#### QGIS 3.22 (Linux)

Via WMS from this GeoServer, the layer loads normally when using `EPSG:3573` projection. Any slowdowns loading tiles are from the parent ArcticWebMap tile server, particularly for uncached regions.

Via WMTS, the `image/jpeg` layer works as expected.

Via WMTS, the `image/png` layer works as expected.

## Data Store: GEBCO

`https://www.gebco.net/data_and_products/gebco_web_services/web_map_service/mapserv`

### Layer: GEBCO Grid shaded relief

Start by using the New Layer interface to publish `GEBCO_LATEST`.

#### GeoServer OpenLayer Client

Map renders fine with WMS 1.1.1.

#### QGIS 3.22 (Linux)

Via WMS from this GeoServer, the layer loads normally when using `EPSG:4326` projection. It also reprojects cleanly to `EPSG:3857` and `EPSG:3573`.

WMTS `image/jpeg` works.

WMTS `image/png` works.

## Data Store: NSIDC

`https://nsidc.org/api/mapservices/NSIDC/wms`

### Layer: Northern Hemisphere Daily Sea Ice Concentration

Start by using the New Layer interface to publish `g02135_concentration_raster_daily_n`. Set the projections both to `EPSG:3573` (or your choice).

#### GeoServer OpenLayer Client

Map renders fine with WMS 1.1.1. OpenLayers will use the "Declared" projection set on the layer.

#### QGIS 3.22 (Linux)

Via WMS from this GeoServer, the layer loads normally when using `EPSG:3573` projection.

WMTS `image/jpeg` works.

WMTS `image/png` works.

## Data Store: Soper's World

`https://maps.arcticconnect.ca/geoserver/ows?service=wms&version=1.3.0&request=GetCapabilities`

This project is for an interactive web application that lets readers follow the expeditions of naturalist Dewey Soper in the early 20th century. To provide non-mercator maps for the visualizations, a WMS/WMTS GeoServer was configured to serve a base map and a georeferenced hand-drawn map. This service is ran by the Arctic Institute of North America.

### Layer: Soper's World Base Map

Start by using the New Layer interface to publish `base_map_3573`.

#### GeoServer OpenLayer Client

Map loads, but very slowly (due to upstream server). As this GeoServer's primary WMS endpoint is not cached, it is not the recommended way to load this layer. Instead, the GeoWebCache WMS/WMTS endpoint should be used.

The GWC layer preview loads very quickly once the cache is filled.

#### QGIS 3.22 (Linux)

Via WMS from this GeoServer, the layer loads normally when using `EPSG:3573` projection.

WMTS `image/jpeg` works.

WMTS `image/png` works.

### Layer: Dewey Soper's Hand Drawn Map

Start by using the New Layer interface to publish `soper_3413`.

The layer SRS must be changed to `EPSG:3413`.

#### GeoServer OpenLayer Client

Map loads.

#### QGIS 3.22 (Linux)

Via WMS, the map renders correctly.

**Error:** Via WMTS, a bottom section of the hand-drawn map is missing.
