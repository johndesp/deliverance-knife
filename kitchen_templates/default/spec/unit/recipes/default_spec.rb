        
## This file is for unit tests based on RSPEC/CHEFSPEC

require 'spec_helper'

describe "<%= @config[:cookbook_name] %>::default" do
  let(:chef_run) do
    runner = ChefSpec::Runner.new(
      log_level: :error,
      cookbook_path: COOKBOOK_PATH
    )
    Chef::Config.force_logger true
    runner.converge('recipe[<%= @config[:cookbook_name] %>::default]')
  end

#  it "installs bacon slicer" do
#    expect(chef_run).to install_package "bacon-slicer"
#  end

#  it "Sets the default sandwich construction" do
#    expect(chef_run.node["sandwich"]["bread"]).to eq "rye sourdough"
#    expect(chef_run.node["sandwich"]["filling"]).to eq [ :bacon, :lettuce, :tomato, :mayo ]
#  end

#  it "Creates a sandwich configuration" do
#    expect(chef_run).to create_file "/etc/sandwich.d/breakfast.conf"
#  end

#  it "It should cut 20 slices of bacon" do
#    chef_run.should execute_command 'slice -n 20 --thickness 2 bacon'
#  end

#  it "Allows access to the secret sandwich sauce for chefs only" do
#    chef_run.directory('/etc/sandwich.d/secret-sauce').should be_owned_by('g_ramsay', 'ivy_chefs')
#  end
end

