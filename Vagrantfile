# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. For a detailed explanation
  # and listing of configuration options, please view the documentation
  # online.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "precise32"
  config.vm.box_url = "http://files.vagrantup.com/precise32.box"

  config.vm.hostname = "wakamagedev"

  config.vm.network :forwarded_port, guest: 80, host: 8080
  config.vm.network :forwarded_port, guest: 3306, host: 3306

  config.vm.network :private_network, ip: "192.168.10.10"

  config.vm.synced_folder "./web", "/srv/web", owner: "www-data", group: "www-data"

  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = "cookbooks"
    chef.add_recipe("vagrant_main")
    chef.json.merge!({
      "mysql" => {
        "server_root_password" => "lamp2013$",
        "server_repl_password" => "lamp2013$",
        "server_debian_password" => "lamp2013$"
      },
      "site" => {
        "name" => "cosmeticasaludable.dev",
        "host" => "cosmeticasaludable.dev",
        "aliases" => ["www.cosmeticasaludable.dev"],
        "database" => "cosmeticasaludable",
        "docroot" => "/srv/web",
        "magento_package" => "http://www.magentocommerce.com/downloads/assets/1.7.0.2/magento-1.7.0.2.tar.bz2"
      }
    })
  end

end
