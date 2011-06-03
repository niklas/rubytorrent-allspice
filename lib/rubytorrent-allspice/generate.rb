# coding: UTF-8

## generate.rb -- Allows easier creation of torrent file, based off of make-metainfo.rb
##   target_file:   target .torrent file name
##   source_files:  array of file or folder locations
##   trackers:      array of at least one URI (String) showing the tracker locations
##   piece_size:    [64, 128, 256, 512, 1024, 2048, 4096] piece size of torrent
##   comments:      String of comments to add to torrent information

## Example:
##   RubyTorrent::Generate.new('./new_torrent_file.torrent', ["/path/to/file", "/path/to/folder/"], ['http://127.0.0.1:6969/announce'], 256, 'My Awesome Torrent')


require 'digest/sha1'

class Numeric
  def to_size_s
    if self < 1024
      "#{self.round}b"
    elsif self < 1024**2
      "#{(self / 1024.0).round}kb"
    elsif self < 1024**3
      "#{(self / (1024.0**2)).round}mb"
    else
      "#{(self / (1024.0**3)).round}gb"
    end
  end
end

module RubyTorrent
  class GenerateError < StandardError; end
  class Generate
    def initialize(target_file, source_files, trackers, piece_size = 256, comments = '')
      @target_file = target_file
      @source_files = source_files
      @trackers = trackers
      @piece_size = piece_size
      @comments = comments
      
      raise RubyTorrent::GenerateError, "no target file specified." if target_file.to_s == ''
      raise RubyTorrent::GenerateError, "no source files found." if source_files.empty?
      raise RubyTorrent::GenerateError, "need at least one tracker." if trackers.size == 0
      raise RubyTorrent::GenerateError, "piece size not one of: [64, 128, 256, 512, 1024, 2048, 4096]" unless [64, 128, 256, 512, 1024, 2048, 4096].include?(piece_size)
      raise RubyTorrent::GenerateError, "specify a target_file that does not exist.  No overwriting allowed." if File.exists?(target_file)

      # puts "Scanning..."
      files = source_files.map { |f| find_files f }.flatten
      single = files.length == 1

      # puts "Building #{(single ? 'single' : 'multi')}-file .torrent for #{files.length} file#{(single ? '' : 's')}."

      mi = RubyTorrent::MetaInfo.new
      mii = RubyTorrent::MetaInfoInfo.new

      maybe_name = if single
        File.basename(source_files.first)
      else
        (File.directory?(source_files.first) ? File.basename(source_files.first) : File.basename(source_files.first))
      end
      
      # puts
      # print %{Default output file/directory name (enter for "#{maybe_name}"): }
      name = "" # $stdin.gets.chomp
      mii.name = (name == "" ? maybe_name : name)
      # puts %{We'll use "#{mii.name}".}

      # puts
      # puts "Measuring..."
      length = nil
      if single
        length = mii.length = files.inject(0) { |s, f| s + File.size(f) }
      else
        mii.files = []
        length = files.inject(0) do |s, f|
          miif = RubyTorrent::MetaInfoInfoFile.new
          miif.length = File.size f
          miif.path = f.split File::SEPARATOR
          miif.path = miif.path[1, miif.path.length - 1] if miif.path[0] == mii.name
          mii.files << miif
          s + miif.length
        end
      end

      # puts "\n\nThe file is #{length.to_size_s}. What piece size would you like? A smaller piece size\nwill result in a larger .torrent file; a larger piece size may cause\ntransfer inefficiency. Common sizes are 256, 512, and 1024kb.\n\nHint: for this .torrent,"

      size = nil
      [64, 128, 256, 512, 1024, 2048, 4096].each do |size|
        num_pieces = (length.to_f / size / 1024.0).ceil
        tsize = num_pieces.to_f * 20.0 + 100
        # puts "  - piece size of #{size}kb => #{num_pieces} pieces and .torrent size of approx. #{tsize.to_size_s}."
        break if tsize < 10240
      end

      # maybe_plen = [size, 256].min
      maybe_plen = (size == nil) ? 256 : [size, 256].min

      # begin
      #   print "Piece size in kb (enter for #{maybe_plen}k): "
      #   plen = $stdin.gets.chomp
      # end while plen !~ /^\d*$/
      # 
      # plen = (plen == "" ? maybe_plen : plen.to_i)
      plen = piece_size

      mii.piece_length = plen * 1024
      num_pieces = (length.to_f / mii.piece_length.to_f).ceil
      # puts "Using piece size of #{plen}kb => .torrent size of approx. #{(num_pieces * 20.0).to_size_s}."

      # print "Calculating #{num_pieces} piece SHA1s... " ; $stdout.flush

      mii.pieces = ""
      i = 0
      read_pieces(files, mii.piece_length) do |piece|
        mii.pieces += Digest::SHA1.digest(piece)
        i += 1
        if (i % 100) == 0
          # print "#{(i.to_f / num_pieces * 100.0).round}%... "; $stdout.flush
        end
      end
      # puts "done"

      mi.info = mii
      # puts <<EOS
      # 
      # Enter the tracker URL or URLs that will be hosting the .torrent
      # file. These are typically of the form:
      # 
      #   http://tracker.example.com:6969/announce
      # 
      # Multiple trackers may be partitioned into tiers; clients will try all
      # servers (in random order) from an earlier tier before trying those of
      # a later tier. See http://home.elp.rr.com/tur/multitracker-spec.txt
      # for details.
      # 
      # Enter the tracker URL(s) now. Separate multiple tracker URLs on the
      # same tier with spaces. Enter a blank line when you're done.
      # 
      # (Note that if you have multiple trackers, some clients may only use
      # the first one, so that should be the one capable of handling the most
      # traffic.)
      # EOS

      # tier = 0
      # trackers = []
      # begin
      #   print "Tier #{tier} tracker(s): "
      #   these = $stdin.gets.chomp.split(/\s+/)
      #   trackers.push these unless these.length == 0
      #   tier += 1 unless these.length == 0
      # end while (these.length != 0) || (tier == 0)

      new_trackers = []
      trackers.each do |tracker|
        new_trackers.push tracker.split(/\s+/)
      end

      mi.announce = URI.parse(new_trackers[0][0])
      mi.announce_list = new_trackers.map do |tier|
        tier.map { |x| URI.parse(x) }
      end unless (new_trackers.length == 1) && (new_trackers[0].length == 1)

      # puts <<EOS
      # 
      # Enter any comments. No one will probably ever see these. End with a blank line.
      # EOS
      # comm = ""
      # while true
      #   s = $stdin.gets.chomp
      #   break if s == ""
      #   comm += s + "\n"
      # end
      # mi.comment = comm.chomp unless comm == ""
      mi.comment = comments

      mi.created_by = "RubyTorrent::Generate (http://rubytorrent.rubyforge.org) - rubytorrent-allspice"
      mi.creation_date = Time.now

      # maybe_name = "#{mii.name}.torrent"
      # begin
      #   print "Output filename (enter for #{maybe_name}): "
      #   name = $stdin.gets.chomp
      # end while name.length == ""

      name = target_file  #(name == "" ? maybe_name : name)
      File.open(name, "w") do |f|
        # puts "name: #{name} #{mi.inspect}\n\n#{mi.to_bencoding}\n\n#{mi.class.name}\n\n"
        f.write mi.to_bencoding
      end

      puts "Succesfully created #{name}"


    end    
    
    def find_files(f)
      if FileTest.directory? f
        Dir.new(f).entries.map { |x| find_files(File.join(f, x)) unless x =~ /^\.[\.\/]*$/}.compact
      else
        f
      end
    end

    def read_pieces(files, length)
      buf = ""
      files.each do |f|
        File.open(f) do |fh|
          begin
            read = fh.read(length - buf.length)
            if (buf.length + read.length) == length
              yield(buf + read)
              buf = ""
            else
              buf += read
            end
          end until fh.eof?
        end
      end

      yield buf
    end
    
  end
end