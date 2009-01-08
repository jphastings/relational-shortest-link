# Todo: Change ID system so it used 'mbid's instead of Artist/Track names, to avoid confusion
# Though this will create large overhead, as a hash of mbid -> displayname would need to be kept...
# Todo: Fix Tracks! Its not finding paths when they're there!

require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'uri'

class Lastfm
  attr_accessor :threshold
  attr_reader :description
  
  @@apikey = "95645efa7aa5f624aa1f1f20823027ac"
    
  def threshold=(threshold)
    if threshold > 0 and threshold < 100
      @threshold = threshold
      setdesc
    else
      raise "#{threshold} is must be a number between 0 and 100"
    end
  end
  
  def setdesc
    @description = "Last.fm #{@type} (#{@threshold}% threshold)"
    @cacheroot = "lastfm.#{@type}.thresh-#{@threshold}"
  end
  
  def canreverselookup?
    false
  end
  
  def directional?
    true
  end
  
  def links_from(id)
    links = []
    
    cachename = "cache/#{@cacheroot}."+URI.escape(id).gsub(/\//,"_")+".links.txt"
    if File.exists?(cachename)
      links = open(cachename).readlines.collect{|link| link.strip}
      puts " Cached  '"+displayname(id)+"' >>> "+links.length.to_s+" links"
      return links
    end
    
    print "Grabbing '"+displayname(id)+"' ... "
    begin
      page = Hpricot(retrieve(makeurl(id,"getsimilar")))
    rescue
      # Dodgey ID. Don't bother throwing an error, incase it was an invalid link mid-flow
      puts "malformed ID?"
      return links
    end
    
    links = distil(page)
    puts links.length.to_s+" links"
        
    open(cachename,"w").print(links.join("\n"))
    return links
  end
  
  def details(id)
    
  end
end

class Lastfm_artists < Lastfm
  
  Opts = [
    {"name"=>"Threshold","question"=>"What threshold percentage do you want to use?","default"=>90}
  ]
  
  Defaults = ["Muse","The Strokes"]
  
  def initialize (threshold = 90)
    @type = "artists"
    self.threshold = threshold
  end
  
  def makeID(string)
    pre = makeurl(URI.encode(string),"getinfo")
    begin
      page = Hpricot(retrieve(pre))
    rescue
      raise "There is no artist on #{@description} called '#{id}'"
    end
    ((page/:artist)[0]/:name)[0].inner_text
  end
  
  def makeurl(id,style)
    "http://ws.audioscrobbler.com/2.0/?method=artist.#{style}&api_key=#{@@apikey}&artist="+URI.escape(id).gsub(/&/,"%26")
  end
  
  def distil(chunk)
    (chunk/:artist).collect {|artist| (artist/:name).inner_text if (artist/:match).inner_text.to_i > @threshold}.compact
  end
  
  def displayname(id)
    URI.unescape(id)
  end
  
  def self.displayname(id)
    URI.unescape(id)
  end
end

class Lastfm_tracks < Lastfm
  
  Opts = [
    {"name"=>"Threshold","question"=>"What threshold percentage do you want to use?","default"=>4}
  ]
  
  Defaults = ["Bohemian Rhapsody (Queen)","Sweet Home Alabama (Lynyrd Skynyrd)"]
  
  def initialize (threshold = 12)
    @type = "tracks"
    self.threshold = threshold
  end
  
  def makeID(string)
    if string =~ /(.+) \((.+)\)/
      track, artist = $1,$2 
    else
      raise "Malformed track id. Should be 'Track (Artist)'"
    end
    
    url = makeurl("#{artist}|#{track}","getinfo")
    begin
      page = Hpricot(retrieve(url))
    rescue
      raise "There is no track on #{@description} called '#{track}' by '#{artist}' (#{url})"
    end
    artist = ((page/:artist)[0]/:name)[0].inner_text
    track = ((page/:track)[0]/:name)[0].inner_text
    "#{track}|#{artist}"
  end
  
  def makeurl(id,style)
    track, artist = id.split("|")
    "http://ws.audioscrobbler.com/2.0/?method=track.#{style}&api_key=#{@@apikey}&artist="+URI.escape(artist).gsub(/&/,"%26")+"&track="+URI.escape(track).gsub(/&/,"%26")
  end
  
  def distil(chunk)
    (chunk/:track).collect {|track| (track/:name).collect {|name| name.inner_text}.join("|") if (track/:match).inner_text.to_i > @threshold}.compact
  end
  
  def displayname(id)
    track, artist = id.split("|")
    
    "#{track} (#{artist})"
  end
  
  def self.displayname(id)
    track, artist = id.split("|")
    
    "#{track} (#{artist})"
  end
end