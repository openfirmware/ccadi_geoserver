# GeoServer Cookbook for [CCADI][]

This cookbook will install GeoServer onto a node (machine/instance) using Chef Infrastructure. Chef provides a consistent deployment process and "Infrastructure as Code" for this part of  the project.

Installs:

* [OpenJDK 17][]
* [Nginx][nginx]
* [Apache Tomcat 10.0][tomcat]
	* Apache [Tomcat native][tomcat-native] plugins
* [GDAL 3][gdal]
* [GeoServer 2.19][geoserver]
	* "GDAL" extension
	* "[Importer][importer]" extension
	* "[Monitoring][monitoring]" extension
* [certbot][] for HTTPS certificates

A *temporary* production domain will be configured under the GeoSensorWeb Lab domain at https://geoserver.ccadi.gswlab.ca/. Expect this domain to change in the future to a more permanent home with CCADI.

Any automated configuration of GeoServer is described in the "GeoServer Autoconfiguration" section below.

[ccadi]:         https://ccadi.ca/
[certbot]:       https://certbot.eff.org/
[gdal]:          https://gdal.org/
[geoserver]:     http://geoserver.org/
[importer]:      https://docs.geoserver.org/maintain/en/user/extensions/importer/index.html
[monitoring]:    https://docs.geoserver.org/maintain/en/user/extensions/monitoring/index.html
[nginx]:         https://nginx.org/en/
[OpenJDK 17]:    https://jdk.java.net/17/
[tomcat]:        https://tomcat.apache.org/
[tomcat-native]: https://tomcat.apache.org/native-doc/

## Service Components and Architecture

The main service being installed is GeoServer. This will provide data in multiple APIs to clients. As GeoServer is a Java web application, it will be deployed under Apache Tomcat servlet and HTTP server.

Tomcat provides access to the service on ports 8080 and 8443 (HTTPS). These are unprivileged ports (ports with a number greater than 1024), and this lets Tomcat run as a non-root user and improves security. To provide port 80 and 443 access (the default HTTP and HTTPS ports), Nginx is used to proxy to Tomcat and handle HTTPS.

This means Java can be run as a non-root user, limiting the access the process has to files and the system. Nginx will be running as root, but as a separate process from Java and with fewer potential security vulnerabilities. Additionally, reloading Nginx for configuration and certificate updates has less downtime than reloading Tomcat.

GDAL is installed to provide extra functionality to GeoServer using the GDAL plugin. This can accelerate some processing functions, as well as parse more input formats and sources.

## Using this cookbook to install GeoServer

TODO: Include bootstrap instructions, as well as Chef Server instructions

### Cookbook Attributes

TODO: List the attributes that can be customized to override various settings.

## Developing on this cookbook

TODO: Explain installation of Chef Workstation and making changes to this cookbook

## GeoServer Autoconfiguration (TODO)

This cookbook applies some additional automated setup steps for the GeoServer installation, making the administration of the GeoServer instance a bit more streamlined.

## License (TODO)

All rights reserved.

