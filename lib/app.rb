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

      config = config.deep_merge(local_config)
      config.extend Structly
    end
  end
  
  module Structly
    def fetch(key)
      value = super(key)
      value.extend(Structly) if value.is_a?(Hash)
      value
    end
    
    def method_missing(sym)
      if (key = sym.to_s) =~ /(.*)!$/
        key, super_if_missing = $1, true
      end
      
      return fetch(key) if key?(key)
      return fetch(key.to_sym) if key?(key.to_sym)
      
      super if super_if_missing
    end
  end
end
