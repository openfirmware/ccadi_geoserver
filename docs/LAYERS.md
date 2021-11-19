# Layers Setup for GeoServer

Here is a list of some of the remote data sources that have been tested with GeoServer. Each item will list the configuration details needed to add to GeoServer, as well as information about the source and any issues with cascading through GeoServer to clients.

I plan to use this as a reference for re-setting up layers, as well as tracking down potential issues when re-serving data.

## Data Store: Arctic SDI

`http://basemap.arctic-sdi.org/mapcache/wmts/?request=GetCapabilities&service=wmts`

Added as a test of cascading their WMTS.

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

## Data Store: Arctic Web Map

`http://tiles.arcticconnect.ca/mapproxy/service?REQUEST=GetCapabilities`

Arctic Web Map is the custom polar-focused map tiles and data (from OpenStreetMap Contributors and others). It is available via a web API for XYZ slippy tiles system (using the `mod_tile` system) or via WMS/WMTS (using the `mapproxy` system). We will use the latter to cascade.

### Layer: Arctic Web Map v2

Start by using the New Layer interface to publish `awm2`. In the layer configuration, ensure the SRS is `EPSG:3573`. The bounding boxes can use "Compute from data" and "Compute from native bounds".

WMS Attribution should be "ArcticConnect, OpenStreetMap Contributors".

Tile caching can be configured with GeoWebCache (GWC), although you should start by having an `EPSG:3573` gridset created in GWC. To use this tile cache, the GeoWebCache endpoint must be used instead of the standard GeoServer WMS/WMTS.

#### GeoServer OpenLayer Client

Map renders fine with WMS 1.1.1.

#### QGIS 3.16 (MacOS)

Via WMS from this GeoServer, the layer loads normally when using `EPSG:3573` projection. Any slowdowns loading tiles are from the parent ArcticWebMap tile server, particularly for uncached regions.

**Error:** Via WMTS, the `image/jpeg` layer is "added" but nothing is displayed on the map and no errors are shown.

**Bug:** Via WMTS, the `image/png` layer is shown on the map. The quality is not good and may be due to scaling/resolution differences between the client and the server's gridsets. Attribution is also repeated across the image.

