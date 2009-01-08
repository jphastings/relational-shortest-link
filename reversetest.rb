require 'library'
require 'wikipedia'
fetcher = Wikipedia.new

#start = fetcher.makeID("Whose_Line_Is_It_Anyway?")
start = fetcher.makeID("Whoopi_Goldberg")

p fetcher.links_from(start)

Process.exit
links = fetcher.links_to(start)
links.each do |link|
  back = fetcher.links_from(link)
  if not back.include? start
    puts "#{start} > #{link} !> #{start}"
    Process.exit()
  end
end