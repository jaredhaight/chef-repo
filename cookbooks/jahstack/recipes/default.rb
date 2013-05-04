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
include_recipe "openssl"
include_recipe "postgresql::server"
include_recipe "postgresql::client"
include_recipe "database::postgresql"

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

directory node["jahstack"]["django_home"] do
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
        :uwsgi_home		=> node["jahstack"]["django_home"],
	:uwsgi_module		=> node["jahstack"]["uwsgi_module_location"],
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

template "#{node[:jahstack][:django_app_home]}/settings.py" do
    source "settings.py.erb"
    owner node["jahstack"]["run_user"]
    group node["jahstack"]["run_group"]
    variables(
	:django_static_dir	=> node["jahstack"]["django_static_dir"],
        :django_secret_key      => node["jahstack"]["django_secret_key"],
	:postgresql_database	=> node["jahstack"]["postgresql_database"],
	:postgresql_user	=> node["jahstack"]["postgresql_user"],
	:postgresql_password	=> node["jahstack"]["postgresql_password"])
    action :nothing
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
    notifies :run, "execute[install_requirements]"
end

service "uwsgi" do
    service_name "uwsgi"
    provider Chef::Provider::Service::Upstart
    supports :restart => true, :start => true, :stop => true
    action [:enable, :start]
end

execute "install_requirements" do
    cwd node["jahstack"]["django_home"]
    user "jared"
    command "#{node[:jahstack][:python_venv_dir]}/bin/pip install -r #{node[:jahstack][:django_home]}/requirements.txt"
    action :nothing
end

git node["jahstack"]["django_home"] do
  repository "git://github.com/photosandtext/todo_site.git"
  reference "master"
  action :checkout
  notifies :create, "template[#{node[:jahstack][:django_app_home]}/settings.py]"
end

postgresql_database node["jahstack"]["postgresql_database"] do
  connection ({:host => "127.0.0.1", :port => 5432, :username => 'postgres', :password => node['jahstack']['postgresql_password']})
  action :create
end

