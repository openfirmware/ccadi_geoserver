# Chef InSpec test for recipe ccadi_geoserver::default

# The Chef InSpec reference, with examples and extensive documentation, can be
# found at https://docs.chef.io/inspec/resources/

##################
# Preconfiguration
##################

describe package('epel-release') do
  it { should be_installed }
end

describe package('fontconfig') do
  it { should be_installed }
end

#################
# Install OpenJDK
#################

describe directory('/opt/java/jdk-17') do
  it { should exist }
end

################
# Install Tomcat
################

describe directory('/opt/tomcat/apache-tomcat-9.0.53') do
  it { should exist }
end

describe service('tomcat') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

###############
# Install nginx
###############

describe package('nginx') do
  it { should be_installed }
end

describe service('nginx') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe package('certbot') do
  it { should be_installed }
end

describe package('python2-certbot-nginx') do
  it { should be_installed }
end

describe file('/etc/ssl/certs/fake-geoserver.ccadi.gswlab.ca.crt') do
  it { should exist }
end

describe file('/etc/nginx/conf.d/geoserver-http.conf') do
  it { should exist }
end

describe file('/etc/nginx/conf.d/geoserver-https.conf') do
  it { should exist }
end

##########################
# Install GDAL and friends
##########################

describe directory("/opt/src") do
  it { should exist }
end

describe file("/opt/local/bin/sqlite3") do
  it {should exist }
  it {should be_executable }
end
