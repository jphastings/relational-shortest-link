# This scrapes the webpages themselves. Its horifically inefficient as the script
# has to make 2 calls for every link to make sure its not a redirect. I'll be updating
# it to use the wikimedia API... after I've finished my physics degree exams next week O_O

class Wikipedia
  attr_accessor :region
  attr_reader :description
   
  def initialize(region = "en")
    require 'rubygems'
    require 'hpricot'
    require 'open-uri'
    require 'uri'
    
    self.region = region
  end
  
  def region=(region)
    @region = region
    @description = "Wikipedia (#{@region})"
  end
  
  def canreverselookup?
    true
  end
  
  def directional?
    true
  end
  
  def links(id)
    grablinks("http://#{@region}.wikipedia.org/wiki/"+URI.escape(id),id)
  end
  
  def linksto(id)
    grablinks("http://#{@region}.wikipedia.org/w/index.php?title=Special:WhatLinksHere/"+URI.escape(id)+"&hideredirs=1&namespace=0",id)
  end
  
  def grablinks(url,id)
    links = []
    begin
      page = Hpricot(open(url))
    rescue
      return links
    end
    
    # This removes all the navboxes at the bottom of pages showing other objects in groups (see Ritalin)
    (page/".navbox").remove
    
    raw = (page/"#bodyContent"/:a).collect {|a| a.attributes['href'] }.compact.collect {|href| $1 if href.gsub(/#.+$/,"") =~ /\/wiki\/([^:]+?)?$/ }.uniq.compact
    
    puts "Grabbing '"+URI.unescape(id)+"' ... "+raw.length.to_s+" links"
    raw.each do |href|
      begin
        links.push(makeID(URI.unescape($1)))
      rescue
        
      end
    end
  end
  
  def details(id)
    return {"url"=>"http://#{@region}.wikipedia.org/wiki/"+URI.escape(id)}
  end
  
  def makeID(id)
    begin
      pre = "http://#{@region}.wikipedia.org/wiki/"+URI.escape(id)
      url = (Hpricot(open(pre))/".printfooter"/:a)[0].attributes['href']
      #cachecopy(pre,url)
      url.gsub(/^.*\/wiki\/(.+)$/,"\\1")
    rescue
      raise "There is no page on #{@description} called '#{id}'"
    end 
  end
end