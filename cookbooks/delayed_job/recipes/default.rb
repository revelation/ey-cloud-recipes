#
# Cookbook Name:: delayed_job
# Recipe:: default
#

if node[:instance_role] == "solo" || (node[:instance_role] == "util" && node[:name] == node[:delayed_job][:instance_name])
  node[:applications].each do |app_name,data|

    if node[:instance_role] == 'solo'
      worker_count = 1
    else
      worker_count = node[:delayed_job][:worker_count]
    end

    worker_count.times do |count|
      template "/etc/monit.d/delayed_job#{count+1}.#{app_name}.monitrc" do
        source "dj.monitrc.erb"
        owner "root"
        group "root"
        mode 0644
        variables({
          :app_name => app_name,
          :user => node[:owner_name],
          :worker_name => "#{app_name}_delayed_job#{count+1}",
          :framework_env => node[:environment][:framework_env]
        })
      end
    end

    execute "monit reload" do
       action :run
       epic_fail true
    end

  end
end
