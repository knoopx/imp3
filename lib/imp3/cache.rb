require "singleton"

class IMP3::Cache
  include Singleton

  CACHE_FILE = File.join(IMP3::APP_DIR, "cache.yml")

  def initialize
    @data = {}

    if File.exist?(CACHE_FILE)
      begin
        @data = YAML.load_file(CACHE_FILE)
      rescue
        raise "Unable to read cache file #{CACHE_FILE}"
      end
    end
  end

  def artist_genres
    @data[:artist_genres] ||= {}
    @data[:artist_genres]
  end

  def save
    File.new(CACHE_FILE, "w+").write(@data.to_yaml)
  end
end