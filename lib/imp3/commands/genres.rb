module IMP3::Commands::Genres
  def genres_fetch_command (options)
    if options.flush_cache
      cache.artist_genres.clear
      puts "Flushing artist genres cache."
    end

    tagged, requests, errors = 0, 0, 0

    progress_bar tracks do |track, bar|
      normalized_artist_name = track.artist.normalize
      begin
        unless cache.artist_genres.has_key?(normalized_artist_name)
          raise "Track has no artist name set" if track.artist.empty?
          requests += 1
          bar.refresh(:title => "Quering last.fm for '#{track.artist}'")
          response = Nokogiri(open("http://ws.audioscrobbler.com/1.0/artist/#{URI.escape(CGI.escape(track.artist))}/toptags.xml"))
          cache.artist_genres[normalized_artist_name] = response.search("//toptags/tag/name").map{|t| t.text.normalize }.uniq
          cache.save
        end
      rescue => e
        errors += 1
        bar.refresh(:title => "Error: #{e}")
        cache.artist_genres[normalized_artist_name] = nil
      end

      if (cache.artist_genres.has_key?(normalized_artist_name) and not cache.artist_genres[normalized_artist_name].nil?)
        genre = (cache.artist_genres[normalized_artist_name] - config.ignore_genres).first

        if track.genre.eql?(genre)
          bar.refresh(:title => "Skipping track #{track.object_id}. Genre is already '#{genre}'")
        else
          bar.refresh(:title => "Tagging track #{track.object_id} with genre '#{genre}'")
          tagged += 1
          begin
            track.genre = genre
          rescue => e
            errors += 1
            bar.refresh(:title => "Error: #{e}")
          end
        end
      end

      bar.increment
    end
    summary(:tracks_tagged => tagged, :requests => requests, :errors => errors)
  end

  def genres_fetch_cache_command(options)
    genres = {}
    (cache.artist_genres.map{|artist, tags| tags}.flatten - config.ignore_genres).each do |tag|
      genres[tag] ||= 0
      genres[tag] += 1
    end

    genres = genres.sort{|a, b| b[1] <=> a[1]}

    if genres.any?
      genre_table = table do |t|
        t.headings = 'Genre', 'Artist count'
        genres.to_a[0..[genres.size, options.limit].min].each do |g, c|
          t << [g, c]
        end
      end
      puts genre_table
    else
      puts "No genres cached yet."
    end

    summary
  end

  def genres_list_command
    genres = {}
    tracks.each do |track|
      genres[track.genre] ||= 0
      genres[track.genre] += 1
    end

    genre_table = table do |t|
      t.headings = 'Genre', 'Tracks'
      genres.sort{|a, b| b[1] <=> a[1]}.each do |g, c|
        t << [g, c]
      end
    end

    puts genre_table
    summary
  end

  def genres_ignore_add_command (genre)
    raise "Please specify a genre" unless genre
    genre.strip!
    config.ignore_genres << genre unless config.ignore_genres.include?(genre)
    config.save
    puts "Genre '#{genre}' added to ignore list"
  end

  def genres_ignore_del_command (genre)
    raise "Please specify a genre" unless genre
    genre.strip!
    config.ignore_genres.delete(genre) if config.ignore_genres.include?(genre)
    config.save
    puts "Genre '#{genre}' deleted from ignore list"
  end

  def genres_ignore_list_command
    if config.ignore_genres.any?
      genre_table = table do |t|
        t.headings = 'Genre'
        config.ignore_genres.each do |g|
          t << [g]
        end
      end
      puts genre_table
    else
      puts "No ignored genres."
    end
  end
end