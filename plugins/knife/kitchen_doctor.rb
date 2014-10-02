# encoding: UTF-8
# Author:: Richard Nixon
# Copyright:: Copyright (c) 2013 General Electric
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/knife'
require 'fileutils'
require 'json'

class Chef
  class Knife
  
    # KitchenDoctor checks for general issues with your chef, git and cookbook
    # It should be installed under ~/.chef/plugins/knife
    class KitchenDoctor < Chef::Knife

      # Display usage options
      banner "knife kitchen doctor"

      # This methos is executed by knife in response to a "knife kitchen doctor" command
      def run

        # Grab all the config params from command line, knife.rb etc
        self.config = Chef::Config.merge!(config)

        # Check if we have a knife.rb
        puts "Check location of knife.rb"
          checkfiles(:config_file,"The config file (knife.rb) should be stored in a .chef folder here or higher (towards root)")
          if config[:config_file].nil?
            exit 1
          else
            # We shouldn't reach this point but lets make sure we die if we somehow do.
            unless ::File.exists?(File.expand_path(config[:config_file]))
              exit 1
            end
          end
          
        puts "Check chef basics"
          checkparm(:chef_server_url,'chef_server_url should be set to point to your chef server (https://<server.name>/organizations/<orgname>)')
          checkfiles(:cookbook_path,"cookbook_path should point to a valid directory")

        puts "Check author and copyright info"
          checkparm(:cookbook_copyright,"cookbook_copyright should be set to your company name")
          checkparm(:cookbook_email,"cookbook_email should be set to your eMail address")


        puts "Check keys exist"
          checkfiles(:client_key,"This file is used for authenticating to Chef server and is normally saved in .chef as client.pem")
          checkfiles(:validation_key,"This file is used for bootstraping new nodes and is stored in .chef as validator.pem")
          checkparm(:validation_client_name,"validation_client_name is normally set to <orgname>-validator")

        puts "Check proxy configuration"
          checkparm(:http_proxy,"http_proxy should be set to a valid proxy like http://myproxy.ge.com:3128")
          checkparm(:https_proxy,"https_proxy should be set to a valid proxy like http://myproxy.ge.com:3128")
          checkparm(:bootstrap_proxy,"bootstrap_proxy should be set to a valid proxy like http://myproxy.ge.com:3128")
          checkparm(:no_proxy,"no_proxy should be set to exclude certain domains like *.ge.com from being proxied. Dont add wildcard subnets like 3.*")

        puts "Check GIT/Gerrit"
          checkparm(:reviewhost,"reviewhost should be set to the FQDN of your Gerrit server (leave out the http:// and the port number)")

          # Check if GIT has a default username configured
          result=`git config --get user.name`.chomp
          if result.length < 1
            puts ui.color("  the git user.name is not set. Add it using:-", :red)
            puts ui.color("      git config --global user.name <username>", :magenta)
          else
            puts ui.color("  the git user.name is set to #{result}", :green)
          end

          # Check if GIT has a default email address configured
          result=`git config --get user.email`.chomp
          if result.length < 1
            puts ui.color("  the git user.email is not set. Add it using:-", :red)
            puts ui.color("      git config --global user.email <email address>", :magenta)
          else
            puts ui.color("  the git user.email is set to #{result}", :green)
          end

          # Check if the git core.autocrlf is set correctly (different on Windows and OSX... TODO: Check on Linux)
          result=`git config --get core.autocrlf`.chomp
          case result
          when 'input'
            if (RUBY_PLATFORM =~ /.*darwin.*/) or (RUBY_PLATFORM =~ /.*linux.*/)
              puts ui.color("  the git core.autocrlf is set to 'input' which is correct for OSX or Linux systems", :green)
            end
            if (RUBY_PLATFORM =~ /.*mingw.*/) or (RUBY_PLATFORM =~ /.*cygwin.*/)
              puts ui.color("  the git core.autocrlf is set to 'input' but Windows/Linux should use 'true' to prevent line ending problems", :red)
            end

          when 'true'
            if (RUBY_PLATFORM =~ /.*mingw.*/) or (RUBY_PLATFORM =~ /.*cygwin.*/)
              puts ui.color("  the git core.autocrlf is set to 'true' which is correct for Windows/Cygwin", :green)
            end
            if (RUBY_PLATFORM =~ /.*darwin.*/) or (RUBY_PLATFORM =~ /.*linux.*/)
              puts ui.color("  the git core.autocrlf is set to 'true' but OSX/Linux should use 'input' to prevent line ending problems", :red)
            end

          else
            puts ui.color("  the git core.autocrlf is set to '#{result}'", :red)
            puts ui.color("    the git core.autocrlf should be set to 'input' (on OSX or Linux) or 'true' (on Windows) to prevent line ending problems", :magenta)
          end

        # Check if we have a git remote called Gerrit.
        result=`git config --get remote.gerrit.url`.chomp
        if result.length < 1
          puts ui.color("  we don't seem to have a git remote called gerrit.", :red)
          puts ui.color("      If we are in a project folder, check you have a valid .gitreview file and try running:-", :red)
          puts ui.color("      git review -s", :magenta)
        else
          puts ui.color("  the git remote for gerrit is set to #{result}", :green)
        end

        # Check we have the settings to install Vagrant box templates and create Vagrant boxes
        # TODO: Add a check to make sure the box is installed and the URL is valid
        puts "Check Vagrant"
          checkparm(:vagrant_box,"vagrant_box should be set to the name of your vagrant box")
          checkparm(:vagrant_box_url,"vagrant_box_url should point to a downloadable vagrant box")

        puts "Check berkshelf"
          # Do we actually have a berks config
          berksConfigFile=File.expand_path(File.join('~','.berkshelf','config.json'))
          checkfile('Berkshelf Config',berksConfigFile,"You dont have a Berkshelf config. Try running 'berks config'")

          if ::File.exists?(berksConfigFile)
            berksConfigRaw=File.read(berksConfigFile)
            berksConfig=JSON.parse(berksConfigRaw)

            # Make sure that SSL verify is off
            if berksConfig['ssl']['verify'].to_s == 'false'
              puts ui.color("  SSL verify is turned off", :green)
            else
              puts ui.color("  SSL verify is 'true'... you should set it to 'false' to allow connecting to Chef server", :red)
            end
            
            # Check berks is using correct Chef server URL
            if berksConfig['chef']['chef_server_url'].to_s == config[:chef_server_url]
              puts ui.color("  Berkshelf chef_server_url is '#{berksConfig['chef']['chef_server_url']}'", :green)
            else
              puts ui.color("  Berkshelf chef_server_url does not match knife.rb. It's set to '#{berksConfig['chef']['chef_server_url']}'", :red)
            end

            # Check berks is using correct validator.pem
            if berksConfig['chef']['validation_key_path'].to_s == File.expand_path(config[:validation_key])
              puts ui.color("  Berkshelf validation_key_path is '#{berksConfig['chef']['validation_key_path']}'", :green)
            else
              puts ui.color("  Berkshelf validation_key_path does not match knife.rb. It's set to '#{berksConfig['chef']['validation_key_path']}'", :red)
            end

            # Check berks is using correct client.pem
            if berksConfig['chef']['client_key'].to_s == File.expand_path(config[:client_key])
              puts ui.color("  Berkshelf client_key is '#{berksConfig['chef']['client_key']}'", :green)
            else
              puts ui.color("  Berkshelf client_key does not match knife.rb. It's set to '#{berksConfig['chef']['client_key']}'", :red)
            end

            puts "Done !!!"

          end

      end

      # This method checks for presence of one or more files/dirs in a config item.
      # The config may be singular (String) or multiple (Array) so we need to check
      # * [configKey] is a param name from knife.rb, command line or generated by Knife/Chef
      # * [description] is used to pass a helpful message to the user if the param is missing
      
      def checkfiles(configKey, description)
        # Check if the file/dir name is actually set
        if config[configKey].nil?
          puts ui.color("  #{configKey} is not set", :red)
          puts ui.color("      #{description}", :magenta)
        else
          # Check if we have been passed an array of files/dirs
          if config[configKey].is_a? Array
            # Process multiple files
            puts ui.color("  WARNING #{configKey} is an array", :magenta)
            config[configKey].each do |fileName|
              checkfile(configKey, fileName, description)
            end
          else
            # Process a single file
            checkfile(configKey, config[configKey], description)
          end
        end
      end

      # This method is called by checkfiles to verify an individual file
      # * [configKey] is a param name from knife.rb, command line or generated by Knife/Chef
      # * [fileName] is the actual value of the configKey
      # * [description] is used to pass a helpful message to the user if the param is missing

      def checkfile(configKey, fileName, description)
        # Check if the file exists
        if ::File.exists?(File.expand_path(fileName))
          # Yes, so display it
          puts ui.color("  #{configKey} is set to '#{fileName}'",:green)
        else
          # No, so tell the user it's missing
          puts ui.color("  #{configKey} is set to '#{fileName}' which cannot be found", :red)
        end
      end

      # This method checks for the existence of specified parameters
      # * [configKey] is a param name from knife.rb, command line or generated by Knife/Chef
      # * [description] is used to pass a helpful message to the user if the param is missing

      def checkparm(configKey,description)
        # Check if the [configKey] is set
        if config[configKey].nil?
          # No, so tell the user a bit about what it does, why its needed, what to do etc.
          puts ui.color("  #{configKey} is not set", :red)
          puts ui.color("      #{description}", :magenta)
        else
          # Yes, so display it
          puts ui.color("  #{configKey} is set to '#{config[configKey]}'",:green)
        end        
      end
      
    end
  end
end
