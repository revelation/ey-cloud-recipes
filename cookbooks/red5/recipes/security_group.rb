#
# Cookbook Name:: red5
# Recipe:: security_group
#

if app_master? || solo?

  def already_open?(range, group)
    open_port = false
    group.ip_permissions.each do |ip_permission|
      open_port = true if range.include?(ip_permission.fetch("toPort"))
    end
    open_port
  end

  require 'fog'

  # create fog connection to EC2
  connection = Fog::Compute.new(
    :provider                 => 'AWS',
    :aws_secret_access_key    => node[:engineyard][:environment][:aws_secret_key],
    :aws_access_key_id        => node[:engineyard][:environment][:aws_secret_id],
    :region                   => node[:engineyard][:environment][:region]
  )

  # get any security groups matching the environment name
  groups = connection.security_groups.all('group-name' => "*#{node[:engineyard][:environment][:name]}*")

  groups.each do |group|
    node[:red5][:ports].each do |port|
      ruby_block "open port #{port}" do
        block do
          group.authorize_port_range(port..port)
        end
        ignore_failure true
        action :create
      end
    end
  end
end
