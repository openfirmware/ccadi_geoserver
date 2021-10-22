# GeoServer Cookbook for [CCADI][]

This cookbook will install GeoServer onto a node (machine/instance) using Chef Infrastructure. Chef provides a consistent deployment process and "Infrastructure as Code" for this part of  the project.

Installs:

* [IBM Semeru Java 11 Development Kit][IBM Semeru]
    * (GeoServer is not yet compatible with OpenJDK 17)
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
[IBM Semeru]:    https://developer.ibm.com/languages/java/semeru-runtimes/
[importer]:      https://docs.geoserver.org/2.19.x/en/user/extensions/importer/index.html
[monitoring]:    https://docs.geoserver.org/2.19.x/en/user/extensions/monitoring/index.html
[netcdf]:        https://docs.geoserver.org/2.19.x/en/user/extensions/netcdf/netcdf.html
[nginx]:         https://nginx.org/en/
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

Instead of hard-coding the configuration values for the server software, we use the "[attributes][Chef Components]" system in Chef Infrastructure. This lets us set default values for software (such as versions, installation options, directory structure), as well as override those values later without having to update the cookbook.

[Chef Components]: https://docs.chef.io/chef_overview/#components

The default values for this cookbook are specified in the `attributes/default.rb` file. Most of the attributes are values normally customized when installing server software, and the attributes are grouped and named according to their source application/tool's terminology.

An additional layer of default values is applied for "Test Kitchen" virtual machines used for testing this cookbook; these values are specified in `kitchen.yml` in the suite attributes section.

## Developing on this cookbook

This Chef Infrastructure cookbook can be cloned using Git to your local development machine. From there, you should install [Chef Workstation][] to have access to the development tools necessary for testing and deploying this cookbook.

[Chef Workstation]: https://docs.chef.io/workstation/

For local testing using a virtual machine, this cookbook is set up to use VirtualBox with Vagrant. It may be necessary for you to modify this if you are developing from a non-x86 machine.

Versioning of the cookbook is specified in the `metadata.rb` file, and can be used to have multiple versions installed on a Chef Infrastructure Server. These multiple versions can be deployed to different servers. Note that Chef Infra *does not* use Git's tags or metadata for pushing cookbooks to Chef Server, and Chef will merely push the working tree (excluding any files/folders matching `chefignore`).

## GeoServer Autoconfiguration

This cookbook applies some additional automated setup steps for the GeoServer installation, making the administration of the GeoServer instance a bit more streamlined.

* The default GeoServer password is changed away from `admin:geoserver`
* The service configurations for CSW, WCS, WFS, WMS, and WPS will include CCADI information
* The included sample layers for GeoServer are automatically removed
* The server administration information has been updated
* Adjusts some configuration values for Java Advanced Imaging API
* Installs more EPSG code definitions
* Relocates GeoServer data directory to outside of GeoServer application directory

User accounts, stores, layers, etc must still be configured through the web UI.

## License (TODO)

All rights reserved.

