# Chef InSpec test for recipe ccadi_geoserver::default

# The Chef InSpec reference, with examples and extensive documentation, can be
# found at https://docs.chef.io/inspec/resources/

describe package('fontconfig') do
  it { should be_installed }
end