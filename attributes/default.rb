# Primary Attributes

# One or more domains to map as virtual hosts in nginx to point to Tomcat on port 80
# If certbot is enabled, then it will try to retrieve a certificate for each one.
default["ccadi_geoserver"]["domains"]     = ["geoserver.ccadi.gswlab.ca"]
# Location to store source files for compilation
default["ccadi_geoserver"]["source_path"] = "/opt/src"

# For some tasks that can be parallelized, this many "jobs" should be used.
# This should probably match the number of cores/VCPUs.
default["jobs"] = 4

# IBM Semeru (JDK 11)
default["openjdk"]["version"]      = "11.0.12+7"
default["openjdk"]["prefix"]       = "/opt/java"
default["openjdk"]["download_url"] = "https://github.com/ibmruntimes/semeru11-binaries/releases/download/jdk-11.0.12%2B7_openj9-0.27.0/ibm-semeru-open-jdk_x64_linux_11.0.12_7_openj9-0.27.0.tar.gz"
default["openjdk"]["checksum"]     = "4c2d776f69e3ff7d01cd57c0938b7a7f058264425faf18e3708b905e93f915c4"

# Apache Tomcat
default["tomcat"]["version"]      = "9.0.53"
default["tomcat"]["user"]         = "tomcat"
default["tomcat"]["Xms"]          = "256m"
default["tomcat"]["Xmx"]          = "4g"
default["tomcat"]["prefix"]       = "/opt/tomcat"
default["tomcat"]["download_url"] = "https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.53/bin/apache-tomcat-9.0.53.tar.gz"
# Manually calculated SHA256:
default["tomcat"]["checksum"]     = "7b3e456ed76b0b42d99767985dc3774b22e2388834994f8539272eb7c05ab6fd"

# Apache Tomcat native plugin
default["tomcat-native"]["version"]      = "1.2.31"
default["tomcat-native"]["prefix"]       = "/opt/tomcat"
default["tomcat-native"]["download_url"] = "https://archive.apache.org/dist/tomcat/tomcat-connectors/native/1.2.31/source/tomcat-native-1.2.31-src.tar.gz"
# Manually calculated SHA256:
default["tomcat-native"]["checksum"]     = "acc0e6e342fbdda54b029564405322823c93d83f9d64363737c1cbcc3af1c1fd"

# Certbot
default["certbot"]["enabled"]        = true
default["certbot"]["email"]          = "jpbadger@ucalgary.ca"
default["certbot"]["challenge_path"] = "/usr/share/nginx/html/.well-known/acme-challenge"

# SQLite
default["sqlite"]["download_url"] = "https://sqlite.org/2021/sqlite-autoconf-3360000.tar.gz"
# Manually calculated SHA256:
default["sqlite"]["checksum"]     = "bd90c3eb96bee996206b83be7065c9ce19aef38c3f4fb53073ada0d0b69bbce3"
default["sqlite"]["prefix"]       = "/opt/local"

# PROJ
default["proj"]["download_url"]  = "https://download.osgeo.org/proj/proj-8.1.1.tar.gz"
# Manually calculated SHA256:
default["proj"]["checksum"]      = "82f1345e5fa530c407cb1fc0752e83f8d08d2b98772941bbdc7820241f7fada2"
default["proj"]["prefix"]        = "/opt/local"

# Ant
default["ant"]["version"]       = "1.10.12"
default["ant"]["prefix"]        = "/opt/java"
default["ant"]["download_url"]  = "https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.12-bin.tar.gz"
# Manually calculated SHA256:
default["ant"]["checksum"]      = "4b3b557279bae4fb80210a5679180fdae3498b44cfd13368e3386e2a21dd853b"

# GDAL
default["gdal"]["version"]       = "3.3.2"
default["gdal"]["download_url"]  = "https://github.com/OSGeo/gdal/releases/download/v3.3.2/gdal-3.3.2.tar.gz"
# Manually calculated SHA256:
default["gdal"]["checksum"]      = "f2097ea6e3ccc07c0b3663b86393b7affde3db92ca92508ab972a029b865a96c"
default["gdal"]["prefix"]        = "/opt/local"

# GeoServer
# Checksums are manually calculated SHA256.
default["geoserver"]["version"]                           = "2.19.2"
default["geoserver"]["prefix"]                            = "/opt/geoserver"
default["geoserver"]["download_url"]                      = "http://sourceforge.net/projects/geoserver/files/GeoServer/2.19.2/geoserver-2.19.2-war.zip"
default["geoserver"]["checksum"]                          = "d84c75a55e77cc40a198470014d14983fbcb204dec253d7482b81f1c701f9f3f"
default["geoserver"]["data_dir"]                          = "/opt/geoserver/data"
default["geoserver"]["csw_plugin"]["download_url"]        = "http://sourceforge.net/projects/geoserver/files/GeoServer/2.19.2/extensions/geoserver-2.19.2-csw-plugin.zip"
default["geoserver"]["csw_plugin"]["checksum"]            = "1215a440b71a71897d2dfc9dadee54d7e4f0c08b9e58403d524869e6ef42fe6a"
default["geoserver"]["gdal_plugin"]["download_url"]       = "http://sourceforge.net/projects/geoserver/files/GeoServer/2.19.2/extensions/geoserver-2.19.2-gdal-plugin.zip"
default["geoserver"]["gdal_plugin"]["checksum"]           = "ce98090783e13fb6073e571d674fbaac7ac2276346b4aa72032ea130400bc469"
default["geoserver"]["monitoring_plugin"]["download_url"] = "http://sourceforge.net/projects/geoserver/files/GeoServer/2.19.2/extensions/geoserver-2.19.2-monitor-plugin.zip"
default["geoserver"]["monitoring_plugin"]["checksum"]     = "4a7823e1059c255f43c7a0d1fc5b28436993b77292d3c20619aef6eb82dcf8db"
default["geoserver"]["netcdf_plugin"]["download_url"]     = "http://sourceforge.net/projects/geoserver/files/GeoServer/2.19.2/extensions/geoserver-2.19.2-netcdf-plugin.zip"
default["geoserver"]["netcdf_plugin"]["checksum"]         = "5c22db7150ff92fc6957b80373ea22a1a433d64c768a101f953e28ca5adc1697"
default["geoserver"]["wps_plugin"]["download_url"]        = "http://sourceforge.net/projects/geoserver/files/GeoServer/2.19.2/extensions/geoserver-2.19.2-wps-plugin.zip"
default["geoserver"]["wps_plugin"]["checksum"]            = "dc367278d4143952ff4c711600e083ffa72a80a47a4701ce98b4f36a219700ff"

# GeoServer global configuration
# This values are only set on the first installation and will NOT overwrite
# values updated later through the web UI.
default["geoserver"]["address"]["city"]         = "Calgary"
default["geoserver"]["address"]["country"]      = "Canada"
default["geoserver"]["address"]["type"]         = "Work"
default["geoserver"]["contact"]["organization"] = "GeoSensor Web Lab, Geomatics Engineering, University of Calgary"
default["geoserver"]["contact"]["person"]       = "James Badger"
default["geoserver"]["contact"]["email"]        = "jpbadger@ucalgary.ca"
default["geoserver"]["contact"]["position"]     = "Research Associate"

default["geoserver"]["num_decimals"]       = 8
default["geoserver"]["verbose"]            = false
default["geoserver"]["verbose_exceptions"] = false
default["geoserver"]["proxy_base_url"]     = "https://geoserver.ccadi.gswlab.ca/geoserver"

default["geoserver"]["jai"]["allow_interpolation"] = false
default["geoserver"]["jai"]["recycling"]           = false
default["geoserver"]["jai"]["tile_priority"]       = 5
default["geoserver"]["jai"]["tile_threads"]        = 7
default["geoserver"]["jai"]["memory_capacity"]     = 0.5
default["geoserver"]["jai"]["memory_threshold"]    = 0.75
default["geoserver"]["jai"]["image_io_cache"]      = false
default["geoserver"]["jai"]["png_acceleration"]    = true
default["geoserver"]["jai"]["jpeg_acceleration"]   = true
default["geoserver"]["jai"]["allow_native_mosaic"] = false
default["geoserver"]["jai"]["allow_native_warp"]   = false

# Replacement "master password" for GeoServer
default["geoserver"]["masterpw"] = "digest1:IFus7DrdapMz6GBCP0A9rM8Xrrxu52z6vgib6sxwzW20SaoqHA8Y3H1MRch8zeOJ"
