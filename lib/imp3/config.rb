require "singleton"

class IMP3::Config
  include Singleton

  CONFIG_FILE = File.join(IMP3::APP_DIR, "config.yml")

  def initialize
    @data = {}

    if File.exist?(CONFIG_FILE)
      begin
        @data = YAML.load_file(CONFIG_FILE)
      rescue
        raise "Unable to read config file #{CONFIG_FILE}"
      end
    end
  end

  def ignore_genres
    @data[:ignore_genres] ||= []
    @data[:ignore_genres]
  end

  def strip_words
    @data[:strip_words] ||= %w(the a of in)
    @data[:strip_words]
  end

  def save
    File.new(CONFIG_FILE, "w+").write(@data.to_yaml)
  end
end