module IMP3::Commands
  require "lib/imp3/commands/genres"
  require "lib/imp3/commands/artists"

  include IMP3::Commands::Artists
  include IMP3::Commands::Genres
end

