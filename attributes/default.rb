# Primary Attributes

# One or more domains to map as virtual hosts in nginx to point to Tomcat on port 80
# If certbot is enabled, then it will try to retrieve a certificate for each one.
default["ccadi_geoserver"]["domains"]     = ["geoserver.ccadi.gswlab.ca"]
# Location to store source files for compilation
default["ccadi_geoserver"]["source_path"] = "/opt/src"

# For some tasks that can be parallelized, this many "jobs" should be used.
# This should probably match the number of cores/VCPUs.
default["jobs"] = 4

# OpenJDK
default["openjdk"]["version"]       = "17"
default["openjdk"]["prefix"]        = "/opt/java"
default["openjdk"]["download_url"]  = "https://download.java.net/java/GA/jdk17/0d483333a00540d886896bac774ff48b/35/GPL/openjdk-17_linux-x64_bin.tar.gz"
default["openjdk"]["checksum_url"]  = "https://download.java.net/java/GA/jdk17/0d483333a00540d886896bac774ff48b/35/GPL/openjdk-17_linux-x64_bin.tar.gz.sha256"
default["openjdk"]["checksum_type"] = "SHA256"

# Apache Tomcat
default["tomcat"]["version"]       = "9.0.53"
default["tomcat"]["user"]          = "tomcat"
default["tomcat"]["Xms"]           = "256m"
default["tomcat"]["Xmx"]           = "4g"
default["tomcat"]["prefix"]        = "/opt/tomcat"
default["tomcat"]["download_url"]  = "https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.53/bin/apache-tomcat-9.0.53.tar.gz"
default["tomcat"]["checksum_url"]  = "https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.53/bin/apache-tomcat-9.0.53.tar.gz.sha512"
default["tomcat"]["checksum_type"] = "SHA512"

# Certbot
default["certbot"]["enabled"]        = true
default["certbot"]["email"]          = "jpbadger@ucalgary.ca"
default["certbot"]["challenge_path"] = "/usr/share/nginx/html/.well-known/acme-challenge"

# SQLite
default["sqlite"]["download_url"] = "https://sqlite.org/2021/sqlite-autoconf-3360000.tar.gz"
default["sqlite"]["prefix"]       = "/opt/local"

# PROJ
default["proj"]["download_url"]  = "https://download.osgeo.org/proj/proj-8.1.1.tar.gz"
default["proj"]["checksum_url"]  = "https://download.osgeo.org/proj/proj-8.1.1.tar.gz.md5"
default["proj"]["checksum_type"] = "MD5"
default["proj"]["prefix"]        = "/opt/local"

# Ant
default["ant"]["version"]       = "1.10.11"
default["ant"]["prefix"]        = "/opt/java"
default["ant"]["download_url"]  = "https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.11-bin.tar.gz"
default["ant"]["checksum_url"]  = "https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.11-bin.tar.gz.sha512"
default["ant"]["checksum_type"] = "SHA512"

# GDAL
default["gdal"]["version"]       = "3.3.2"
default["gdal"]["download_url"]  = "https://github.com/OSGeo/gdal/releases/download/v3.3.2/gdal-3.3.2.tar.gz"
default["gdal"]["checksum_url"]  = "https://github.com/OSGeo/gdal/releases/download/v3.3.2/gdal-3.3.2.tar.gz.md5"
default["gdal"]["checksum_type"] = "MD5"
default["gdal"]["prefix"]        = "/opt/local"

# GeoServer
default["geoserver"]["version"]                           = "2.19.2"
default["geoserver"]["prefix"]                            = "/opt/geoserver"
default["geoserver"]["download_url"]                      = "http://sourceforge.net/projects/geoserver/files/GeoServer/2.19.2/geoserver-2.19.2-war.zip"
default["geoserver"]["gdal_plugin"]["download_url"]       = "http://sourceforge.net/projects/geoserver/files/GeoServer/2.19.2/extensions/geoserver-2.19.2-gdal-plugin.zip"
default["geoserver"]["monitoring_plugin"]["download_url"] = "http://sourceforge.net/projects/geoserver/files/GeoServer/2.19.2/extensions/geoserver-2.19.2-monitor-plugin.zip"
default["geoserver"]["netcdf_plugin"]["download_url"]     = "http://sourceforge.net/projects/geoserver/files/GeoServer/2.19.2/extensions/geoserver-2.19.2-netcdf-plugin.zip"
