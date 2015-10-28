#
# Cookbook Name:: nfs
# Recipe:: master
#
# Copyright 2011, Eric G. Wolfe
#
# Licensed under the Apache License, Version 2.0(the "License");
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

if util?(node['nfs']['instance_name'])

   # slave recipe checks for file existance to ensure NFS is mounted properly
   execute "create-nfs.exists-file" do
     command "touch /data/nfs.exists"
   end

   # Start nfs-server components
   service node['nfs']['service']['server'] do
     action [ :start, :enable ]
   end

  # Configure nfs-server components
  template node['nfs']['config']['server_template'] do
    source "nfs.erb"
    mode 0644
    notifies :restart, resources(:service => node['nfs']['service']['server'])
  end

  execute "restart-nfs" do
    command "/etc/init.d/nfs restart"
  end

  execute "exportfs" do
    command "exportfs -ar"
    action :nothing
  end

  unless node["nfs"]["exports"].empty?
    template "/etc/exports" do
       source "exports.erb"
       mode 0644
       notifies :run, resources(:execute => "exportfs")
       variables({
         :exports => node["nfs"]["exports"],
         :hostname => node['name']
       })
    end
  end

  # Create shared directories
  node['applications'].each do |app_name,data|
    node[:nfs][:links].each do |link|
      directory "/data/#{app_name}/shared/#{link}" do
        action :create
        recursive true
        owner node['owner_name']
        group node['owner_name']
        mode 0755
      end
    end
  end

end
