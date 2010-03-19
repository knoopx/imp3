module IMP3::Commands::Artists
  def artists_misspelled_command
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
          artist_name = choose("What is the correct artist name for #{track.artist}?", *(artist_choices[normalized_artist_name] << :"(Skip)"))
          artist_names[normalized_artist_name] = artist_name
        else
          artist_names[normalized_artist_name] = track.artist
        end
      end

      next if artist_names[normalized_artist_name].eql?(:"(Skip)")

      unless track.artist.eql?(artist_names[normalized_artist_name])
        tagged += 1
        puts "Tagging track #{track.object_id} with artist name '#{artist_names[normalized_artist_name]}'"
        begin
          track.artist = artist_names[normalized_artist_name]
        rescue => e
          errors += 1
          puts "Error: #{e}"
        end

      end
    end

    summary :tracks_tagged => tagged
  end
end