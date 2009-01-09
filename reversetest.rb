require 'library'
require 'modules/wikipedia'
fetcher = Wikipedia.new

start = fetcher.makeID("Whoopi_Goldberg")

links = fetcher.links_to(start)
links.each do |link|
  back = fetcher.links_from(link)
  if not back.include? start
    puts "#{start} > #{link} !> #{start}"
    Process.exit()
  end
end