module App
  def self.load_config_from_yaml_file(path)
    configs = YAML.load File.read(path)

    config, env_setting = *configs.values_at("default", Rails.env)
    (config || {}).deep_merge(env_setting || {})
  rescue Errno::ENOENT
    W "Missing config file: #{path}"
    {}
  end
  
  def self.config
    @config ||= begin
      config = load_config_from_yaml_file("config/app.defaults.yml")
      local_config = load_config_from_yaml_file("config/app.local.yml")

      config.deep_merge local_config
    end
  end
end
