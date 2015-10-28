#
# Cookbook Name:: nfs
# Recipe:: slave
#

# Install package, dependent on platform
node['nfs']['packages'].each do |nfspkg|
  package nfspkg
end

# Determine the NFS master hostname
nfs_master_hostname = nil
if node[:utility_instances]
  nfs_master = node[:utility_instances].find {|u| u[:name] == node['nfs']['instance_name'] }
  if nfs_master && nfs_master[:hostname]
    nfs_master_hostname = nfs_master[:hostname]
  end
end

# Run on all instances except for the NFS master
unless node[:name] == nfs_master[:name]

  if(util? || app_server?) && !solo? && !nfs_master_hostname.nil?

    # Start NFS client components
    service "portmap" do
      service_name node['nfs']['service']['portmap']
      action [ :start, :enable ]
    end

    # Configure NFS client components
    node['nfs']['config']['client_templates'].each do |client_template|
      template client_template do
        source "#{client_template.split("/").last}.erb"
        mode 0644
        notifies :restart, resources(:service => [ 'portmap' ] )
        variables({
          :statd => node["nfs"]["port"]["statd"],
          :statd_out => node["nfs"]["port"]["statd_out"],
          :mountd_port => node["nfs"]["port"]["mountd"],
          :lockd_port => node["nfs"]["port"]["lockd"],
          :hostname => node['name']
        })
      end
    end

    # If we reboot the environment, the NFS hostname will change so we need to clean out the fstab entries with the old hostname
    ruby_block "cleanup" do
      block do
        if system("cat /etc/fstab | grep 'nfs'")
          if !system("cat /etc/fstab | grep '#{nfs_master_hostname}:/data /shared nfs defaults 0 0'")
            system("sed -i '$ d' /etc/fstab")
          end
        end
      end
    end

    # Directory that the NFS partition will be mounted to
    directory "/shared" do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0755
      recursive true
    end

    execute "update-fstab" do
      command "echo '#{nfs_master_hostname}:/data /shared nfs defaults 0 0' >> /etc/fstab"
      not_if "grep '#{nfs_master_hostname}:/data /shared nfs defaults 0 0' /etc/fstab"
    end

    # Loop until NFS master is ready and can be mounted
    ruby_block "wait-for-nfs_master" do
      block do
        until File.exists?("/shared/nfs.exists") do
          Chef::Log.info("NFS master not ready yet")
          sleep 5
          system("mount /shared")
        end
      end
    end

    # Create application specific symlinks for asset storage
    node['applications'].each do |app_name,data|
      node[:nfs][:links].each do |link|
        link "/data/#{app_name}/shared/#{link}" do
          to "/shared/#{app_name}/shared/#{link}/"
        end

        # Set ownership as Chef 0.6.x link does not allow owner/group parameters
        bash "set-ownership-on-#{app_name}-#{link}" do
          code "chown -h #{node[:owner_name]}:#{node[:owner_name]} /data/#{app_name}/shared/#{link}"
        end
      end
    end
  end
end
