require 'rubygems'
require 'hpricot'
require 'json'

class Spitweb
  attr_reader :description
  
  Defaults = [[1,"JP Hastings-Spital","m"],[343,"James Kelly","m"]]
    
  Opts = []

  def initialize
    @description = "Spitweb"
    @cacheroot = "spitweb"
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
      links = open(cachename).readlines.collect{|link| link = link.strip.split("|"); link[0] = link[0].to_i; link}
      puts " Cached  '"+displayname(id)+"' ... "+links.length.to_s+" links"
      return links
    end
    
    print "Grabbing '"+displayname(id)+"' ... "
    url = "http://spitweb.thesethings.org/links.php?userid=#{id[0]}"
    begin
      page = retrieve(url)
    rescue
      # Dodgey ID. Don't bother throwing an error, incase it was an invalid link mid-flow
      puts "malformed ID?"
      return links
    end
    
    links = JSON.parse(page).collect{|p| [p['id'].to_i,p['name'],p['sex']]}.compact
    
    open(cachename,"w").print(links.collect {|link| link.join("|")}.join("\n"))
        
    puts links.length.to_s+" links"
    
    return links
  end
  
  def makeID(string)
    if string.is_a?(Array)
      return string
    end
    
    url = "http://spitweb.thesethings.org/search.php?q="+URI.encode(string)
    
    begin
      page = retrieve(url)
    rescue
      # Dodgey ID. Don't bother throwing an error, incase it was an invalid link mid-flow
      puts "malformed ID?"
      return links
    end
    
    hits = JSON.parse(page).collect{|p| [p['id'].to_i,p['name'],p['sex']]}
    
    if hits.length > 1
      puts "Sorry, there are more than one people like that. Be more specific.\n"+hits.collect{|person| person[1] }.join(", ")
      Process.exit
    end
    
    return hits[0]
  end
  
  def details(id)
    
  end
  
  def displayname(id)
    "#{id[1]} (#{id[2]})"
  end
  
  def removeTV(links)
    links.delete_if {|link| link[2] != "F"}
  end
end