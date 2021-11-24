#
# Cookbook:: ccadi_geoserver
# Recipe:: default
#
# Copyright:: 2021, CCADI Project Contributors, All Rights Reserved.
require "uri"

def filename_from_url(url)
  uri = URI.parse(url)
  File.basename(uri.path)
end

# Where source code will be stored for compilation
src_path = node["ccadi_geoserver"]["source_path"]

##################
# Preconfiguration
##################
# Enable EPEL repository
yum_package "epel-release"

# Install vim for debugging
yum_package "vim"

# Update packages
execute "yum update" do
  command "yum update --assumeyes"
end

# Fix certificate bug in RHEL/CentOS
# https://blog.devgenius.io/rhel-centos-7-fix-for-lets-encrypt-change-8af2de587fe4
execute "fix certificates" do
  command 'trust dump --filter "pkcs11:id=%c4%a7%b1%a4%7b%2c%71%fa%db%e1%4b%90%75%ff%c4%15%60%85%89%10" | openssl x509 | sudo tee /etc/pki/ca-trust/source/blacklist/DST-Root-CA-X3.pem'
  not_if { ::File.exists?("/etc/pki/ca-trust/source/blacklist/DST-Root-CA-X3.pem") }
end

execute "update root store" do
  command "update-ca-trust extract"
end

# Install fontconfig for OpenJDK to have access to system fonts
# See: https://blog.adoptopenjdk.net/2021/01/prerequisites-for-font-support-in-adoptopenjdk/
yum_package %w[freetype fontconfig dejavu-sans-fonts]

# RHEL/CentOS development tools for compiling source
bash "install development tools" do
  code <<-EOF
    yum --assumeyes groups mark install "Development Tools"
    yum --assumeyes groups mark convert "Development Tools"
    yum --assumeyes groupinstall "Development Tools"
  EOF
end

#################
# Install OpenJDK
#################
java_home = "#{node["openjdk"]["prefix"]}/jdk-#{node["openjdk"]["version"]}"

directory node["openjdk"]["prefix"] do
  recursive true
  action :create
end

jdk_filename = filename_from_url(node["openjdk"]["download_url"])

remote_file "#{Chef::Config["file_cache_path"]}/#{jdk_filename}" do
  source   node["openjdk"]["download_url"]
  checksum node["openjdk"]["checksum"]
end

bash "extract JDK" do
  cwd node["openjdk"]["prefix"]
  code <<-EOH
    tar xzf "#{Chef::Config["file_cache_path"]}/#{jdk_filename}" -C .
    EOH
  not_if { ::File.exists?(java_home) }
end

################
# Install Tomcat
################
tomcat_home = "#{node["tomcat"]["prefix"]}/apache-tomcat-#{node["tomcat"]["version"]}"

user node["tomcat"]["user"] do
  home node["tomcat"]["prefix"]
  manage_home false
end

group node["tomcat"]["user"] do
  members node["tomcat"]["user"]
end

directory node["tomcat"]["prefix"] do
  owner node["tomcat"]["user"]
  group node["tomcat"]["user"]
  recursive true
  action :create
end

tomcat_filename = filename_from_url(node["tomcat"]["download_url"])

remote_file "#{Chef::Config["file_cache_path"]}/#{tomcat_filename}" do
  source   node["tomcat"]["download_url"]
  checksum node["tomcat"]["checksum"]
end

bash "extract Tomcat" do
  cwd node["tomcat"]["prefix"]
  user node["tomcat"]["user"]
  code <<-EOH
    tar xzf "#{Chef::Config["file_cache_path"]}/#{tomcat_filename}" -C .
    EOH
  not_if { ::File.exists?(tomcat_home) }
end

geoserver_data = node["geoserver"]["data_dir"]
domains        = node["ccadi_geoserver"]["domains"].join(",")

systemd_unit "tomcat.service" do
  content <<-EOU.gsub(/^\s+/, '')
  [Unit]
  Description=Apache Tomcat Web Application Container
  After=syslog.target network.target
  [Service]
  Type=forking
  User=#{node["tomcat"]["user"]}
  Group=#{node["tomcat"]["user"]}
  Environment="JAVA_HOME=#{java_home}"
  Environment="CATALINA_PID=#{tomcat_home}/temp/tomcat.pid"
  Environment="CATALINA_HOME=#{tomcat_home}"
  Environment="CATALINA_BASE=#{tomcat_home}"
  Environment="CATALINA_OPTS="
  Environment="GEOSERVER_CSRF_WHITELIST=#{domains}"
  Environment="GEOSERVER_DATA_DIR=#{geoserver_data}"
  Environment="GDAL_DATA=#{node["gdal"]["prefix"]}/share/gdal"
  Environment="LD_LIBRARY_PATH=$LD_LIBRARY_PATH:#{tomcat_home}/lib"
  Environment="JAVA_OPTS=-Dfile.encoding=UTF-8 -Djava.library.path=/usr/local/lib:/opt/local/lib:#{tomcat_home}/lib -Xms#{node["tomcat"]["Xms"]} -Xmx#{node["tomcat"]["Xmx"]}"
  ExecStart=#{tomcat_home}/bin/startup.sh
  ExecStop=/bin/kill -15 $MAINPID
  [Install]
  WantedBy=multi-user.target
  EOU

  action [:create, :enable, :start]
end

# Create resource to refer to in other resource notifications
service "tomcat" do
  supports [:start, :stop, :restart]
  action :nothing
end

# Remove default Tomcat applications
# Note: this will delete any future webapp that has one of
#       these names.
%w(ROOT docs examples host-manager manager).each do |app|
  directory "#{tomcat_home}/webapps/#{app}" do
    recursive true
    action :delete
  end
end

###############
# Install nginx
###############
yum_package "nginx"

# Create resource to refer to in other resource notifications
service "nginx" do
  supports [:start, :stop, :restart, :reload]
  action [:enable, :start]
end

# Override default nginx configuration to disable the default site
template "/etc/nginx/nginx.conf" do
  source "default/nginx.conf"
  notifies :restart, "service[nginx]"
end

# Set up HTTPS certificates and virtual hosts for nginx
yum_package %w[certbot python-certbot-nginx]

# Install self-signed certificates so nginx can start the HTTPS virtual host
selfsigned_certificate_path = "/etc/ssl/certs/fake-geoserver.ccadi.gswlab.ca.crt"

bash "create self-signed certificate" do
  code "/etc/ssl/certs/make-dummy-cert #{selfsigned_certificate_path}"
  not_if { ::File.exist?(selfsigned_certificate_path) }
end

# Create directory for holding ACME challenge files
directory node["certbot"]["challenge_path"] do
  recursive true
  action :create
end

# Use an attribute flag to only enable fetching HTTPS certificates in production.
# In testing, getting certificates from Let's Encrypt doesn't work as the test
# VM isn't internet-facing.
if node["certbot"]["enabled"]
  domains = node["ccadi_geoserver"]["domains"]

  domains.each do |domain|
    bash "get certificate using certbot" do
      code "certbot certonly \
      --nginx                \
      --non-interactive      \
      --domains #{domain}   \
      --agree-tos            \
      -m #{node["certbot"]["email"]}"
    end
  end
end

# Install HTTP-only virtual host
template "/etc/nginx/conf.d/geoserver-http.conf" do
  source "default/geoserver-http-vhost.conf"
  variables({
    domains: domains
  })
  notifies :reload, "service[nginx]"
end

# Install HTTPS-only virtual host
template "/etc/nginx/conf.d/geoserver-https.conf" do
  source "default/geoserver-https-vhost.conf"
  variables({
    domains:    domains,
    selfsigned: !node["certbot"]["enabled"]
  })
  notifies :reload, "service[nginx]"
end

# Enable SELinux access from nginx to Tomcat
execute "Allow httpd network connections" do
  command "setsebool -P httpd_can_network_connect 1"
end

##########################
# Install GDAL and support
##########################

# Set up install directory
directory "/opt/local" do
  action :create
end

# Set up source directory
directory src_path do
  action :create
end

# Install SQLite for Proj4
sqlite_prefix = node["sqlite"]["prefix"]

directory sqlite_prefix do
  recursive true
  action :create
end

sqlite_filename = filename_from_url(node["sqlite"]["download_url"])

remote_file "#{Chef::Config["file_cache_path"]}/#{sqlite_filename}" do
  source   node["sqlite"]["download_url"]
  checksum node["sqlite"]["checksum"]
end

sqlite_src_dir = "#{src_path}/sqlite-autoconf-3360000"

bash "extract sqlite" do
  cwd src_path
  code <<-EOH
    tar xzf "#{Chef::Config["file_cache_path"]}/#{sqlite_filename}" -C .
  EOH
  not_if { ::File.exists?(sqlite_src_dir) }
end

log "Compiling SQLite, this may take a minute"

# Compile the source code for SQLite. For explanation of flags used, see:
# https://sqlite.org/compile.html
bash "compile sqlite" do
  cwd sqlite_src_dir
  code <<-EOH
    ./configure --prefix="#{sqlite_prefix}" \
      CFLAGS="-g -O2                   \
      -DSQLITE_ENABLE_FTS5=1           \
      -DSQLITE_ENABLE_GEOPOLY=1        \
      -DSQLITE_ENABLE_JSON1=1          \
      -DSQLITE_ENABLE_MATH_FUNCTIONS=1 \
      -DSQLITE_ENABLE_RTREE=1          \
      -DSQLITE_SQS=0                   \
      -DSQLITE_OMIT_DEPRECATED=1       \
      -DSQLITE_ENABLE_UNLOCK_NOTIFY=1"
    make
    make install
  EOH

  not_if { ::File.exist?("#{sqlite_prefix}/bin/sqlite3") }
end

# Install PROJ from source
yum_package %w[libtiff libtiff-devel curl libcurl libcurl-devel]

proj_prefix = node["proj"]["prefix"]

directory proj_prefix do
  recursive true
  action :create
end

proj_filename = filename_from_url(node["proj"]["download_url"])

remote_file "#{Chef::Config["file_cache_path"]}/#{proj_filename}" do
  source   node["proj"]["download_url"]
  checksum node["proj"]["checksum"]
end

proj_src_dir = "#{src_path}/proj-8.1.1"

bash "extract PROJ" do
  cwd src_path
  code <<-EOH
    tar xzf "#{Chef::Config["file_cache_path"]}/#{proj_filename}" -C .
  EOH
  not_if { ::File.exists?(proj_src_dir) }
end

log "Compiling PROJ, this may take a few minutes"

# Note that PATH must be set for proj.db to compile properly.
# See: https://github.com/OSGeo/PROJ/issues/2071
bash "compile PROJ" do
  cwd proj_src_dir
  environment({
    "MAKEFLAGS"      => "-j #{node["jobs"]}",
    "PATH"           => "/opt/local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin",
    "SQLITE3_CFLAGS" => "-I/opt/local/include",
    "SQLITE3_LIBS"   => "-L/opt/local/lib -lsqlite3"
  })
  code <<-EOH
    ./configure --prefix="#{proj_prefix}"
    make
    make install
  EOH

  not_if { ::File.exist?("#{proj_prefix}/bin/proj") }
end

log "Downloading PROJ data files, this may take a few minutes"

# These are helper files for datum and transformations, and we download them now rather than
# on-the-fly. They are stored in "$proj_prefix/share/proj".
execute "download PROJ data files" do
  command "/opt/local/bin/projsync --system-directory --all"
end

# Install Apache Ant for Java GDAL bindings
ant_home = "#{node["ant"]["prefix"]}/apache-ant-#{node["ant"]["version"]}"
ant_filename = filename_from_url(node["ant"]["download_url"])

directory node["ant"]["prefix"] do
  recursive true
  action :create
end

remote_file "#{Chef::Config["file_cache_path"]}/#{ant_filename}" do
  source   node["ant"]["download_url"]
  checksum node["ant"]["checksum"]
end

# This is a binary, so we can extract directly to the prefix
bash "extract ant archive" do
  cwd node["ant"]["prefix"]
  code <<-EOH
    tar xzf "#{Chef::Config["file_cache_path"]}/#{ant_filename}" -C .
  EOH
  not_if { ::File.exists?(ant_home) }
end

execute "Install Apache Ant library dependencies" do
  command "#{ant_home}/bin/ant -f fetch.xml -Ddest=system"
  cwd ant_home
  environment({
    "ANT_HOME"  => ant_home,
    "JAVA_HOME" => java_home
  })
end

# Install GDAL from source
gdal_prefix = node["gdal"]["prefix"]

directory gdal_prefix do
  recursive true
  action :create
end

gdal_filename = filename_from_url(node["gdal"]["download_url"])

remote_file "#{Chef::Config["file_cache_path"]}/#{gdal_filename}" do
  source   node["gdal"]["download_url"]
  checksum node["gdal"]["checksum"]
end

gdal_src_dir = "#{src_path}/gdal-#{node["gdal"]["version"]}"

bash "extract GDAL" do
  cwd src_path
  code <<-EOH
    tar xzf "#{Chef::Config["file_cache_path"]}/#{gdal_filename}" -C .
  EOH
  not_if { ::File.exists?(gdal_src_dir) }
end

log "Compiling GDAL, this may take a few minutes"

bash "compile GDAL" do
  cwd gdal_src_dir
  environment({
    "MAKEFLAGS" => "-j #{node["jobs"]}",
    "PATH"      => "#{ant_home}/bin:/opt/local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin",
    "ANT_HOME"  => ant_home,
    "JAVA_HOME" => java_home
  })
  code <<-EOH
    ./configure --prefix="#{gdal_prefix}" \
      --with-proj="#{proj_prefix}"        \
      --with-sqlite3="#{sqlite_prefix}"   \
      --with-java="#{java_home}"
    make
    make install

    cd swig/java
    make
    make install
  EOH

  not_if "#{gdal_prefix}/bin/gdal-config --version | grep -q '#{node["gdal"]["version"]}'"
end

###################
# Install GeoServer
###################
directory node["geoserver"]["prefix"] do
  recursive true
  action :create
end

geoserver_filename = filename_from_url(node["geoserver"]["download_url"])

remote_file "#{Chef::Config["file_cache_path"]}/#{geoserver_filename}" do
  source   node["geoserver"]["download_url"]
  checksum node["geoserver"]["checksum"]
end

yum_package "unzip"

bash "extract GeoServer" do
  cwd "#{tomcat_home}/webapps"
  user node["tomcat"]["user"]
  code <<-EOH
    unzip -o "#{Chef::Config["file_cache_path"]}/#{geoserver_filename}" -d .
  EOH
  not_if { ::File.exists?("#{tomcat_home}/webapps/geoserver.war") }
  notifies :restart, "service[tomcat]"
end

###############################
# Install GeoServer GDAL Plugin
###############################

geoserver_gdal_filename = filename_from_url(node["geoserver"]["gdal_plugin"]["download_url"])

remote_file "#{Chef::Config["file_cache_path"]}/#{geoserver_gdal_filename}" do
  source   node["geoserver"]["gdal_plugin"]["download_url"]
  checksum node["geoserver"]["gdal_plugin"]["checksum"]
end

# Extract GDAL plugin to GeoServer, waiting for Tomcat to start GeoServer
# and create the plugins directory first. If it doesn't exist within 120
# seconds, then there is probably a problem and the chef client should
# stop.
bash "extract GeoServer GDAL plugin" do
  cwd node["geoserver"]["prefix"]
  code <<-EOH
    while ! test -d "#{tomcat_home}/webapps/geoserver/WEB-INF/lib"; do
      sleep 10
      echo "Waiting for GeoServer lib directory to be created"
    done
    rm -rf geoserver-gdal-plugin
    unzip -o "#{Chef::Config["file_cache_path"]}/#{geoserver_gdal_filename}" -d geoserver-gdal-plugin
    cp geoserver-gdal-plugin/*.jar "#{tomcat_home}/webapps/geoserver/WEB-INF/lib/."
    cp "#{gdal_src_dir}/swig/java/gdal.jar" "#{tomcat_home}/webapps/geoserver/WEB-INF/lib/."
    chown -R #{node["tomcat"]["user"]} #{tomcat_home}/webapps/geoserver/WEB-INF/lib
  EOH
  timeout 120
  notifies :restart, "service[tomcat]"
  not_if { ::File.exists?("#{tomcat_home}/webapps/geoserver/WEB-INF/lib/gs-gdal-#{node["geoserver"]["version"]}.jar") }
end

#####################################
# Install GeoServer Monitoring Plugin
#####################################

geoserver_monitoring_filename = filename_from_url(node["geoserver"]["monitoring_plugin"]["download_url"])

remote_file "#{Chef::Config["file_cache_path"]}/#{geoserver_monitoring_filename}" do
  source   node["geoserver"]["monitoring_plugin"]["download_url"]
  checksum node["geoserver"]["monitoring_plugin"]["checksum"]
end

# Extract Monitoring plugin to GeoServer, waiting for Tomcat to start GeoServer
# and create the plugins directory first. If it doesn't exist within 120
# seconds, then there is probably a problem and the chef client should
# stop.
bash "extract GeoServer Monitoring plugin" do
  cwd node["geoserver"]["prefix"]
  code <<-EOH
    while ! test -d "#{tomcat_home}/webapps/geoserver/WEB-INF/lib"; do
      sleep 10
      echo "Waiting for GeoServer lib directory to be created"
    done
    rm -rf geoserver-gdal-plugin
    unzip -o "#{Chef::Config["file_cache_path"]}/#{geoserver_monitoring_filename}" -d geoserver-monitor-plugin
    cp geoserver-monitor-plugin/*.jar "#{tomcat_home}/webapps/geoserver/WEB-INF/lib/."
    chown -R #{node["tomcat"]["user"]} "#{tomcat_home}/webapps/geoserver/WEB-INF/lib"
  EOH
  timeout 120
  notifies :restart, "service[tomcat]"
  not_if { ::File.exists?("#{tomcat_home}/webapps/geoserver/WEB-INF/lib/gs-monitor-core-#{node["geoserver"]["version"]}.jar") }
end

#################################
# Install GeoServer NetCDF Plugin
#################################
yum_package %w[netcdf netcdf-devel netcdf-cxx netcdf-cxx-devel]

geoserver_netcdf_filename = filename_from_url(node["geoserver"]["netcdf_plugin"]["download_url"])

remote_file "#{Chef::Config["file_cache_path"]}/#{geoserver_netcdf_filename}" do
  source   node["geoserver"]["netcdf_plugin"]["download_url"]
  checksum node["geoserver"]["netcdf_plugin"]["checksum"]
end

# Extract NetCDF plugin to GeoServer, waiting for Tomcat to start GeoServer
# and create the plugins directory first. If it doesn't exist within 120
# seconds, then there is probably a problem and the chef client should
# stop.
bash "extract GeoServer NetCDF plugin" do
  cwd node["geoserver"]["prefix"]
  code <<-EOH
    while ! test -d "#{tomcat_home}/webapps/geoserver/WEB-INF/lib"; do
      sleep 10
      echo "Waiting for GeoServer lib directory to be created"
    done
    rm -rf geoserver-netcdf-plugin
    unzip -o "#{Chef::Config["file_cache_path"]}/#{geoserver_netcdf_filename}" -d geoserver-netcdf-plugin
    cp geoserver-netcdf-plugin/*.jar "#{tomcat_home}/webapps/geoserver/WEB-INF/lib/."
    chown -R #{node["tomcat"]["user"]} "#{tomcat_home}/webapps/geoserver/WEB-INF/lib"
  EOH
  timeout 120
  notifies :restart, "service[tomcat]"
  not_if { ::File.exists?("#{tomcat_home}/webapps/geoserver/WEB-INF/lib/gs-netcdf-#{node["geoserver"]["version"]}.jar") }
end

##############################
# Install GeoServer WPS Plugin
##############################
geoserver_wps_filename = filename_from_url(node["geoserver"]["wps_plugin"]["download_url"])

remote_file "#{Chef::Config["file_cache_path"]}/#{geoserver_wps_filename}" do
  source   node["geoserver"]["wps_plugin"]["download_url"]
  checksum node["geoserver"]["wps_plugin"]["checksum"]
end

# Extract WPS plugin to GeoServer, waiting for Tomcat to start GeoServer
# and create the plugins directory first. If it doesn't exist within 120
# seconds, then there is probably a problem and the chef client should
# stop.
bash "extract GeoServer WPS plugin" do
  cwd node["geoserver"]["prefix"]
  code <<-EOH
    while ! test -d "#{tomcat_home}/webapps/geoserver/WEB-INF/lib"; do
      sleep 10
      echo "Waiting for GeoServer lib directory to be created"
    done
    rm -rf geoserver-wps-plugin
    unzip -o "#{Chef::Config["file_cache_path"]}/#{geoserver_wps_filename}" -d geoserver-wps-plugin
    cp geoserver-wps-plugin/*.jar "#{tomcat_home}/webapps/geoserver/WEB-INF/lib/."
    chown -R #{node["tomcat"]["user"]} "#{tomcat_home}/webapps/geoserver/WEB-INF/lib"
  EOH
  timeout 120
  notifies :restart, "service[tomcat]"
  not_if { ::File.exists?("#{tomcat_home}/webapps/geoserver/WEB-INF/lib/gs-wps-#{node["geoserver"]["version"]}.jar") }
end

##############################
# Install GeoServer CSW Plugin
##############################
geoserver_csw_filename = filename_from_url(node["geoserver"]["csw_plugin"]["download_url"])

remote_file "#{Chef::Config["file_cache_path"]}/#{geoserver_csw_filename}" do
  source   node["geoserver"]["csw_plugin"]["download_url"]
  checksum node["geoserver"]["csw_plugin"]["checksum"]
end

# Extract CSW plugin to GeoServer, waiting for Tomcat to start GeoServer
# and create the plugins directory first. If it doesn't exist within 120
# seconds, then there is probably a problem and the chef client should
# stop.
bash "extract GeoServer CSW plugin" do
  cwd node["geoserver"]["prefix"]
  code <<-EOH
    while ! test -d "#{tomcat_home}/webapps/geoserver/WEB-INF/lib"; do
      sleep 10
      echo "Waiting for GeoServer lib directory to be created"
    done
    rm -rf geoserver-csw-plugin
    unzip -o "#{Chef::Config["file_cache_path"]}/#{geoserver_csw_filename}" -d geoserver-csw-plugin
    cp geoserver-csw-plugin/*.jar "#{tomcat_home}/webapps/geoserver/WEB-INF/lib/."
    chown -R #{node["tomcat"]["user"]} "#{tomcat_home}/webapps/geoserver/WEB-INF/lib"
  EOH
  timeout 120
  notifies :restart, "service[tomcat]"
  not_if { ::File.exists?("#{tomcat_home}/webapps/geoserver/WEB-INF/lib/gs-csw-#{node["geoserver"]["version"]}.jar") }
end

######################
# Set up tomcat-native
######################

tomcat_native_home = "#{node["tomcat"]["prefix"]}/tomcat-native-#{node["tomcat-native"]["version"]}-src"
tomcat_native_filename = filename_from_url(node["tomcat-native"]["download_url"])

remote_file "#{Chef::Config["file_cache_path"]}/#{tomcat_native_filename}" do
  source   node["tomcat-native"]["download_url"]
  checksum node["tomcat-native"]["checksum"]
end

bash "extract tomcat-native" do
  cwd node["tomcat"]["prefix"]
  user node["tomcat"]["user"]
  code <<-EOH
    tar xzf "#{Chef::Config["file_cache_path"]}/#{tomcat_native_filename}" -C .
  EOH
  not_if { ::File.exists?(tomcat_native_home) }
end

yum_package %w[apr-devel openssl-devel]

# Compile tomcat-native
log "Compiling tomcat-native, which may take a few minutes"
bash "compile tomcat-native" do
  cwd "#{tomcat_native_home}/native"
  environment({
    "MAKEFLAGS" => "-j #{node["jobs"]}",
    "JAVA_HOME" => java_home
  })
  code <<-EOH
    ./configure --prefix=#{tomcat_home}
    make
    make install
  EOH
  not_if { ::File.exists?("#{tomcat_home}/lib/libtcnative-1.so") }
  notifies :restart, "service[tomcat]"
end

#####################
# Customize GeoServer
#####################
# Install new global configuration.
# The action is set to "nothing" as this should *only* be triggered after
# a fresh installation, otherwise changes made using the GeoServer web UI
# will be overwritten.
template "install geoserver global configuration" do
  path "#{geoserver_data}/global.xml"
  source "global.xml.erb"
  variables({
    address:            node["geoserver"]["address"],
    contact:            node["geoserver"]["contact"],
    num_decimals:       node["geoserver"]["num_decimals"],
    proxy_base_url:     node["geoserver"]["proxy_base_url"],
    verbose:            node["geoserver"]["verbose"],
    verbose_exceptions: node["geoserver"]["verbose_exceptions"],
    jai:                node["geoserver"]["jai"]

  })
  notifies :restart, "service[tomcat]"
  action :nothing
end

# Install default CSW configuration, only on first run.
cookbook_file "install default CSW configuration" do
  path "#{geoserver_data}/csw.xml"
  source "csw.xml"
  notifies :restart, "service[tomcat]"
  action :nothing
end

# Install default WCS configuration, only on first run.
cookbook_file "install default WCS configuration" do
  path "#{geoserver_data}/wcs.xml"
  source "wcs.xml"
  notifies :restart, "service[tomcat]"
  action :nothing
end

# Install default WFS configuration, only on first run.
cookbook_file "install default WFS configuration" do
  path "#{geoserver_data}/wfs.xml"
  source "wfs.xml"
  notifies :restart, "service[tomcat]"
  action :nothing
end

# Install default WMS configuration, only on first run.
cookbook_file "install default WMS configuration" do
  path "#{geoserver_data}/wms.xml"
  source "wms.xml"
  notifies :restart, "service[tomcat]"
  action :nothing
end

# Install default WPS configuration, only on first run.
cookbook_file "install default WPS configuration" do
  path "#{geoserver_data}/wps.xml"
  source "wps.xml"
  notifies :restart, "service[tomcat]"
  action :nothing
end

# Install new masterpw file
file "install new masterpw file" do
  path "#{geoserver_data}/security/masterpw.digest"
  content node["geoserver"]["masterpw"]
  notifies :restart, "service[tomcat]"
  action :nothing
end

# Move the default GeoServer data directory out of the Tomcat webapps
# directory. This allows it to be on another volume and persist between
# Tomcat upgrades.

# If the "new" data directory is still empty, then move over the original
# data directory. Using Chef resource notifications to stop Tomcat before
# this runs does not seem to work, and will leave a partial data directory
# behind. Instead Tomcat is stopped by systemd in the resource.
bash "copy base geoserver data directory" do
  code <<-EOH
    systemctl stop tomcat
    sleep 5
    rsync -a "#{tomcat_home}/webapps/geoserver/data" "#{node["geoserver"]["prefix"]}"
  EOH
  not_if { ::File.exist?("#{geoserver_data}/global.xml") }
  notifies :restart, "service[tomcat]"
  notifies :create, "template[install geoserver global configuration]"
  notifies :create, "cookbook_file[install default CSW configuration]"
  notifies :create, "cookbook_file[install default WCS configuration]"
  notifies :create, "cookbook_file[install default WFS configuration]"
  notifies :create, "cookbook_file[install default WMS configuration]"
  notifies :create, "cookbook_file[install default WPS configuration]"
  notifies :create, "file[install new masterpw file]"
end

# Install extra CRS definitions
cookbook_file "#{geoserver_data}/user_projections/epsg.properties" do
  source "epsg.properties"
  owner node["tomcat"]["user"]
  group node["tomcat"]["user"]
  notifies :restart, "service[tomcat]"
end

# Create directory for GeoWebCache blob store
gwc_cache_dir = node["geoserver"]["data_dir"] + "/cache"

directory gwc_cache_dir do
  recursive true
  owner node["tomcat"]["user"]
  group node["tomcat"]["user"]
  action :create
end
