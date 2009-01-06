require 'lastfm'
fetcher = Lastfm.new

start = fetcher.makeID("muse")

fetcher.links(start).each do |link|
  if not fetcher.links(link).include? start
    puts "#{start} > #{link} !> #{start}"
    Process.exit()
  end
end