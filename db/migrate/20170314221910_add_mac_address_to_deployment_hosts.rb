class AddMacAddressToDeploymentHosts < ActiveRecord::Migration
  def change
    add_column :deployment_hosts, :mac_address, :string
  end
end
