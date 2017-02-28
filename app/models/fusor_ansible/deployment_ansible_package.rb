require 'erb'


module FusorAnsible
  class DeploymentAnsiblePackage
    ROLES_SOURCE = '/usr/share/fusor-ansible/roles'

    attr_accessor :vault_password
    attr_reader :ansible_package_dir, :files

    def initialize(deployment, vault_password = nil)
      @satellite_fqdn = Rails.configuration.external_apis['satellite_fqdn']
      @satellite_domain = Rails.configuration.external_apis['satellite_domain']
      @satellite_subnet = Rails.configuration.external_apis['satellite_subnet']
      @satellite_username = Rails.configuration.external_apis['satellite_api_username']
      @satellite_password = Rails.configuration.external_apis['satellite_api_password']


      @deployment = deployment
      @ansible_package_dir = "#{Rails.root}/tmp/ansible-ovirt/#{deployment.label}_#{deployment.id}_#{deployment.run_number}"
      @vault_password = vault_password || SecureRandom.urlsafe_base64

      @vars_file_info = {
          template_path:  "#{Rails.root}/app/models/fusor_ansible/templates/vars.yml.erb",
          output_path: File.join(@ansible_package_dir, 'vars.yml')
      }

      @vault_file_info = {
          template_path:  "#{Rails.root}/app/models/fusor_ansible/templates/vault.yml.erb",
          output_path: File.join(@ansible_package_dir, 'vault.yml'),
          encryption_password: @vault_password
      }

      @hosts_file_info = {
          template_path:  "#{Rails.root}/app/models/fusor_ansible/templates/hosts.erb",
          output_path: File.join(@ansible_package_dir, 'hosts')
      }

      @playbook_file_info = {
          template_path:  "#{Rails.root}/app/models/fusor_ansible/templates/deploy.yml.erb",
          output_path: File.join(@ansible_package_dir, 'deploy.yml')
      }

      # TODO extra files will be added as required by the deployment options
      @files = [@vars_file_info, @vault_file_info, @hosts_file_info, @playbook_file_info]
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

    def generate_files
      @files.each {|file_info| generate_from_erb(file_info[:template_path], file_info[:output_path], file_info[:encryption_password] )}
    end

    def generate_from_erb(template_path, output_path, encryption_password)
      renderer = ERB.new(File.read(template_path))
      output = renderer.result(binding)

      file = File.open(output_path, 'w') { |file| file.write(output) }
      `sshpass -p #{encryption_password} ansible-vault encrypt #{output_path}` if encryption_password
      file
    end
  end
end