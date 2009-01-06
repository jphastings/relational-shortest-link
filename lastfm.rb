class Lastfm
  attr_accessor :type,:threshold
  attr_reader :description
  
  @@apikey = "95645efa7aa5f624aa1f1f20823027ac"
  
  def initialize
    require 'rubygems'
    require 'hpricot'
    require 'open-uri'
    require 'uri'
    
    @threshold = 90
  end
    
  def threshold=(threshold)
    if threshold > 0 and threshold < 100
      @threshold = threshold
      setdesc
    else
      raise "#{threshold} is not a number between 0 and 100"
    end
  end
  
  def setdesc
    @description = "Last.fm #{@type} (#{@threshold}% threshold)"
  end
  
  def canreverselookup?
    false
  end
  
  def directional?
    true
  end
  
  def links(id)
   grablinks(makeurl(id,"getsimilar"),id)
  end
  
  def grablinks(url,id)
    links = []
    
    begin
      page = Hpricot(open(url))
    rescue
      return links
    end
    
    raw = distil(page)
        
    puts "Grabbing '"+URI.unescape(id)+"' ... "+raw.length.to_s+" links"
    raw.each do |href|
      begin
        links.push(URI.unescape($1))
      rescue
        
      end
    end
  end
  
  def details(id)
    
  end
end

class Lastfm_artists < Lastfm
  def initialize
    super
    @type = "artists"
    setdesc
  end
  
  def makeID(id)
    pre = makeurl(id,"getinfo")
    begin
      ((Hpricot(open(pre))/:artist)[0]/:name)[0].inner_text
    rescue
      raise "There is no artist on #{@description} called '#{id}'"
    end
  end
  
  def makeurl(id,style)
    "http://ws.audioscrobbler.com/2.0/?method=artist.#{style}&api_key=#{@@apikey}&artist="+URI.escape(id)
  end
  
  def distil(chunk)
    (chunk/:artist).collect {|artist| (artist/:name).inner_text if (artist/:match).inner_text.to_i > @threshold}.compact
  end
end

class Lastfm_tracks < Lastfm
  def initialize
    super
    @type = "tracks"
    setdesc
  end
  
  def makeurl(id)
    pre = makeurl(id,"getinfo")
    begin
      page = Hpricot(open(pre))
      artist = ((page/:artist)[0]/:name)[0].inner_text
      track = ((page/:track)[0]/:name)[0].inner_text
      "#{track}|#{artist}"
    rescue
      raise "There is no track on #{@description} called '#{id}'"
    end
  end
  
  def makeURL(id,style)
    track, artist = id.split("|")
     "http://ws.audioscrobbler.com/2.0/?method=track.#{style}&api_key=#{@@apikey}&artist="+URI.escape(artist)+"&track="+URI.escape(track)
  end
  
  def distil(chunk)
    (chunk/:track).collect {|track| (track/:name).collect {|name| name.inner_text}.join("|") if (track/:match).inner_text.to_i > @threshold}.compact
  end
end