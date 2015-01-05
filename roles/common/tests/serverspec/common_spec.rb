require_relative '../../../../test/serverspec/spec_helper'

describe file('/etc/lsb-release') do
  it { should be_file }
end