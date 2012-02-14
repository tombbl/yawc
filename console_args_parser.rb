require 'optparse'
require 'ostruct'
require 'pp'
# require 'mechanize'

class ArgsParser

  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = OpenStruct.new
    options.outputfile = []

    opts = OptionParser.new do |opts|
      # Set a banner displayed at the top
      # of the help screen
      opts.banner = "Usage: yawc.rb [options] URI to extract links from"

      opts.on( '-o FILEPATH', '--output-file', 'Log the output into the given file' ) do |filepath|
        options.outputfile << filepath
      end
      
      # No argument, shows at tail.  This will print an options summary.
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    opts.parse!(args)
    options
  end
end

class Spider
  def initialize; end

  def get_links; end
end

options = ArgsParser.parse(ARGV)
pp options


#if ARGV[0] != nil
#  agent = Mechanize.new
#  agent.user_agent_alias = 'Linux Mozilla'

#  begin
#    page = agent.get(URI(ARGV[0]))
#    links = page.links.clone
#    print_the_links(links)
#    print_stats(stats(links))
#  rescue Mechanize::ResponseReadError => e
#    page = e.force_parse
#  end
#else
#  puts optparse.banner
#end
