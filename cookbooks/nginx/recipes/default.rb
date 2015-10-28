#
# Cookbook Name:: nginx
# Recipe:: nginx
#

execute "restart-nginx" do
  action :nothing
  command "/etc/init.d/nginx restart"
end

if app_server?
  http_port = solo? ? 80 : 81
  https_port = solo? ? 443 : 444
  ssl = node[:engineyard][:environment][:apps].first[:vhosts].first[:ssl_cert].nil? ? false : true

  node[:applications].each do |app_name,data|
    bash "create-keep-files" do
      user node[:owner_name]
      code "touch /etc/nginx/servers/keep.#{app_name}.conf && touch /etc/nginx/servers/keep.#{app_name}.ssl.conf"
    end

    template "/etc/nginx/servers/#{app_name}.conf" do
      source 'app.conf.erb'
      owner node[:owner_name]
      group node[:owner_name]
      mode 0644
      variables({
        :framework_env => node[:environment][:framework_env],
        :app_name => app_name,
        :http_port => http_port
      })
      notifies :run, resources(:execute => "restart-nginx"), :delayed
    end

    template "/etc/nginx/servers/#{app_name}.ssl.conf" do
      source 'app.ssl.conf.erb'
      owner node[:owner_name]
      group node[:owner_name]
      mode 0644
      variables({
        :app_name => app_name,
        :https_port => https_port
      })
      notifies :run, resources(:execute => "restart-nginx"), :delayed
    end
  end
end
