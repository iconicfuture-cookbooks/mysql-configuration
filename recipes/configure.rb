#
# Cookbook Name:: mysql-configuration
# Recipe:: configure
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

unless node['mysql'].nil?

  unless node['sites'].nil?
    node['sites'].each do |name, config|
      execute "#{name}-import-db-struct" do
        command "\"#{node['mysql']['mysql_bin']}\" -h #{config['mysql']['host']} -u root #{node['mysql']['server_root_password'].empty? ? '' : '-p' }\"#{node['mysql']['server_root_password']}\" < \"/var/www/#{config['fqdn']}/sql/prod.struct.sql\""
        only_if do
          File.exists?("/var/www/#{config['fqdn']}/sql/prod.struct.sql")
        end
      end

      execute "#{name}-import-db-data" do
        command "\"#{node['mysql']['mysql_bin']}\" -h #{config['mysql']['host']} -u root #{node['mysql']['server_root_password'].empty? ? '' : '-p' }\"#{node['mysql']['server_root_password']}\" < \"/var/www/#{config['fqdn']}/sql/prod.data.sql\""
        only_if do
          File.exists?("/var/www/#{config['fqdn']}/sql/prod.data.sql")
        end
      end

      execute "#{name}-apply-delta" do
        command "/var/www/#{config['fqdn']}/sql/delta.sh"
        user "root"
        action :run
        only_if do
          File.exists?("/var/www/#{config['fqdn']}/sql/delta.sh")
        end
      end

      execute "#{name}-apply-development" do
        command "\"#{node['mysql']['mysql_bin']}\" -h #{config['mysql']['host']} -u root #{node['mysql']['server_root_password'].empty? ? '' : '-p' }\"#{node['mysql']['server_root_password']}\" < \"/var/www/#{config['fqdn']}/sql/development.sql\""
        only_if do
          File.exists?("/var/www/#{config['fqdn']}/sql/development.sql")
        end
      end
    end
  end

  unless node['sites'].nil?
    node['sites'].each do |name, config|
      template "/tmp/bootstrap.#{name}.sql" do
        source "bootstrap.sql.erb"
        owner "root"
        group "root"
        mode 00644
        variables( :config => config['mysql'] )
        not_if do
          File.exists?("/var/www/#{config['fqdn']}/sql/prod.struct.sql")
        end
      end
      execute "#{name}-import-db-struct" do
        command "\"#{node['mysql']['mysql_bin']}\" -h #{config['mysql']['host']} -u root #{node['mysql']['server_root_password'].empty? ? '' : '-p' }\"#{node['mysql']['server_root_password']}\" < \"/tmp/bootstrap.#{name}.sql\""
        only_if do
          File.exists?("/tmp/bootstrap.#{name}.sql")
        end
      end
    end
  end

end
