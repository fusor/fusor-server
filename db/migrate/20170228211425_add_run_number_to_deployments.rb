class AddRunNumberToDeployments < ActiveRecord::Migration
  def change
    add_column :deployments, :run_number, :integer, :null => false, :default => 0
  end
end
