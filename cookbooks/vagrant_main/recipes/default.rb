include_recipe "apt"
include_recipe "apache2"
include_recipe "apache2::mod_rewrite"
include_recipe "apache2::mod_ssl"
include_recipe "mysql::server"
include_recipe "php"
include_recipe "apache2::mod_php5"

# Some neat package (subversion is needed for "subversion" chef ressource)
%w{ debconf php5-xdebug php5-curl subversion  }.each do |a_package|
  package a_package
end

# get phpmyadmin conf
cookbook_file "/tmp/phpmyadmin.deb.conf" do
  source "phpmyadmin.deb.conf"
end
bash "debconf_for_phpmyadmin" do
  code "debconf-set-selections /tmp/phpmyadmin.deb.conf"
end
package "phpmyadmin"

site = {
  :name => node[:site][:name],
  :host => node[:site][:host],
  :aliases => node[:site][:aliases],
  :docroot => node[:site][:docroot]
}

# Configure the development site
web_app site[:name] do
  template "sites.conf.erb"
  server_name site[:host]
  server_aliases site[:aliases]
  docroot "#{site[:docroot]}/magento"
end  

# Add site info in /etc/hosts
bash "info_in_etc_hosts" do
  code "echo 127.0.0.1 #{site[:host]} #{site[:aliases]} >> /etc/hosts"
end

# Retrieve webgrind for xdebug trace analysis
subversion "Webgrind" do
  repository "http://webgrind.googlecode.com/svn/trunk/"
  revision "HEAD"
  destination "/var/www/webgrind"
  action :sync
end

log "Downloading magento from #{node[:site][:magento_package]}"

# Download magento
execute "download_magento" do
  command "wget #{node[:site][:magento_package]} -O /tmp/magento.tar.bz2"
  action :run
  not_if { ::File.exists?(site[:docroot]) }
  ignore_failure true
end

log "Decompressing magento (this may take a while)"

# Decompress magento
execute "decompress_magento" do
  command "tar jxvf /tmp/magento.tar.bz2 -C #{site[:docroot]}"
  action :run
  not_if { ::File.exists?(site[:docroot]) }
  ignore_failure true
end

# Add an admin user to mysql
execute "add-admin-user" do
  command "/usr/bin/mysql -u root -p#{node[:mysql][:server_root_password]} -e \"" +
      "CREATE USER 'myadmin'@'localhost' IDENTIFIED BY 'myadmin';" +
      "GRANT ALL PRIVILEGES ON *.* TO 'myadmin'@'localhost' WITH GRANT OPTION;" +
      "CREATE USER 'myadmin'@'%' IDENTIFIED BY 'myadmin';" +
      "GRANT ALL PRIVILEGES ON *.* TO 'myadmin'@'%' WITH GRANT OPTION;" +
      "CREATE DATABASE #{node[:site][:database]};\" " +
      "mysql"
  action :run
  only_if { `/usr/bin/mysql -u root -p#{node[:mysql][:server_root_password]} -D mysql -r -N -e \"SELECT COUNT(*) FROM user where user='myadmin' and host='localhost'"`.to_i == 0 }
  ignore_failure true
end
