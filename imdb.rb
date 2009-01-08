require 'rubygems'
require 'hpricot'
require 'library'
require 'uri'

# id is an array ["tt0000000","Name","Film|Actor|Video Game|TV"]

class IMDB
  attr_accessor :region,:othertitles
  attr_reader :description

  Regions = {"UK"=>"uk.imdb.com","US"=>"imdb.com"}
  
  Opts = [
    {"name"=>"IMDB Region","question"=>"Which IMDB region would you like to use?","default"=>"UK"},
    {"name"=>"Films Only","question"=>"Would you like to include TV shows and Video Games?","default"=>"n"}
  ]
  
  Defaults = [["tt1013753","Milk","F"],["nm0000102","Kevin Bacon","A"]]

  def initialize(region = "UK",othertitles = true)
    
    self.othertitles = othertitles
    self.region = region
  end
  
  def region=(region)
    if not Regions.include? region
      raise "Sorry, #{region} isn't a valid region - use: "+Regions.keys.join(", ")
    end
    @region = region
    setdesc
  end
  
  def othertitles=(othertitles)
    if not [true,false].include? othertitles
      raise "Sorry, please specify true or false for whether to allow TV shows and video games"
    end
    @othertitles = othertitles
    setdesc
  end
  
  def setdesc
    @description = "IMDB (#{@region}; "+((@allowtv) ? "Allow" : "No")+" TV Shows)"
    @cacheroot = "imdb.#{@region}"
  end
  
  def directional?
    false
  end
  
  def links_to(id)
    links_from(id)
  end
  
  def links_from(id)
    links = []
    
    cachename = "cache/#{@cacheroot}.#{id[0]}.links.txt"
    if File.exists?(cachename)
      links = open(cachename).readlines.collect{|link| [$1,$2,$3] if link.strip =~ /^((?:nm|tt)[0-9]+)\|(.+)\|(A|F|VG|TV)$/}
      if not (@allowtv or id[2])
        links = removeTV(links)
      end
      puts " Cached  '"+displayname(id)+"' ... "+links.length.to_s+" links"
      return links
    end
    
    print "Grabbing '"+displayname(id)+"' ... "
    url = "http://#{Regions[@region]}/"+((id[2] != "A") ? "title/#{id[0]}": "name/#{id[0]}") # add /fullcast if you're using the fullcast code
    begin
      page = Hpricot(retrieve(url))
    rescue
      # Dodgey ID. Don't bother throwing an error, incase it was an invalid link mid-flow
      puts "malformed ID?"
      return links
    end
    
    if id[2] != "A" # Is it's a 'title'
      
      # Note to self, Add director?
      
      links = ((page/"table.cast")/:tr).collect {|row| [(row/"td.nm"/:a)[0].attributes['href'].gsub(/^\/name\/(nm[0-9]+)\/?$/,"\\1"),(row/"td.nm"/:a)[0].inner_text,"A"] if ["odd","even"].include?(row.attributes['class'])}.compact
      
      # This is the code for the fullcast page, this really returns too many links
      # so I've decided to assume that the 'main' page for the film lists all the
      # important cast members
      
      # maincast = true
      # links = ((page/"table.cast")/:tr).delete_if {|row| not (maincast = (maincast and ["odd","even"].include?(row.attributes['class'])))}
      
      # links = links.collect {|row| [(row/"td.nm"/:a)[0].attributes['href'].gsub(/^\/name\/(nm[0-9]+)\/?$/,"\\1"),(row/"td.nm"/:a)[0].inner_text,false]}
    else
      links = ((page/"div.filmo")[0]/:ol/:li).collect {|li| [(li/:a)[0].attributes['href'].gsub(/^\/title\/(tt[0-9]+)\/?$/,"\\1"),(li/:a)[0].inner_text,(((li/:a)[0].inner_text =~ /^"/ or li.children[1].to_s =~ /\(TV\)/) ? "TV" : ((li.children[1].to_s =~ /\(VG\)/) ? "VG": "F"))]}
    end
    
    open(cachename,"w").print(links.collect {|link| link.join("|")}.join("\n"))
    
    if not (@allowtv or id[2])
      links = removeTV(links)
    end
    
    puts links.length.to_s+" links"
    
    return links
  end
  
  def makeID(string)
    if string.is_a?(Array)
      return string
    end
    
    # This is going to need to be changed for the new id[2]. For now I'm assuming only films are given
    
    case string
    when /^tt[0-9]+$/
      url = "http://#{Regions[@region]}/title/#{string}"
      isfilm = true
      search = false
    when /^nm[0-9]$/
      url = "http://#{Regions[@region]}/name/#{string}"
      isfilm = false
      search = false
    else
      scope = "tt,nm"
      string,scope = $1,$2 if string =~ /^(.+)\s*#\s*(nm|tt)$/
      
      puts url = "http://#{Regions[@region]}/find?q="+URI.encode(string)+";s=#{scope}"
      search = true
    end
    
    if search
      # Do some searching, find
      raise "Sorry, I haven't done searching yet, can you use the URL and enter IDs for now please?"
      
      #note to self, leave the IMDB ID eg. tt23455667 in the string variable
    end
    
    begin
      page = Hpricot(retrieve(url))
    rescue
      raise "There is no artist on #{@description} called '#{string}' : #{url}"
    end
    
    name = (page/:h1)[0].children[0].to_s.strip
    
    return [string,name,(isfilm) ? "F" : "A"]
  end
  
  def details(id)
    
  end
  
  # Hmmm, this can't be right
  def displayname(id)
    "#{id[1]} ("+((id[2]) ? "Film" : "Actor")+")"
  end
  
  def self.displayname(id)
    "#{id[1]} ("+((id[2]) ? "Film" : "Actor")+")"
  end
  
  def removeTV(links)
    links.delete_if {|link| link[2] != "F"}
  end
end