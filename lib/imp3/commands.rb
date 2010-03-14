module IMP3::Commands
  require "imp3/commands/genres"
  require "imp3/commands/artists"

  include IMP3::Commands::Artists
  include IMP3::Commands::Genres
end

