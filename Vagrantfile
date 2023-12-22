# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = '2'

# Make sure you have run "git submodule init && git submodule update" to pull the infrastructure code
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  if ENV['EXTRA_POWER'] == 'true'
    config.vm.provider 'virtualbox' do |vbox|
      vbox.memory = 1024
      vbox.cpus = 2
    end
  end

  config.vm.define 'dev', primary: true do |dev|
    dev.vm.box = 'hashicorp/precise32'
    dev.vm.network 'forwarded_port', guest: 3000, host: 3000
    dev.vm.network 'forwarded_port', guest: 5984, host: 5984
    dev.vm.network 'forwarded_port', guest: 8983, host: 8983
    dev.ssh.forward_x11 = true
    dev.ssh.forward_agent = true
    dev.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = 'infrastructure/site-cookbooks'
      chef.roles_path = 'infrastructure/roles'
      chef.add_role 'development'
      chef.verbose_logging = true
    end
    dev.vm.synced_folder 'tmp/vagrant/dev/apt', '/var/cache/apt/archives', create: true
    dev.vm.synced_folder 'tmp/vagrant/dev/gems', '/usr/local/rvm/gems/ruby-2.1.2@rapidftr/cache', create: true, mount_options: ['dmode=777', 'fmode=666']
    dev.vm.synced_folder 'tmp/vagrant/dev/rubies', '/usr/local/rvm/archives', create: true, mount_options: ['dmode=777', 'fmode=666']
  end

  config.vm.define 'prod', autostart: false do |prod|
    prod.vm.box = 'hashicorp/precise64'
    prod.vm.network 'forwarded_port', guest: 80, host: 8080
    prod.vm.network 'forwarded_port', guest: 443, host: 8443
    prod.vm.network 'forwarded_port', guest: 5984, host: 5984
    prod.vm.network 'forwarded_port', guest: 6984, host: 6984
    prod.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = 'infrastructure/site-cookbooks'
      chef.roles_path = 'infrastructure/roles'
      chef.add_role 'production'
      chef.verbose_logging = true
    end
    prod.vm.synced_folder 'tmp/vagrant/prod/apt', '/var/cache/apt/archives', create: true
    prod.vm.synced_folder 'tmp/vagrant/prod/gems2.1.0', '/srv/rapidftr/localhost/shared/gems/ruby/2.1.0/cache', create: true, mount_options: ['dmode=777', 'fmode=666']
    prod.vm.synced_folder 'tmp/vagrant/prod/gems2.1.2', '/srv/rapidftr/localhost/shared/gems/ruby/2.1.2/cache', create: true, mount_options: ['dmode=777', 'fmode=666']
  end

end
