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

##################
# Preconfiguration
##################
# Enable EPEL repository
yum_package "epel-release"

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

# Install GDAL

# Install GeoServer

# Install GeoServer Plugins

# Auto-configure GeoServer

