#!/usr/bin/env ruby

case ARGV[0]
when "wikipedia"
  require 'wikipedia'
  fetcher = Wikipedia.new

  start = fetcher.makeID((ARGV[1]) ? ARGV[1] : "Special:Random")
  goal  = fetcher.makeID((ARGV[2]) ? ARGV[2] : "Kevin Bacon")

when "lastfm_tracks"
  require 'lastfm'
  fetcher = Lastfm_tracks.new

  fetcher.threshold = 15

  start = fetcher.makeID((ARGV[1]) ? ARGV[1] : "This Love|Maroon 5")
  goal  = fetcher.makeID((ARGV[2]) ? ARGV[2] : "Kryptonite|3 Doors Down")

when "lastfm_artists"
  require 'lastfm'
  fetcher = Lastfm_artists.new

  start = fetcher.makeID((ARGV[1]) ? ARGV[1] : "Muse")
  goal  = fetcher.makeID((ARGV[2]) ? ARGV[2] : "The Strokes")
else
  puts "Usage: ruby shortest.rb <module> [<start point> [<end point>]]"
  puts " Currently supported Modules: wikipedia, lastfm_tracks, lastfm_artists"
  Process.exit
end


## Nothing more to edit here unless you wanna change the code

puts "Going from '#{start}' to '#{goal}' using "+fetcher.description

if fetcher.canreverselookup?
  # Two directional lookup
  
  done = [[],[]]
  routes = [[[start]],[[goal]]]
  finished = []
  
  dir = 0
  
  while finished == []
    nextdir = (dir == 0) ? 1 : 0
    if routes[dir].length > 0
      
      from = nil
      while done[dir].include?(from) or from.nil?
        route = routes[dir].shift
        from = route.last
      end
      
      fetcher.links(from).collect { |to|
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
    else
      puts "Error! There are dead ends, these two points are not linked!"
      Process.exit
    end
    
    dir = nextdir
  end
  
  puts "The shortest path"+(finished.length > 1 ? "s" : "")+" from #{start} to #{goal} using "+fetcher.description
  finished.each do |route|
    puts " "+((route).join((fetcher.directional?) ? " > " : " <-> "))
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
    
    fetcher.links(from).each do |to|
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
      puts "The shortest path"+(finished.length > 1 ? "s" : "")+" from #{start} to #{goal} using "+fetcher.description
      finished.each do |route|
        puts " "+((route).join((fetcher.directional?) ? " > " : " <-> "))
      end
      Process.exit
    end
    done.push from
  end

  puts "Ooops, we ran out of places to look! Would you believe it?!"
end