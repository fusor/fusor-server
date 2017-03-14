module FusorAnsible
  module TemplateBindings
    class Hosts < Default
      def initialize(deployment)
        super(deployment)

        #TODO implement when model changes are complete
        # @rhv_engine_fqdn = "#{@deployment.rhev_engine_host.hostname}.#{@satellite_domain}"
        # @rhv_hypervisor_fqdn_list = @deployment.rhev_hypervisor_hosts.map{ |host| "#{host.hostname}.#{@satellite_domain}" }
        if @deployment.deploy_rhev
          if @deployment.rhev_is_self_hosted
            @rhv_hypervisor_engine_host = "#{@deployment.rhv_hypervisor_hosts[0].host_name}.#{@satellite_domain} host_id=1 mac_address=#{@deployment.rhv_hypervisor_hosts[0].mac_address}"
            @rhv_engine_host = "#{@deployment.rhev_self_hosted_engine_hostname}.#{@satellite_domain} "
            @rhv_hypervisor_host_list = @deployment.rhv_hypervisor_hosts[1..-1].map.with_index { |host, idx| "#{host.host_name}.#{@satellite_domain} host_id=#{idx+2} mac_address=#{host.mac_address}" }
          else
            @rhv_hypervisor_engine_fqdn = ''
            @rhv_engine_host = "#{@deployment.rhv_engine_hosts[0].host_name}.#{@satellite_domain}"
            @rhv_hypervisor_host_list = @deployment.rhv_hypervisor_hosts.map { |host| "#{host.host_name}.#{@satellite_domain}" }
          end
        end
      end

    end
  end
end
