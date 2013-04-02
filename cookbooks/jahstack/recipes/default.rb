#
# Cookbook Name:: jahstack
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
include_recipe "nginx"
include_recipe "python"
include_recipe "python::pip"
include_recipe "python::virtualenv"
include_recipe "git"

file "/etc/chef/ohai_plugins/README" do
    action :delete
end

directory node["nginx"]["static_files_dir"] do
    owner "www-data"
    group "www-data"
    mode "0755"
    action :create
    recursive true
end


directory node["nginx"]["media_files_dir"] do
    owner "www-data"
    group "www-data"
    mode "0755"
    action :create
    recursive true
end

template "#{node[:nginx][:dir]}/sites-available/default" do
    source "default-site.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
        :static_files_dir        => node["nginx"]["static_files_dir"],
        :media_files_dir         => node["nginx"]["media_files_dir"])
end

directory node["jahstack"]["home"] do
    owner node["jahstack"]["run_user"]
    group node["jahstack"]["run_group"]
    mode "0755"
    action :create
    recursive true
end

directory node["jahstack"]["log_dir"] do
    owner node["jahstack"]["run_user"]
    group node["jahstack"]["run_group"]
    mode "0755"
    action :create
    recursive true
end

directory node["jahstack"]["etc"] do
    owner node["jahstack"]["run_user"]
    group node["jahstack"]["run_group"]
    mode "0755"
    action :create
    recursive true
end

template "#{node[:jahstack][:etc]}/uwsgi.ini" do
    source "uwsgi.ini.erb"
    owner node["jahstack"]["run_user"]
    group node["jahstack"]["run_group"]
    mode "0644"
    variables(
        :log_dir		=> node["jahstack"]["log_dir"],
        :uwsgi_home		=> node["jahstack"]["home"],
        :virtualenv		=> node["jahstack"]["python_venv_dir"])
end

template "/etc/init/uwsgi.conf" do
    source "uwsgi.conf.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
        :etc_dir                     => node["jahstack"]["etc"])
end

directory node["jahstack"]["python_venv_dir"] do
    owner node["jahstack"]["run_user"]
    group node["jahstack"]["run_group"]
    mode "0755"
    action :create
    recursive true
end

python_virtualenv node["jahstack"]["python_venv_dir"] do
    owner node["jahstack"]["run_user"]
    group node["jahstack"]["run_group"]
    action :create
end

python_pip "django" do
  virtualenv node["jahstack"]["python_venv_dir"] 
  action :install
end

python_pip "uwsgi" do
  action :install
end

service "uwsgi" do
    service_name "uwsgi"
    provider Chef::Provider::Service::Upstart
    supports :restart => true, :start => true, :stop => true
    action [:enable, :start]
end
