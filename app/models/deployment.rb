require 'open3'

#
# Copyright 2015 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

# == Schema Information
#
# Table name: deployments
#
#  id                               :integer          not null, primary key
#  name                             :string
#  lifecycle_environment_id         :integer
#  organization_id                  :integer
#  deploy_rhev                      :boolean          default("false")
#  deploy_cfme                      :boolean          default("false")
#  deploy_openstack                 :boolean          default("false")
#  rhev_engine_host_id              :integer
#  rhev_data_center_name            :string
#  rhev_cluster_name                :string
#  rhev_storage_name                :string
#  rhev_storage_type                :string
#  rhev_storage_address             :string
#  rhev_cpu_type                    :string
#  rhev_share_path                  :string
#  cfme_install_loc                 :string
#  description                      :text
#  rhev_is_self_hosted              :boolean          default("false")
#  rhev_engine_admin_password       :string
#  foreman_task_uuid                :string
#  upstream_consumer_uuid           :string
#  rhev_root_password               :string
#  cfme_root_password               :string
#  upstream_consumer_name           :string
#  rhev_export_domain_name          :string
#  rhev_export_domain_address       :string
#  rhev_export_domain_path          :string
#  rhev_local_storage_path          :string
#  host_naming_scheme               :string
#  custom_preprend_name             :string
#  enable_access_insights           :boolean          default("false")
#  cfme_admin_password              :string
#  cdn_url                          :string
#  manifest_file                    :string
#  is_disconnected                  :boolean
#  label                            :string
#  deploy_openshift                 :boolean          default("false")
#  openshift_install_loc            :string
#  openshift_storage_size           :integer          default("0")
#  openshift_username               :string
#  openshift_master_vcpu            :integer          default("0")
#  openshift_master_ram             :integer          default("0")
#  openshift_master_disk            :integer          default("0")
#  openshift_node_vcpu              :integer          default("0")
#  openshift_node_ram               :integer          default("0")
#  openshift_node_disk              :integer          default("0")
#  openshift_available_vcpu         :integer          default("0")
#  openshift_available_ram          :integer          default("0")
#  openshift_available_disk         :integer          default("0")
#  openshift_number_master_nodes    :integer          default("0")
#  openshift_number_worker_nodes    :integer          default("0")
#  openshift_storage_type           :string
#  openshift_export_path            :string
#  cloudforms_vcpu                  :integer          default("0")
#  cloudforms_ram                   :integer          default("0")
#  cloudforms_vm_disk_size          :integer          default("0")
#  cloudforms_db_disk_size          :integer          default("0")
#  has_content_error                :boolean
#  openshift_subdomain_name         :string
#  ose_public_key_path              :string
#  ose_private_key_path             :string
#  openshift_user_password          :string
#  openshift_root_password          :string
#  openshift_storage_host           :string
#  hosted_storage_name              :string
#  hosted_storage_type              :string
#  hosted_storage_address           :string
#  hosted_storage_path              :string
#  openstack_deployment_id          :integer
#  cfme_db_password                 :string
#  openshift_sample_helloworld      :boolean          default("false")
#  rhev_self_hosted_engine_hostname :string
#  cfme_rhv_address                 :string
#  cfme_rhv_hostname                :string
#  cfme_osp_address                 :string
#  cfme_osp_hostname                :string
#  ssh_public_key                   :text
#  ssh_private_key                  :text
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#

class Deployment < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => {:scope => :organization_id}

  scoped_search :on => [:id, :name, :updated_at], :complete_value => true
  scoped_search :in => :organization, :on => :name, :rename => :organization
  scoped_search :in => :lifecycle_environment, :on => :name, :rename => :lifecycle_environment
  scoped_search :in => :foreman_task, :on => :state, :rename => :status

  # used by ember-data for .find('model', {id: [1,2,3]})
  scope :by_id, proc { |n| where(:id => n) if n.present? }

  # since there are no has_many relationships
  attr_accessor :openshift_host_ids,
                :subscription_ids,
                :introspection_task_ids,
                :foreman_task_id

  alias_attribute :discovered_host_id, :rhev_engine_host_id

  # if we want to envorce discovered host uniqueness uncomment this line
  #validates :rhev_engine_host_id, uniqueness: { :message => _('This Host is already an RHV Engine for a different deployment') }

  has_many :deployment_hosts

  has_many :deployment_hypervisor_hosts, -> { where(:deployment_host_type => 'rhev_hypervisor') }, :class_name => "DeploymentHost"
  has_many :ose_deployment_master_hosts, -> { where(:deployment_host_type => 'ose_master') },      :class_name => "DeploymentHost"
  has_many :ose_deployment_worker_hosts, -> { where(:deployment_host_type => 'ose_worker') },      :class_name => "DeploymentHost"
  has_many :ose_deployment_ha_hosts,     -> { where(:deployment_host_type => 'ose_ha') },          :class_name => "DeploymentHost"

  # since can't have has_many :discovered_host, so no model discoverd_hosts,
  # need to create collection_ids= methods manually
  def discovered_host_ids
    @discovered_host_ids ||= self.deployment_hypervisor_hosts.pluck(:discovered_host_id)
  end

  def discovered_host_ids=(ids = [])
    # delete rows if array is not empty
    self.deployment_hypervisor_hosts
        .where(discovered_host_id: self.discovered_host_ids - ids)
        .destroy_all

    # add rows if array is not empty
    (ids - self.discovered_host_ids).each do |id|
      deployment_hypervisor_hosts.create(discovered_host_id: id)
    end
  end

  def execute_ansible_run
    self.run_number = run_number + 1
    self.save!
    package = FusorAnsible::DeploymentAnsiblePackage.new(self)
    package.write
    Open3.capture2e(package.environment, package.command)
  end

end
