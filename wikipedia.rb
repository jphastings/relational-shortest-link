# This scrapes the webpages themselves. Its very, very inefficient as the script
# has to make 2 calls for every link to make sure its not a redirect. I'll be updating
# it to use the wikimedia API... after I've finished my physics degree exams next week O_O

require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'uri'

class Wikipedia
  attr_accessor :region,:allowdates
  attr_reader :description
  
  Opts = [
    {"name"=>"Allow Dates","question"=>"Would you like to include date pages?","default"=>"n"},
    {"name"=>"Region","question"=>"Which wikipedia version would you like to use?","default"=>"en"}
  ]
  
  Defaults = ["Special:Random","Kevin_Bacon"]
  
  Regions = ["aa","ab","af","ak","als","am","an","ang","ar","arc","as","ast","av","ay","az","ba","bar","bat_smg","bcl","be","be_x_old","bg","bh","bi","bm","bn","bo","bpy","br","bs","bug","bxr","ca","cbk_zam","cdo","ce","ceb","ch","cho","chr","chy","co","cr","crh","cs","csb","cu","cv","cy","da","de","diq","dsb","dv","dz","ee","el","eml","en","eo","es","et","eu","ext","fa","ff","fi","fiu_vro","fj","fo","fr","frp","fur","fy","ga","gan","gd","gl","glk","gn","got","gu","gv","ha","hak","haw","he","hi","hif","ho","hr","hsb","ht","hu","hy","hz","ia","id","ie","ig","ii","ik","ilo","io","is","it","iu","ja","jbo","jv","ka","kaa","kab","kg","ki","kj","kk","kl","km","kn","ko","kr","ks","ksh","ku","kv","kw","ky","la","lad","lb","lbe","lg","li","lij","lmo","ln","lo","lt","lv","map_bms","mdf","mg","mh","mi","mk","ml","mn","mo","mr","mt","mus","my","myv","mzn","na","nah","nap","nds","nds_nl","ne","new","ng","nl","nn","no","nov","nrm","nv","ny","oc","om","or","os","pa","pag","pam","pap","pdc","pi","pih","pl","pms","ps","pt","qu","quality","rm","rmy","rn","ro","roa_rup","roa_tara","ru","rw","sa","sah","sc","scn","sco","sd","se","sg","sh","si","simple","sk","sl","sm","sn","so","sr","srn","ss","st","stq","su","sv","sw","szl","ta","te","tet","tg","th","ti","tk","tl","tlh","tn","to","tpi","tr","ts","tt","tum","tw","ty","udm","ug","uk","ur","uz","ve","vec","vi","vls","vo","wa","war","wo","wuu","xal","xh","yi","yo","za","zea","zh","zh_classical","zh_min_nan","zh_yue","zu"]
  
  def initialize(allowdates = false,region = "en")  
    self.region = region
    self.allowdates = allowdates
  end
  
  def region=(region)
    if not Regions.include? region
      raise "Sorry, #{region} isn't a valid region - use: "+allowed.join(", ")
    end
    @region = region
    setdesc
  end
  
  def allowdates=(allowdates)
    if @region != "en"
      @allowdates = allowdates 
      puts "Be warned: I haven't implemented Month/Day combo removing in non-english languages yet"
    else
      allowed = [true,false]

      if not allowed.include? allowdates
        raise "You need to specify true or false to allow date pages or not"
      end
      @allowdates = allowdates  
    end
    setdesc
  end
  
  def setdesc
    @description = "Wikipedia (#{@region}; "+((@allowdates) ? "Allow" : "No" )+" dates)"
    @cacheroot = "wikipedia.#{@region}."+((@allowdates) ? "nodates" : "dates")
  end
  
  def canreverselookup?
    true
  end
  
  def directional?
    true
  end
  
  def links_from(id)
    links = []
    cachename = "cache/#{@cacheroot}.#{id}.links_from.txt"
    if File.exists?(cachename)
      links = open(cachename).readlines.collect{|link| link.strip}
      puts " Cached  '"+displayname(id)+"' >>> "+links.length.to_s
      return links
    end
    
    print "Grabbing '"+displayname(id)+"' >>> "
    begin
      page = Hpricot(retrieve("http://#{@region}.wikipedia.org/wiki/#{id}"))
    rescue
      puts "malformed ID?"
      return links
    end
    
    # This removes all the navboxes at the bottom of pages showing other objects in groups (see Ritalin)
    (page/".navbox").remove
    
    raw = (page/"#bodyContent"/:a).collect {|a| a.attributes['href'] }.compact.collect {|href| $1 if href.gsub(/#.+$/,"") =~ /^(?:http:\/\/#{@region}.wikipedia.org)?\/wiki\/([^:]+?)?$/ }.unshift(id).uniq.compact[1..-1]
    
    links = parselinks(raw)
    open(cachename,"w").print(links.join("\n"))
    return links
  end
  
  def links_to(id)
    links = []
    
    cachename = "cache/#{@cacheroot}.#{id}.links_to.txt"
    if File.exists?(cachename)
      links = open(cachename).readlines.collect{|link| link.strip}
      puts " Cached  '"+displayname(id)+"' <<< "+links.length.to_s
      return links
    end
      
    print "Grabbing '"+displayname(id)+"' <<< "
    begin
      page = Hpricot(retrieve("http://#{@region}.wikipedia.org/w/index.php?title=Special:WhatLinksHere/#{id}&hideredirs=1&limit=100000&namespace=0"))
    rescue
      puts "0 links"
      return links
    end
    
    # This removes all the navboxes at the bottom of pages showing other objects in groups (see Ritalin)
    (page/".navbox").remove
    
    raw = (page/"#bodyContent"/:a).collect {|a| a.attributes['href'] }.compact.collect {|href| $1 if href.gsub(/#.+$/,"") =~ /^\/wiki\/([^:]+?)?$/ }.unshift(id).uniq.compact[1..-1]

    links = parselinks(raw)
    open(cachename,"w").print(links.join("\n"))
    return links
  end
  
  def parselinks(raw)
    if not @allowdates
      raw = raw.delete_if{|link| (not link.match(/^(?:[0-9]{4}|(?:January|February|March|April|May|June|July|August|September|October|November|December)_[0-9]{1,2}(?:[0-9]{2})?)$/).nil?) }
    end
    
    puts raw.length.to_s+" links"
    
    raw.each do |href|
      begin
        links.push(makeID(href))
      rescue
        
      end
    end
  end
  
  def details(id)
    return {"url"=>"http://#{@region}.wikipedia.org/wiki/#{id}"}
  end
  
  def makeID(id)
    cachename = "cache/wikipedia.#{@region}.#{id}.trueid.txt"
    if File.exists?(cachename) and id.downcase != "special:random"
      return open(cachename).read
    end
    
    begin    
      page = Hpricot(retrieve("http://#{@region}.wikipedia.org/wiki/#{id}"))
    rescue
      raise "There is no page on #{@description} called '"+displayname(id)+"'"
    end
    id = (page/".printfooter"/:a)[0].attributes['href'].gsub(/^(?:http:\/\/#{@region}.wikipedia.org)?\/wiki\/(.+)$/,"\\1")
    if id.downcase != "special:random"
      open(cachename,"w").print(id)
    end
    return id
  end
  
  def displayname(id)
    URI.unescape(id).gsub(/_/," ")
  end
end