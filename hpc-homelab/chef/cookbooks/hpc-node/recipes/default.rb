# =========================================================
# chef/cookbooks/hpc-node/recipes/default.rb
# Configures a Slurm compute node using Chef
# Mirrors: ansible/roles/slurm_compute
# =========================================================

# Install Slurm compute daemon and MUNGE authentication
%w[slurm-slurmd munge].each do |pkg|
  package pkg do
    action :install
  end
end

# Deploy shared MUNGE key (pre-shared secret for Slurm auth)
directory '/etc/munge' do
  owner  'munge'
  group  'munge'
  mode   '0700'
  action :create
end

cookbook_file '/etc/munge/munge.key' do
  source   'munge.key'
  owner    'munge'
  group    'munge'
  mode     '0400'
  notifies :restart, 'service[munge]', :delayed
end

# Deploy slurm.conf from Chef template
template '/etc/slurm/slurm.conf' do
  source    'slurm.conf.erb'
  owner     'slurm'
  group     'slurm'
  mode      '0644'
  variables(
    controller_host:  node['slurm']['controller_host'],
    cluster_name:     node['slurm']['cluster_name'],
    state_save_dir:   node['slurm']['state_save_location']
  )
  notifies :restart, 'service[slurmd]', :delayed
end

# Ensure spool directory exists with correct ownership
directory node['slurm']['spool_dir'] do
  owner     'slurm'
  group     'slurm'
  mode      '0755'
  recursive true
  action    :create
end

# Enable and start daemons
service 'munge' do
  action [:enable, :start]
end

service 'slurmd' do
  action    [:enable, :start]
  supports  status: true, restart: true, reload: true
end

# Register node with controller on first boot
execute 'register-slurmd-node' do
  command "scontrol update NodeName=#{node['hostname']} State=RESUME"
  only_if { ::File.exist?('/var/run/slurmd.pid') }
  not_if  "sinfo -n #{node['hostname']} | grep -qE 'idle|alloc'"
end
