require 'singleton'
require 'yaml'

# AppResources[key] でアクセス可能
class AppResources
  include Singleton
  
  # resource file
  RESOURCE_FILE = "#{RAILS_ROOT}/config/app.yml"  

  # usage: AppResources["key_name"]
  def self.[](key)
    self.instance[key]
  end
  
  # リソース情報を取得する
  # usage: AppResources.instance["key_name"]
  def [](key)
    load if @app_resources == nil
    @app_resources[key]
  end
  
  # リソース情報をロードする
  # usage: AppResources.instance.load
  def load
    @app_resources = YAML.load_file(RESOURCE_FILE)[RAILS_ENV].with_indifferent_access
  end
  
end