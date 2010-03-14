require 'cgi'
require 'open-uri'
require 'nokogiri'
require 'terminal-table/import'
require 'active_support'
require 'friendly_id/slug_string'
require 'rbosa'
require 'pp'
require 'commander/user_interaction'
require 'singleton'
require 'lib/imp3/config'
require 'lib/imp3/cache'
require 'lib/imp3/commands.rb'

OSA.utf8_strings = true

class IMP3::CLI
  include Singleton
  attr_reader :config, :cache
  attr_accessor :source_origin

  def initialize
    @source_origin = :library
    @config = IMP3::Config.instance
    @cache = IMP3::Cache.instance
  end

  include IMP3::Commands

  protected

  def itunes
    OSA.app('iTunes') rescue raise "Can't locate iTunes! It's installed?"
  end

  def tracks
    case source_origin
      when :library
        @library ||= itunes.sources.find {|s| s.kind == OSA::ITunes::ESRC::LIBRARY }.playlists[0] rescue raise "Unable to contact iTunes, please make sure it is open."
        @library.tracks 
      when :selection
        itunes.selection
      else
        raise "Invalid source origin: #{source_origin}"
    end
  end

  def artists
    @artists ||= tracks.map{|t| t.artist}.uniq.sort
  end

  def create_app_dir
    Dir.mkdir(APP_DIR) unless File.directory?(APP_DIR) rescue "Unable to create application directory: #{APP_DIR}"
  end

  def summary(opts = {})
    puts
    puts "#{opts[:artist] || artists.size} artists."
    puts "#{opts[:tracks] || tracks.size} tracks."
    puts "#{opts[:tracks_tagged] || 0} tracks tagged."
    puts "#{opts[:requests] || 0} requests."
    puts "#{opts[:errors] || 0} errors."
  end
end

class String
  def strip_meaningless_words
    string = self
    IMP3::Config.instance.strip_words.each do |w|
      string = string.gsub(/\b#{w}\b/i, '')
    end
    string.strip
  end

  def normalized_without_words
    self.strip_meaningless_words.normalize
  end

  def normalize
    FriendlyId::SlugString.new(self).normalize!.approximate_ascii!.to_s
  end
end

def progress_bar arr, options = {:format => ":percent_complete% |:progress_bar| :title"}, &block
  bar = ProgressBar.new arr.size, options
  bar.show
  arr.each { |v| yield(v, bar) }
end

class Commander::UI::ProgressBar
  def refresh(tokens)
    @tokens.merge! tokens if tokens.is_a? Hash
    show
  end
end