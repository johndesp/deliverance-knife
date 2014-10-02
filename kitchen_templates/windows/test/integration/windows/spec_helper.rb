# 
# Integration Tests for Windows 
# Cookbook Name:: <%= @config[:cookbook_name] %>
# File:: spec_helper.rb
#
require 'serverspec'
require 'winrm'

include Serverspec::Helper::WinRM
include Serverspec::Helper::Windows

RSpec.configure do |c|
  user = 'vagrant'
  pass = 'vagrant'
  endpoint = "http://localhost:<%= @winrm_port %>/wsman"

  c.winrm = ::WinRM::WinRMWebService.new(endpoint, :ssl, :user => user, :pass => pass, :basic_auth_only => true)
  c.winrm.set_timeout 300 
end
