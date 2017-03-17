module Fusor::Api::V21
  module LifecycleEnvironmentsMixin
    extend ActiveSupport::Concern

    included do
      include Fusor::Api::V21::AuthenticationMixin
    end

    def get_lifecycle_environments
      connection = get_sat_connection

      # TODO - remove hardcode of ?organization_id=1
      json_response = connection.get('katello/api/v2/environments?organization_id=1')
      json_response.body["results"].map do |hash|
        {id: hash['id'],
         name: hash['name'],
         label: hash['label'],
         description: hash['description'],
         library: hash['library'],
         prior: (hash['prior']['id'] if hash['prior']),
         prior_id: (hash['prior']['id'] if hash['prior']),
         created_at: hash['created_at'],
         updated_at: hash['updated_at']
         }
      end
    end

    def get_lifecycle_environment(id)
      connection = get_sat_connection

      # TODO - remove hardcode of ?organization_id=1
      json_response = connection.get("katello/api/v2/environments/#{params[:id]}?organization_id=1")
      hash = json_response.body
      {id: hash['id'],
       name: hash['name'],
       label: hash['label'],
       description: hash['description'],
       library: hash['library'],
       prior: (hash['prior']['id'] if hash['prior']),
       prior_id: (hash['prior']['id'] if hash['prior']),
       created_at: hash['created_at'],
       updated_at: hash['updated_at']
      }
    end

  end
end