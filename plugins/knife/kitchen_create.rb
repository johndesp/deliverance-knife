# Author:: Richard Nixon
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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
require 'erb'

class Chef
  class Knife
    
    # KitchenCreate makes test-kitchen boilerplate for cookbooks
    # It should be installed under ~/.chef/plugins/knife
    # It searches for templates under ~/.chef/plugins/knife/kitchen_templates
    class KitchenCreate < Chef::Knife

      # Include the code from Opscode's cookbook_create
      deps do
        require 'chef/knife/cookbook_create'
      end

      # Display usage options
      banner "knife kitchen create COOKBOOK (options)"

      option :vagrant_box,
        :long => "--vagrant_box BOX",
        :description => "The vagrant box to be used for testing"

      option :vagrant_box_url,
        :long => "--vagrant_box_url URL",
        :description => "Where to get the vagrant box from"

      option :reviewhost,
        :long => "--reviewhost HOSTNAME",
        :description => "The IP or DNS name of your Gerrit host"

      option :kitchen_template,
        :long => "--kitchen_template TEMPLATE",
        :description => "The name of a template (Defaults to 'default')"
      
      option :winrm_port,
        :long => "--winrm_port PORT",
        :description => "WinRM forwarded PORT to configure on the host"
      
      option :box_hostname,
        :long => "--box_hostname HOSTNAME",
        :description => "Hostname to configure into the box (Defaults to 'cookbook_name')"
      
      attr_reader :winrm_port, :windows_box, :windows_box_url, :box_hostname

      def run
        self.config = Chef::Config.merge!(config)
        if @name_args.length < 1
          show_usage
          ui.fatal("You must specify a cookbook name")
          exit 1
        end

        # First call Opscode's "knife cookbook create" to generate the normal boilerplate
        cookbook_create = Chef::Knife::CookbookCreate.new
        cookbook_create.name_args = @name_args
        cookbook_create.config=config
        cookbook_create.run 

        # Set up the paths for template rendering

        if self.config[:cookbook_path].is_a? Array      # Developer has multiple cookbook dirs
          cookbookDir=self.config[:cookbook_path][0]    # We will just take the first one
        else
          cookbookDir=self.config[:cookbook_path]
        end

        pluginDir=File.expand_path(File.dirname(__FILE__))
        templateDir=File.join(pluginDir,'kitchen_templates',self.config[:kitchen_template] || "default")
        targetDir=File.join(cookbookDir,@name_args[0])
        self.config[:cookbook_name]=@name_args[0]
        
        # Cooking with Windows
        if self.config[:kitchen_template].eql? "windows" 
          @winrm_port=config[:winrm_port] || 5985
          @windows_box=config[:windows_box] || "ge_windows2008r2"
          @windows_box_url=config[:windows_box_url] || "http://acusvinolare001.frictionless.capital.ge.com/virtualbox/ge_windows2008r2.box"
          @box_hostname=config[:box_hostname] || "windows2008r2"
        end
        # Start up some recursive template rendering
        recurseTemplate(templateDir,targetDir)
      end

      # This method recurses over a template directory to make the kitchen scaffold in cookbook_path.
      # It:-
      # * Calls "render" on *.erb files
      # * Creates subdirectories
      # * Creates .gitkeep files for empty directories
      def recurseTemplate(templateDir,targetDir)

        if not Dir.exists?(targetDir)
          puts "Create Dir:  #{targetDir}"
          FileUtils.mkpath(targetDir)
        end
        
        Dir.foreach(templateDir) do |filename|

          sourceName=File.join(templateDir,filename)
          targetName=File.join(targetDir,filename)

          # Skip over . and ..
          if ( filename !='.' && filename != '..')

            case File.ftype(sourceName)

              when 'directory'
                recurseTemplate( sourceName, targetName)    # Recurse to process a subdirectory

              when 'file'
                if not File.exists?(targetName)
                  renderFile( sourceName, targetName )
                end

              else # This is not a file or dir so dia a horrible death
                ui.fatal "Cannot process #{File.ftype(sourceName)}: #{sourceName}"
            end # of case
          end # if not . or ..
        end # of for each
      end # of def render

      # This method uses ERB to render template files using embedded ruby
      # Note that we don't use .erb extensions. All files get rendered
      def renderFile(templateFile, targetFile)
        puts "Render file: #{targetFile}"      
        erb=ERB.new(File.read(templateFile))
        File.new(targetFile,'w+').write(erb.result(binding))
      end # of render
      
    end
  end
end
