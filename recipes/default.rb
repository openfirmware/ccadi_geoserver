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

# Update packages
execute "yum update" do
  command "yum update --assumeyes"
end

# Fix certificate bug in RHEL/CentOS
# https://blog.devgenius.io/rhel-centos-7-fix-for-lets-encrypt-change-8af2de587fe4
execute "fix certificates" do
  command 'trust dump --filter "pkcs11:id=%c4%a7%b1%a4%7b%2c%71%fa%db%e1%4b%90%75%ff%c4%15%60%85%89%10" | openssl x509 | sudo tee /etc/pki/ca-trust/source/blacklist/DST-Root-CA-X3.pem'
  ignore_failure true
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
  source node["openjdk"]["download_url"]
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
  source node["tomcat"]["download_url"]
end

bash "extract Tomcat" do
  cwd node["tomcat"]["prefix"]
  user node["tomcat"]["user"]
  code <<-EOH
    tar xzf "#{Chef::Config["file_cache_path"]}/#{tomcat_filename}" -C .
    EOH
  not_if { ::File.exists?(tomcat_home) }
end

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
  Environment="GDAL_DATA=/usr/local/share/gdal"
  Environment="LD_LIBRARY_PATH=$LD_LIBRARY_PATH:#{tomcat_home}/lib"
  Environment="JAVA_OPTS=-Dfile.encoding=UTF-8 -Djava.library.path=/usr/local/lib:#{tomcat_home}/lib -Xms#{node["tomcat"]["Xms"]} -Xmx#{node["tomcat"]["Xmx"]}"
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
  domains = node["ccadi_geoserver"]["domains"].join(",")

  bash "get certificate using certbot" do
    code "certbot certonly --nginx -n \
    --domains #{domains} \
    --agree-tos \
    -m #{node["certbot"]["email"]}"
  end
end

# Install HTTP-only virtual host
template "/etc/nginx/conf.d/geoserver-http.conf" do
  source "default/geoserver-http-vhost.conf"
  variables({
    domains: node["ccadi_geoserver"]["domains"]
  })
  notifies :reload, "service[nginx]"
end

# Install HTTPS-only virtual host
template "/etc/nginx/conf.d/geoserver-https.conf" do
  source "default/geoserver-https-vhost.conf"
  variables({
    domains:    node["ccadi_geoserver"]["domains"],
    selfsigned: !node["certbot"]["enabled"]
  })
  notifies :reload, "service[nginx]"
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
  source node["sqlite"]["download_url"]
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
  source node["proj"]["download_url"]
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
  source node["ant"]["download_url"]
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
  source node["gdal"]["download_url"]
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
    "MAKEFLAGS"      => "-j #{node["jobs"]}",
    "PATH"           => "/opt/local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"
  })
  code <<-EOH
    ./configure --prefix="#{gdal_prefix}" \
      --with-proj="#{proj_prefix}"        \
      --with-sqlite3="#{sqlite_prefix}"
    make
    make install
  EOH

  not_if { ::File.exist?("#{gdal_prefix}/bin/gdalinfo") }
end

# Install GeoServer

# Install GeoServer Plugins

# Auto-configure GeoServer

