#
# Cookbook Name:: red5
# Recipe:: install
#

if app_master?
  #remote_file "/home/#{node[:owner_name]}/#{node[:red5][:download_url].split("/").last}" do
  #  source node[:red5][:download_url]
  #  owner node[:owner_name]
  #  group node[:owner_name]
  #  mode '0755'
  #  action :create
  #end

  bash "download-red5" do
    user node[:owner_name]
    cwd "/home/#{node[:owner_name]}"
    code "wget -O /home/#{node[:owner_name]}/red5.tar.gz #{node[:red5][:download_url]}"
  end

  directory "/opt/red5" do
    owner node[:owner_name]
    group node[:owner_name]
    action :create
  end

  bash "unpackage-red5" do
    user node[:owner_name]
    cwd "/home/#{node[:owner_name]}"
    code "tar zxvf red5.tar.gz}"
  end

  bash "rsync-red5" do
    user node[:owner_name]
    code "rsync -av /home/#{node[:owner_name]}/red5/ /opt/red5/"
  end

  template "/etc/init.d/red5" do
    source 'red5.initd.erb'
    owner "root"
    group "root"
    mode 0777
    variables({
      :user => node[:owner_name]
    })
  end

  bash "add-to-runlevel" do
    code "rc-update add red5 default && /etc/init.d/red5 start && true;"
  end

  if app_server? || util?
    if solo?
      red5_hostname = "localhost"
    else
      red5_hostname = node[:master_app_server][:public_ip]
    end
    node[:applications].each do |app_name,data|
      template "/data/#{app_name}/shared/config/red5.yml" do
        source 'red5.yml.erb'
        owner node[:owner_name]
        group node[:owner_name]
        mode 0644
        variables({
          :rails_env => node[:environment][:framework_env],
          :red5_host => red5_hostname
        })
      end
    end
  end
end
