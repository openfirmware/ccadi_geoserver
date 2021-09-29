# Primary Attributes

# One or more domains to map as virtual hosts in nginx to point to Tomcat on port 80
# If certbot is enabled, then it will try to retrieve a certificate for each one.
default["ccadi_geoserver"]["domains"] = ["geoserver.ccadi.gswlab.ca"]

# For some tasks that can be parallelized, this many "jobs" should be used.
# This should probably match the number of cores/VCPUs.
default["jobs"] = 2

# OpenJDK
default["openjdk"]["version"] = "17"
default["openjdk"]["prefix"] = "/opt/java"
default["openjdk"]["download_url"] = "https://download.java.net/java/GA/jdk17/0d483333a00540d886896bac774ff48b/35/GPL/openjdk-17_linux-x64_bin.tar.gz"
default["openjdk"]["checksum_url"] = "https://download.java.net/java/GA/jdk17/0d483333a00540d886896bac774ff48b/35/GPL/openjdk-17_linux-x64_bin.tar.gz.sha256"
default["openjdk"]["checksum_type"] = "SHA256"

# Apache Tomcat
default["tomcat"]["version"] = "10.0.11"
default["tomcat"]["user"] = "tomcat"
default["tomcat"]["Xms"] = "256m"
default["tomcat"]["Xmx"] = "4g"
default["tomcat"]["prefix"] = "/opt/tomcat"
default["tomcat"]["download_url"] = "https://dlcdn.apache.org/tomcat/tomcat-10/v10.0.11/bin/apache-tomcat-10.0.11.tar.gz"
default["tomcat"]["checksum_url"] = "https://downloads.apache.org/tomcat/tomcat-10/v10.0.11/bin/apache-tomcat-10.0.11.tar.gz.sha512"
default["tomcat"]["checksum_type"] = "SHA512"


# Certbot
default["certbot"]["enabled"] = true
default["certbot"]["email"] = "jpbadger@ucalgary.ca"
default["certbot"]["challenge_path"] = "/usr/share/nginx/html/.well-known/acme-challenge"
