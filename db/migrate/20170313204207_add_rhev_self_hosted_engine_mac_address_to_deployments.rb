class AddRhevSelfHostedEngineMacAddressToDeployments < ActiveRecord::Migration
  def change
    add_column :deployments, :rhev_self_hosted_engine_mac_address, :string
  end
end
