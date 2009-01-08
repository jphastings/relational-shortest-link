#!/usr/bin/env ruby
require 'wikipedia'
require 'lastfm'
require 'imdb'
require 'library'

modules = ["wikipedia","imdb","lastfm_artists","lastfm_tracks"]

command = ARGV
$stdout.sync = true

if command.include? "-i"
  if command.length == 1
    command = []
  else
    command.delete("-i")
  end
  
  puts "You're in interactive mode"
  
  default = (command[0].nil?) ? "wikipedia" : command[0]
  print "What module would you like to use? [#{default}] "
  command[0] = $stdin.gets.strip
  if command[0].empty?
    command[0] = default
  end
  
  # There has to be a better way of doing this...
  case command[0]
  when "wikipedia"
    chosen = Wikipedia
  when "imdb"
    chosen = IMDB
  when "lastfm_artists"
    chosen = Lastfm_artists
  when "lastfm_tracks"
    chosen = Lastfm_tracks
  else
    puts "We don't have that module available"
    Process.exit
  end
  
  opts = chosen::Opts
  defaults = chosen::Defaults
  
  default = (command[1].nil?) ? defaults[0] : command[1]
  print "Where would you like to start? ["+chosen.displayname(default)+"] "
  command[1] = $stdin.gets.strip
  if command[1].empty?
    command[1] = default
  end
  
  default = (command[2].nil?) ? defaults[1] : command[2]
  print "Where would you like to start? ["+chosen.displayname(default)+"] "
  command[2] = $stdin.gets.strip
  if command[2].empty?
    command[2] = default
  end
    
  
  point = 3
  if opts.length > 0
    opts.each do |opt|
      default = (command[point].nil?) ? opt['default'] : command[point]
      print "#{opt['question']} [#{default}] "
      command[point] = $stdin.gets.strip
      if command[point].empty?
        command[point] = default
      end
      
      point += 1
    end
  end
end
  
case command[0]
when "wikipedia"
  fetcher = Wikipedia.new
  
  if not command[3].nil?
    fetcher.allowdates = (command[3] =~ /y|true/i) ? true : false
  end
  
  if not command[4].nil?
    fetcher.region = command[4]
  end
  
  start = fetcher.makeID((command[1]) ? command[1] : "Special:Random")
  goal  = fetcher.makeID((command[2]) ? command[2] : "Kevin Bacon")

when "imdb"
  fetcher = IMDB.new
  
  if not command[3].nil?
    fetcher.region = command[3]
  end
  
  if not command[4].nil?
    fetcher.othertitles = (command[4] =~ /y|true/i) ? true : false
  end
  
  start = fetcher.makeID((command[1]) ? command[1] : "Special:Random")
  goal  = fetcher.makeID((command[2]) ? command[2] : "Kevin Bacon")

when "lastfm_tracks"
  fetcher = Lastfm_tracks.new
  
  if not command[3].nil?
    fetcher.threshold = command[3].to_i
  end

  start = fetcher.makeID((command[1]) ? command[1] : "This Love|Maroon 5")
  goal  = fetcher.makeID((command[2]) ? command[2] : "Kryptonite|3 Doors Down")

when "lastfm_artists"
  fetcher = Lastfm_artists.new
  
  if not command[3].nil?
    fetcher.threshold = command[3].to_i
  end

  start = fetcher.makeID((command[1]) ? command[1] : "Muse")
  goal  = fetcher.makeID((command[2]) ? command[2] : "The Strokes")

else
  puts "Usage: shortest <module> [<start point> [<end point>]]"
  puts " Currently supported Modules: "+modules.join(", ")
  Process.exit
end


puts "Going from '"+fetcher.displayname(start)+"' to '"+fetcher.displayname(goal)+"' using "+fetcher.description

if (not fetcher.directional?) or fetcher.canreverselookup?
  # Two directional lookup
  
  done = [[],[]]
  routes = [[[start]],[[goal]]]
  finished = []
  
  dir = 0
  
  while finished == []
    nextdir = (dir == 0) ? 1 : 0
    
    from = nil
    while done[dir].include?(from) or from.nil?
      route = routes[dir].shift
      from = route.last
    end
    
    print "Hop #%d: " % (route.length)
    links = (dir == 0) ? fetcher.links_from(from) : fetcher.links_to(from)
    
    links.collect { |to|
      if done[nextdir].include? to
        routes[nextdir].each do |backwards|
          if backwards.last == to
            toadd = (route + backwards.reverse).uniq
            if dir == 1
              toadd.reverse!
            end
            finished.push(toadd)
          end
        end
      else
        terminate = done[dir].include? to
          
        routes[dir].push(route + [to]) 
        routes[dir].each do |forwards|
          if forwards.last == from
            routes[dir].delete(forwards)
            if not terminate
              routes[dir].push(forwards + [to])
            end
          end
        end
      end
    }
    done[dir].push from  
    
    if routes[dir].length == 0
      puts "Error! There are no more routes left to try from this direction, these points are not linked"+((fetcher.directional?)? " in this direction" : "")+"."
      Process.exit
    end
    
    dir = nextdir
  end
else
  # One directional lookup
  done = []
  routes = [[start]]
  finished = []

  while routes.length > 0
    
    from = nil
    while done.include?(from) or from.nil?
      if routes.length == 0
        puts "Ooops, we ran out of places to look! Would you believe it?!"
        Process.exit
      end
      route = routes.shift
      from = route.last
    end
    
    fetcher.links_from(from).each do |to|
      if to == goal
        finished.push(route + [to])
      else
        terminate = done.include? to
          
        routes.push(route + [to]) 
        routes.each do |forwards|
          if forwards.last == from
            routes.delete(forwards)
            if not terminate
              routes.push(forwards + [to])
            end
          end
        end
      end
    end
    if finished != []
      break
    end
    done.push from
  end
  
  if finished == []
    puts "Ooops, we ran out of places to look! Would you believe it?!"
    Process.exit
  end
end

last = nil
puts "The shortest path"+(finished.length > 1 ? "s" : "")+" from '"+fetcher.displayname(start)+"' to '"+fetcher.displayname(goal)+"' using "+fetcher.description
finished.sort{|x,y| x.length <=> y.length}.each do |route|
  if not last.nil? and last != route.length
    puts ""
  end
  puts route.length.to_s+": "+(route.collect{|id| fetcher.displayname(id)}.join((fetcher.directional?) ? " > " : " <-> "))
  last = route.length
end