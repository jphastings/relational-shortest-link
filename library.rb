require 'open-uri'
#require 'time'

$downloadlimit = 500 * 8 # KB per second

def retrieve(url)
  starttime = 0
  last = 0
  taken = 0
  
	open(url,
	"User-agent"=>"Relational Shortest Link script: http://github.com/jphastings/reltional-shortest-link/ (Ruby)").read
#	:content_length_proc => lambda {|exp_size|
#    starttime = Time.now.to_f
#  },
#  :progress_proc => lambda {|completed|
#    shouldhavetaken = completed / ($downloadlimit * 1024.0)
#    hastaken = Time.now.to_f - starttime
#    if (defecit = hastaken - shouldhavetaken) > 0
#      sleep(defecit)
#    end
#  }).read
  
end