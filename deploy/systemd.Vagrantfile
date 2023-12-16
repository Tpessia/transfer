# Define the number of node nodes
NUM_NODES = 2

Vagrant.configure("2") do |config|
  # Create the systemd machine
  config.vm.define "systemd" do |systemd|
    config.vm.synced_folder ".", "/vagrant", type: "nfs", mount_options: ["vers=3,tcp"] #, nfs_export: false # "nsf", "rsync", "vboxsf"
    systemd.vm.box = "generic/ubuntu1804"
    systemd.vm.hostname = "systemd"
    systemd.vm.network "private_network", type: "dhcp"
    config.vm.provider :libvirt do |libvirt|
      libvirt.driver = "kvm" # qemu, kvm, xen
      libvirt.memory = 4096
      libvirt.cpus = 2
    end
    systemd.vm.provision "shell", path: "deploy/provision.sh", privileged: false
  end

  # Log config
  #config.trigger.after :up do |trigger|
  #  trigger.run = {inline: "bash -c 'echo -e \"\n--- CONFIGS ---\" && cat .temp/config'"}
  #end

  # Run a cleanup command before destroying the environment
  config.trigger.before :destroy do |trigger|
    trigger.info = "Running cleanup command..."
    trigger.run = {inline: "rm -rf .temp"}
  end
end
