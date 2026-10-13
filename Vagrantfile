Vagrant.configure("2") do |config|
  config.vm.define "router" do |r|
    r.vm.box = "bento/ubuntu-24.04"
    r.vm.hostname = "router"
    r.vm.network "private_network", ip: "10.42.10.1", virtualbox__intnet: "net10"
    r.vm.network "private_network", ip: "10.42.20.1", virtualbox__intnet: "net20"
  end
  config.vm.define "app" do |a|
    a.vm.box = "bento/ubuntu-24.04"
    a.vm.hostname = "app"
    a.vm.network "private_network", ip: "10.42.10.10", virtualbox__intnet: "net10"
  end
end