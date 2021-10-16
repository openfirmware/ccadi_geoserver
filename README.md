# GeoServer Cookbook for [CCADI][]

This cookbook will install GeoServer onto a node (machine/instance) using Chef Infrastructure. Chef provides a consistent deployment process and "Infrastructure as Code" for this part of  the project.

Installs:

* [OpenJDK 17][]
* [Nginx][nginx]
* [Apache Tomcat 9][tomcat]
    * Apache [Tomcat native][tomcat-native] plugins
* [GDAL 3][gdal]
    * PROJ 8.1.1
    * PROJ data files (approx 600 MB)
    * SQLite 3.36.0
* [GeoServer 2.19][geoserver]
    * "[CSW][]" extension
    * "GDAL" extension
    * "[Importer][importer]" extension
    * "[Monitoring][monitoring]" extension
    * "[NetCDF Source][netcdf]" extension
    * "[WPS][]" extension
* [certbot][] for HTTPS certificates

A *temporary* production domain will be configured under the GeoSensorWeb Lab domain at https://geoserver.ccadi.gswlab.ca/. Expect this domain to change in the future to a more permanent home with CCADI.

Any automated configuration of GeoServer is described in the "GeoServer Autoconfiguration" section below.

[ccadi]:         https://ccadi.ca/
[certbot]:       https://certbot.eff.org/
[csw]:           https://docs.geoserver.org/2.19.x/en/user/services/csw/index.html
[gdal]:          https://gdal.org/
[geoserver]:     http://geoserver.org/
[importer]:      https://docs.geoserver.org/2.19.x/en/user/extensions/importer/index.html
[monitoring]:    https://docs.geoserver.org/2.19.x/en/user/extensions/monitoring/index.html
[netcdf]:        https://docs.geoserver.org/2.19.x/en/user/extensions/netcdf/netcdf.html
[nginx]:         https://nginx.org/en/
[OpenJDK 17]:    https://jdk.java.net/17/
[tomcat]:        https://tomcat.apache.org/
[tomcat-native]: https://tomcat.apache.org/native-doc/
[wps]:           https://docs.geoserver.org/2.19.x/en/user/services/wps/index.html

## Service Components and Architecture

The main service being installed is GeoServer. This will provide data in multiple APIs to clients. As GeoServer is a Java web application, it will be deployed under Apache Tomcat servlet and HTTP server.

Tomcat provides access to the service on ports 8080 and 8443 (HTTPS). These are unprivileged ports (ports with a number greater than 1024), and this lets Tomcat run as a non-root user and improves security. To provide port 80 and 443 access (the default HTTP and HTTPS ports), Nginx is used to proxy to Tomcat and handle HTTPS.

This means Java can be run as a non-root user, limiting the access the process has to files and the system. Nginx will be running as root, but as a separate process from Java and with fewer potential security vulnerabilities. Additionally, reloading Nginx for configuration and certificate updates has less downtime than reloading Tomcat.

GDAL is installed to provide extra functionality to GeoServer using the GDAL plugin. This can accelerate some processing functions, as well as parse more input formats and sources.

## Using this cookbook to install GeoServer

The primary method of deploying this cookbook is by using a central Chef Infra Server to maintain state and a versioned copies of cookbooks that are deployed to clients. Non-server deployments such as "Chef Zero" are not covered as I don't have experience using that.

Once a Chef Infra Server has been set up, a developer configures a certificate for accessing the Chef Server. Then a developer may push the latest cookbook to Chef Infra Server, assuming Chef configuration (`~/.chef`) has been set:

```
$ chef push (basename $PWD) Policyfile.rb
```

This will replace the server's copy of the cookbook, but only for the version specified in `metadata.rb`. This allows older cookbook versions to be used by stable installations.


To bootstrap a new node with this cookbook/policy, and add that new node to Chef Infra Server:

```
$ knife bootstrap geoserver.ccadi.gswlab.ca \
    --node-name geoserver \
    --connection-user centos \
    --sudo \
    -i ~/.ssh/id_rsa \
    --policy-group ccadi_geoserver \
    --policy-name ccadi_geoserver
```

In this case, `geoserver.ccadi.gswlab.ca` is the SSH address of the node for connecting the bootstrap process.

We give this node the name `geoserver` for Chef Server.

The connection user of `centos` would be different for Ubuntu/Debian.

`sudo` is used as we are not connecting as a root user.

The SSH private key in `~/.ssh/id_rsa` is used to authenticate with this node without a password prompt; this key is usually set up through your cloud provider.

The policy name and group specify the storage organization of this cookbook in Chef Server.

### Cookbook Attributes

TODO: List the attributes that can be customized to override various settings.

## Developing on this cookbook

TODO: Explain installation of Chef Workstation and making changes to this cookbook

## GeoServer Autoconfiguration (TODO)

This cookbook applies some additional automated setup steps for the GeoServer installation, making the administration of the GeoServer instance a bit more streamlined.

## License (TODO)

All rights reserved.

