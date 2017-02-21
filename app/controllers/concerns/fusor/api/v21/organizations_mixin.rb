module Fusor::Api::V21
  module OrganizationsMixin
    extend ActiveSupport::Concern

    included do
      include Fusor::Api::V21::AuthenticationMixin
      API_USERNAME = 'admin'
      API_PASSWORD = 'secret'

      SATELLITE_URL = 'http://localhost:9010/'
    end

    def get_organizations
      connection = Faraday.new SATELLITE_URL do |conn|
        conn.response :json
        conn.adapter Faraday.default_adapter
        conn.basic_auth API_USERNAME, API_PASSWORD
      end

      json_response = connection.get('katello/api/v2/organizations')
      json_response.body["results"]
    end

  end
end