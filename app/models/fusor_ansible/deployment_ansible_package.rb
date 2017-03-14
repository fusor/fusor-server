require 'erb'


module FusorAnsible
  class DeploymentAnsiblePackage
    ROLES_SOURCE = '/usr/share/fusor-ansible/roles'
    DEPLOYMENT_BASE_DIR = "#{Rails.root}/tmp/ansible_deployments/"

    attr_accessor :vault_password
    attr_reader :ansible_package_dir, :files

    def initialize(deployment, vault_password = nil)
      @ansible_package_dir = File.join(DEPLOYMENT_BASE_DIR, "#{deployment.id}_#{deployment.label}_#{deployment.run_number}")
      @vault_password = vault_password || SecureRandom.urlsafe_base64
      init_file_info(deployment)
    end

    def write(directory = nil)
      package_dir = directory || @ansible_package_dir
      FileUtils.rm_rf(package_dir) if Dir.exist?(package_dir)
      FileUtils.mkdir_p(package_dir)

      copy_roles
      generate_files
    end

    def environment
      {
          'ANSIBLE_HOST_KEY_CHECKING' => 'False',
          'ANSIBLE_LOG_PATH' => "#{@ansible_package_dir}/ansible.log",
          'ANSIBLE_RETRY_FILES_ENABLED' => "False",
          'ANSIBLE_ASK_SUDO_PASS' => "False",
          'ANSIBLE_CONFIG' => @ansible_package_dir
      }
    end

    def command
      "sshpass -p #{@vault_password} ansible-playbook '#{@playbook_file_info[:output_path]}' -i '#{@hosts_file_info[:output_path]}' "\
      "-e '@#{@vault_file_info[:output_path]}' -e '@#{@vars_file_info[:output_path]}' --ask-vault-pass"
    end


    private

    def copy_roles
      FileUtils.cp_r(ROLES_SOURCE, @ansible_package_dir)
    end

    def init_file_info(deployment)
      default_binding = ::FusorAnsible::TemplateBindings::Default.new(deployment).get_binding

      @vars_file_info = get_file_info('vars.yml.erb', 'vars.yml', ::FusorAnsible::TemplateBindings::Vars.new(deployment).get_binding)
      @vault_file_info = get_file_info('vault.yml.erb', 'vault.yml', default_binding, true)
      @hosts_file_info = get_file_info('hosts.erb', 'hosts', ::FusorAnsible::TemplateBindings::Hosts.new(deployment).get_binding)
      @playbook_file_info = get_file_info('deploy.yml.erb', 'deploy.yml', default_binding)
      @files = [@vars_file_info, @vault_file_info, @hosts_file_info, @playbook_file_info]

      @files << get_file_info('satellite_prep.yml.erb', 'satellite_prep.yml', default_binding)

      # if deployment.deploy_ceph
      #   @files << get_file_info('deploy_ceph.yml.erb', 'deploy_ceph.yml', default_binding)
      # end

      if deployment.deploy_rhev
        @files << get_file_info('rhv_pre.yml.erb', 'rhv_pre.yml', default_binding)
        if deployment.rhev_is_self_hosted
          @files << get_file_info('rhv_deploy_self_hosted.yml.erb', 'rhv_deploy.yml', default_binding)
        else
          @files << get_file_info('rhv_deploy_engine_hypervisor.yml.erb', 'rhv_deploy.yml', default_binding)
        end
        @files << get_file_info('rhv_post.yml.erb', 'rhv_post.yml', default_binding)
      end

      if deployment.deploy_openstack
        @files << get_file_info('openstack_deploy.yml.erb', 'openstack_deploy.yml', default_binding)
      end

      if deployment.deploy_openshift
        @files << get_file_info('openshift_deploy.yml.erb', 'openshift_deploy.yml', default_binding)
      end

      if deployment.deploy_rhev && deployment.deploy_cfme
        @files << get_file_info('cfme_rhv_deploy.yml.erb', 'cfme_rhv_deploy.yml', default_binding)
      end

      if deployment.deploy_openstack && deployment.deploy_cfme
        @files << get_file_info('cfme_openstack_deploy.yml.erb', 'cfme_openstack_deploy.yml', default_binding)
      end
    end
    
    def get_file_info(input_filename, output_filename, binding, encrypted = false)
      file_info = {
          template_path: "#{Rails.root}/app/models/fusor_ansible/templates/#{input_filename}",
          output_path: File.join(@ansible_package_dir, "#{output_filename}"),
          binding: binding
      }
      file_info[:encryption_password] = @vault_password if encrypted
      file_info
    end

    def generate_files
      @files.each do |file_info|
        renderer = ERB.new(File.read(file_info[:template_path]), nil, '%<>')
        output = renderer.result(file_info[:binding])

        file = File.open(file_info[:output_path], 'w') { |file| file.write(output) }
        `sshpass -p #{file_info[:encryption_password]} ansible-vault encrypt #{file_info[:output_path]}` if file_info[:encryption_password]
        file
      end
    end
  end
end