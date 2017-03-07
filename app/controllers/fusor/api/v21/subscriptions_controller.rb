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

class Fusor::Api::V21::SubscriptionsController < ApplicationController
  skip_before_filter :check_content_type, :only => [:upload]

  resource_description do
    desc 'Information about subscriptions related to a deployment'
    api_version 'fusor_v21'
    api_base_url '/fusor/api/v21'
  end

  def_param_group :subscription do
    param :deployment_id, String, desc: 'ID of the deployment using this subscription'
    param :contract_number, String, desc: 'Contract number'
    param :product_name, String, desc: 'Product name'
    param :quantity_attached, String, desc: 'Quantity attached'
    param :start_date, Date, desc: 'Start date'
    param :end_date, Date, desc: 'Expiration date'
    param :total_quantity, Integer, desc: 'Total quantity'
    param :source, String, desc: 'Source'
    param :quantity_to_add, Integer, desc: 'Quantity to add'
  end

  api :GET, '/subscriptions', 'Gets a list of subscription objects'
  param :deployment_id, Integer, desc: 'filter by the ID of the deployment '
  param :source, :identifier, desc: 'filter by subscription source'
  def index
    if params[:deployment_id] && params[:source]
      Rails.logger.debug "filtering by deployment_id AND by source: #{params[:source]}"
      @subscriptions = Subscription.where(:deployment_id => params[:deployment_id],
                                                   :source => params[:source])
    elsif params[:deployment_id]
      Rails.logger.debug "filtering by deployment_id"
      @subscriptions = Subscription.where(:deployment_id => params[:deployment_id])
    elsif params[:source]
      Rails.logger.debug "filtering by source: #{params[:source]}"
      @subscriptions = Subscription.where(:source => params[:source])
    else
      Rails.logger.debug "finding all"
      @subscriptions = Subscription.all
    end
    render json: {subscriptions: @subscriptions}
  end

  api :POST, '/subscriptions', 'create a subscription'
  param_group :subscription
  def create
    @subscription = Subscription.new(subscription_params)
    if @subscription.save
      render json: {subscription: @subscription}
    else
      render json: {errors: @subscription.errors}, status: 422
    end
  end

  api :GET, '/subscriptions', 'Gets a list of subscription objects'
  param :id, Integer, desc: 'ID of the subscription'
  def show
    @subscription = Subscription.find(params[:id])
    render json: {subscription: @subscription}
  end

  api :PUT, '/subscriptions/:id', 'create a subscription'
  param :id, Integer, desc: 'ID of the subscription'
  param_group :subscription
  def update
    @subscription = Subscription.find(params[:id])
    if @subscription.update_attributes(subscription_params)
      render json: {subscription: @subscription}
    else
      render json: {errors: @subscription.errors}, status: 422
    end
  end

  api :DELETE, '/subscriptions/:id', 'delete a subscription'
  param :id, Integer, desc: 'ID of the subscription'
  def destroy
    @subscription = Subscription.find(params[:id])
    @subscription.destroy
    render json: {}, status: 204
  end

  api :PUT, '/subscriptions', 'upload a subscription manifest file'
  param :manifest_file, Hash, desc: 'ID of the subscription' do
    param :file, :identifier, required: true, desc: 'ID of the deployment'
    param :deployment_id, Integer, required: true, desc: 'ID of the deployment'
  end
  def upload
    Rails.logger.debug "upload params #{params}"
    #fail ::Katello::HttpErrors::BadRequest, _("No manifest file uploaded") if params[:manifest_file][:file].blank?
    #fail ::Katello::HttpErrors::BadRequest, _("No deployment specified") if params[:manifest_file][:deployment_id].blank?

    deployment = Deployment.find(params[:manifest_file][:deployment_id])
    deployment.subscriptions = []
    deployment.save(:validate => false)

    begin
      # candlepin requires that the file has a zip file extension
      temp_file = File.new(File.join("#{Rails.root}/tmp", "import_#{SecureRandom.hex(10)}.zip"), 'wb+', 0600)
      temp_file.write params[:manifest_file][:file].read
      deployment.update_attribute("manifest_file", temp_file.path)
    ensure
      temp_file.close
    end

    Rails.logger.info "Import the manifest into the DB"

    mi = Fusor::Manifest::ManifestImporter.new
    entitlements = mi.get_subscriptions(temp_file.path, deployment.id)

    entitlements.each do |entitlement|
      @subscription = Subscription.where(:deployment_id => deployment.id, :contract_number => entitlement['pool']['contractNumber']).first_or_initialize
      @subscription.deployment_id = deployment.id
      @subscription.contract_number = entitlement['pool']['contractNumber']
      @subscription.product_name = entitlement['pool']['productName']
      @subscription.start_date = entitlement['startDate']
      @subscription.end_date = entitlement['endDate']
      @subscription.quantity_attached = entitlement['quantity']
      @subscription.total_quantity = entitlement['pool']['quantity']
      @subscription.source = "imported"
      @subscription.save!
    end

    render json: {manifest_file: temp_file.path}, status: 200
  end

  api :GET, '/subscriptions/validate', 'Validate a subscription'
  param :deployment_id, Integer, desc: 'ID of the deployment'
  def validate
    Rails.logger.debug "Enter SubscriptionController.validate"
    valid = false
    if params[:deployment_id]

      Rails.logger.debug "SubscriptionController.validate: We have a deployment id"
      deployment = Deployment.find(params[:deployment_id])
      subvalidator = Fusor::Subscriptions::SubscriptionValidator.new
      # TODO get username + password
      valid = subvalidator.validate(deployment, 'rhci-test', 'rhcirhci', manifest_imported?, deployment.is_disconnected)

    else
      Rails.logger.error "SubscriptionController.validate: NO DEPLOYMENT ID"
      valid = false
    end

    Rails.logger.debug "Leave SubscriptionController.validate, returning #{valid}"
    render json: {valid: valid}, status: 200
  end

  private

  def manifest_imported?
    # if there are no subscriptions besides Fusor, we haven't
    # imported a manifest yet
    # TODO - return using Katello API
    return false
    # return !::Katello::Subscription.where.not(name: "Fusor").empty?
  end

  def subscription_params
    params.require(:subscription).permit(:contract_number, :product_name, :quantity_to_add, :quantity_attached,
                                         :start_date, :end_date, :total_quantity, :source, :deployment_id)
  end

end
