# Compiling the Gem
# gem build rubytorrent-allspice.gemspec
# [sudo] gem install ./rubytorrent-allspice-0.3.1.gem
#
# gem push rubytorrent-allspice-0.3.1.gem
# gem list -r rubytorrent-allspice
# gem install rubytorrent-allspice

$:.push File.expand_path("../lib", __FILE__)
require "rubytorrent-allspice/version"

Gem::Specification.new do |s|
  s.name = "rubytorrent-allspice"
  s.version = RubyTorrent::VERSION.dup
  s.platform = Gem::Platform::RUBY
  s.summary = "Based on RubyTorrent 0.3.0 by William Morgan, an update to work with Ruby 1.9.2"
  s.email = "remosm@gmail.com"
  s.homepage = "https://github.com/remomueller"
  s.authors = ["Remo Mueller"]
  
  s.description = "Based on RubyTorrent 0.3.0 gem by William Morgan, this gem makes RubyTorrent compatible with Ruby 1.9.2.
  Changes are also made to rtpeer.rb and rtpeer-ncurses.rb to allow them to be transformed into
  Windows executables using ocra with an embedded .torrent file.
  
  Changes to files may cause incompatibilities with the original RubyTorrent!"
  
  s.files = ["README","dump-metainfo.rb","rtpeer-ncurses.rb","dump-peers.rb","make-metainfo.rb",
             "rtpeer.rb","lib/rubytorrent-allspice.rb","lib/rubytorrent-allspice/bencoding.rb",
             "lib/rubytorrent-allspice/controller.rb","lib/rubytorrent-allspice/message.rb",
             "lib/rubytorrent-allspice/metainfo.rb","lib/rubytorrent-allspice/package.rb",
             "lib/rubytorrent-allspice/peer.rb","lib/rubytorrent-allspice/server.rb",
             "lib/rubytorrent-allspice/tracker.rb","lib/rubytorrent-allspice/typedstruct.rb",
             "lib/rubytorrent-allspice/util.rb","rtpeercomplete.rb","rtpeercursescomplete.rb",
             "lib/rubytorrent-allspice/generate.rb"]
end