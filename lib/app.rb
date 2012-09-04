module App
  def self.configs
    @configs ||= YAML.load File.read("config/app.yml")
  end
  
  def self.config
    @config ||= configs["default"]
  end
end
