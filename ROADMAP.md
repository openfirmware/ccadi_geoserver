# Development Roadmap

Here is a list of items that may be useful to tackle:

## Auto-configure GeoServer using its REST API, instead of editing XML files

Editing files in-place is not a good idea for Chef, as it leaves only part of the file's state controlled by Chef. Here we see GeoServer editing its configuration files, even adding keys not present in the base install XML configuration files.

A more reliable way to automate configuration of GeoServer may be through its REST API. The [http_request resource](https://docs.chef.io/resources/http_request/) might be used here, as it already has Chef's error handling and logging.

## Find a way to install SQLite/PROJ/GDAL/tomcat-native without needing to compile locally

Compiling these packages is slow, taking minutes to finish even on a moderately powerful desktop PC. This typically takes longer when deployed to a cloud instance, and the additional CPU usage may be incurring additional burst costs (depending on your cloud provider plan or configuration). These packages are compiled to ensure that the correct options and features are enabled for usage with GeoServer.

It would be better to install these packages from binary versions if possible. Is there a better source?

## Plan and test deployment onto CentOS 8 and/or Debian

Currently the cookbook is targeting CentOS 7 as that is the production environment. This however will eventually change and be replaced with a newer version of the OS as the previous (7) is deprecated.

Using Test Kitchen it is possible to also start up virtual machines with other base operating systems, and Chef has conditional logic you can use for different platforms.
