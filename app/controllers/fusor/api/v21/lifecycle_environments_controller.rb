class Fusor::Api::V21::LifecycleEnvironmentsController < ApplicationController

  include Fusor::Api::V21::LifecycleEnvironmentsMixin

  #include Api::Version21

  def index
    render json: {lifecycle_environments: get_lifecycle_environments}
  end

  def show
    render json: {lifecycle_environment: get_lifecycle_environment(params[:id])}
  end

  def create
    connection = get_sat_connection

    # TODO - remove hardcode of ?organization_id=1
    json_response = connection.post do |req|
      req.url 'katello/api/v2/environments?organization_id=1'
      req.headers['Content-Type'] = 'application/json'
      req.body = {environment: params[:lifecycle_environment]}.to_json
    end

    render json: {lifecycle_environment: {
                      id: json_response.body['id'],
                      name: json_response.body['name'],
                      label: json_response.body['label'],
                      description: json_response.body['description'],
                      prior: (json_response.body['prior']['id'] if json_response.body['prior']),
                      prior_id: (json_response.body['prior']['id'] if json_response.body['prior']),
                      organization_id: json_response.body['organization_id'],
                      created_at: json_response.body['created_at'],
                      updated_at: json_response.body['updated_at']
                    }
                  }
  end

end
