module FusorAnsible
  module TemplateBindings
    class Default
      def initialize(deployment)
        @deployment = deployment

        @satellite_fqdn           = Rails.configuration.external_apis['satellite_fqdn']
        @satellite_domain         = Rails.configuration.external_apis['satellite_domain']
        @satellite_subnet         = Rails.configuration.external_apis['satellite_subnet']
        @satellite_subnet_gateway = Rails.configuration.external_apis['satellite_subnet_gateway']
        @satellite_username       = Rails.configuration.external_apis['satellite_api_username']
        @satellite_password       = Rails.configuration.external_apis['satellite_api_password']
      end

      def get_binding
        binding
      end
    end
  end
end
