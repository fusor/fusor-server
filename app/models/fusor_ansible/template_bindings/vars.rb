module FusorAnsible
  module TemplateBindings
    class Vars < Default
      def initialize(deployment)
        super(deployment)
        @rhv_engine_hostgroup_title =  "Fusor Base/#{@deployment.label}/RHV-Engine"
        @rhv_hypervisor_hostgroup_title =  "Fusor Base/#{@deployment.label}/RHV-Hypervisor"
        @rhv_cpu_model = get_cpu_model(deployment.rhev_cpu_type)
        @rhv_mac_address_range = get_mac_address_range(deployment.id)
        @rhv_self_hosted_engine_fqdn = ''
        if @deployment.deploy_rhev && @deployment.rhev_is_self_hosted
          @rhv_self_hosted_engine_fqdn = "#{@deployment.rhev_self_hosted_engine_hostname}.#{@satellite_domain}"
        end
      end

      private

      def get_cpu_model(cpu_type)
        {
            'Intel Penryn Family' => 'model_Penryn',
            'Intel Nehalem Family' => 'model_Nehalem',
            'Intel Westmere Family' => 'model_Westmere',
            'Intel SandyBridge Family' => 'model_SandyBridge',
            'Intel Haswell Family' => 'model_Haswell',
            'Intel Haswell-noTSX Family' => 'model_Haswell-noTSX',
            'Intel Broadwell Family' => 'model_Broadwell',
            'Intel Broadwell-noTSX Family' => 'model_Broadwell-noTSX',
            'AMD Opteron G1' => 'model_Opteron_G1',
            'AMD Opteron G2' => 'model_Opteron_G2',
            'AMD Opteron G3' => 'model_Opteron_G3',
            'AMD Opteron G4' => 'model_Opteron_G4',
            'AMD Opteron G5' => 'model_Opteron_G5',
            # 'IBM POWER 8' => 'UNSUPPORTED',
        }[cpu_type]
      end

      def get_mac_address_range(deployment_id)
        # TODO Why not more than 255?  Why start at 1A?
        fail _('Too many deployments to generate a unique mac address pool') if deployment_id > 255
        identifier = deployment_id.to_s(16).rjust(2, '0')
        first = "00:1A:#{identifier}:00:00:00"
        last = "00:1A:#{identifier}:FF:FF:FF"
        "#{first},#{last}"
      end
    end
  end
end
