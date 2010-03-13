require 'cgi'
require 'open-uri'
require 'nokogiri'
require 'terminal-table/import'
require 'active_support'
require 'friendly_id/slug_string'
require 'rbosa'
require 'pp'
require 'commander/user_interaction'

OSA.utf8_strings = true

class IMP3::CLI
  def tag_genres ()
    artist_genres = {}
    tagged, requests, errors = 0, 0, 0

    progress_bar tracks do |track, bar|
      normalized_artist_name = track.artist.normalize

      begin
        unless artist_genres.has_key?(normalized_artist_name)
          requests += 1
          tags = Nokogiri(open("http://ws.audioscrobbler.com/1.0/artist/#{URI.escape(CGI.escape(track.artist))}/toptags.xml")).search("//toptags/tag/name").map{|t| t.text.normalize }.uniq
          bar.refresh(:title => "Quering last.fm for #{track.artist}")
          artist_genres[normalized_artist_name] = tags.first
        end
      rescue => e
        errors += 1
        bar.refresh(:title => e)
        artist_genres[normalized_artist_name] = nil
      end

      if (artist_genres.has_key?(normalized_artist_name) and not artist_genres[normalized_artist_name].nil?)
        tagged += 1
        bar.increment(:title => "Tagging track #{track.persistent_id} with genre '#{artist_genres[normalized_artist_name]}'")
        track.genre = ""
        track.genre = artist_genres[normalized_artist_name].normalize
      end

    end
    summary(:tracks_tagged => tagged, :requests => requests, :errors => errors)
  end

  def list_genres
    genres = {}
    tracks.each do |track|
      genres[track.genre] ||= 0
      genres[track.genre] += 1
    end

    genre_table = table do |t|
      t.headings = 'Genre', 'Tracks'
      genres.sort{|a,b| b[1] <=> a[1]}.each do |g, c|
        t << [g, c]
      end
    end

    puts genre_table
    summary
  end

  def fix_misspelled_artist_names
    artist_choices = {}
    tagged = 0
    
    progress_bar artists, :complete_message => "Misspelled artist name scan complete." do |artist, bar|
      bar.increment :title => "Scanning artist '#{artist}'"
      normalized_artist_name = artist.normalized_without_words
      artist_choices[normalized_artist_name] ||= []
      artist_choices[normalized_artist_name] << artist.strip unless artist_choices[normalized_artist_name].include?(artist)
    end

    artist_names = {}
    tracks.each do |track|
      normalized_artist_name = track.artist.normalized_without_words
      unless artist_names.has_key?(normalized_artist_name)
        if artist_choices[normalized_artist_name] && artist_choices[normalized_artist_name].size > 1
          puts
          artist_name = choose("What is the correct artist name for #{track.artist}", *(artist_choices[normalized_artist_name] << :"(Skip)"))
          artist_names[normalized_artist_name] = artist_name
        else
          artist_names[normalized_artist_name] = track.artist
        end
      end

      unless artist_names[normalized_artist_name].eql?(:"(Skip)") or track.artist.eql?(artist_names[normalized_artist_name])
        tagged += 1
        puts "Tagging track #{track.persistent_id} with artist name '#{artist_names[normalized_artist_name]}'"
        track.artist = ""
        track.artist = artist_names[normalized_artist_name]
      end
    end

    summary :tracks_tagged => tagged
  end

  protected

  def itunes
    @itunes ||= OSA.app('iTunes')
  end

  def library
    @library ||= itunes.sources.find {|s| s.kind == OSA::ITunes::ESRC::LIBRARY }.playlists[0]
  end

  def tracks
    @tracks ||= library.tracks
  end

  def artists
    @artists ||= tracks.map{|t| t.artist}.uniq.sort
  end

  def summary(opts = {})
    puts
    puts "#{opts[:artist] || tracks.map{|t| t.artist}.uniq.size} artists."
    puts "#{opts[:tracks] || tracks.size} tracks."
    puts "#{opts[:tracks_tagged] || 0} tracks tagged."
    puts "#{opts[:requests] || 0} requests."
    puts "#{opts[:errors] || 0} errors."
  end
end

class String
  STRIP_WORDS = %w(the a of in)

  def strip_meaningless_words
    string = self
    STRIP_WORDS.each do |w|
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