unless node['mysql'].nil?

  unless node['sites'].nil?
    node['sites'].each do |name, config|
      execute "#{name}-import-db-struct" do
        command "\"#{node['mysql']['mysql_bin']}\" -u root #{node['mysql']['server_root_password'].empty? ? '' : '-p' }\"#{node['mysql']['server_root_password']}\" < \"/var/www/#{config['fqdn']}/sql/prod.struct.sql\""
        only_if do
          File.exists?("/var/www/#{config['fqdn']}/sql/prod.struct.sql")
        end
      end

      execute "#{name}-import-db-data" do
        command "\"#{node['mysql']['mysql_bin']}\" -u root #{node['mysql']['server_root_password'].empty? ? '' : '-p' }\"#{node['mysql']['server_root_password']}\" < \"/var/www/#{config['fqdn']}/sql/prod.data.sql\""
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
        command "\"#{node['mysql']['mysql_bin']}\" -u root #{node['mysql']['server_root_password'].empty? ? '' : '-p' }\"#{node['mysql']['server_root_password']}\" < \"/var/www/#{config['fqdn']}/sql/development.sql\""
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
        variables( :config => config['database'] )
        not_if do
          File.exists?("/var/www/#{config['fqdn']}/sql/prod.struct.sql")
        end
      end
      execute "#{name}-import-db-struct" do
        command "\"#{node['mysql']['mysql_bin']}\" -u root #{node['mysql']['server_root_password'].empty? ? '' : '-p' }\"#{node['mysql']['server_root_password']}\" < \"/tmp/bootstrap.#{config['name']}.sql\""
        only_if do
          File.exists?(/tmp/bootstrap.#{config['name']}.sql)
        end
      end
    end
  end

end
