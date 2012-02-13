#!/usr/bin/env ruby
require 'mechanize'
require 'optparse'

def stats(links)
  number_of_links = 0
  number_of_no_text_links = 0
  number_of_foreign_page_links = 0
  links.each { |link| 
    number_of_links += 1
    number_of_no_text_links += 1 if link.text == ''
    number_of_foreign_page_links += 1 if true
  }
  return number_of_links, number_of_no_text_links, number_of_foreign_page_links
end

def print_the_links(links)
  count = 1
  links.each do |link|
    print count.to_s + ") Tekst: "
    print (link.text == '' ? "NO_TEXT_LINK" : link.text) + "\n"
    print "Adres: #{link.uri}\n\n"
    count += 1
  end
end

def print_stats(statistics)
  puts "Total number of links: #{statistics[0]}"
  puts "Number of links without text: #{statistics[1]}"
  puts "Number of outside pages links: #{statistics[2]}"
end

options = {}
optparse = OptionParser.new do |opts|
  # Set a banner displayed at the top
  # of the help screen
  opts.banner = "Usage: yawc.rb [options] URI to extract links from"

  # Define the options and what they do
  options[:outputfile] = false
  opts.on( '-o', '--output-file', 'Print output into the given file' ) do
    options[:outputfile] = true
  end

  # This displays the help screen
  opts.on( '-h', '--help', 'Displays this help' ) do
    puts opts
    exit
  end
end

optparse.parse!

if ARGV[0] != nil
  agent = Mechanize.new
  agent.user_agent_alias = 'Linux Mozilla'

  begin
    page = agent.get(URI(ARGV[0]))
    links = page.links.clone
    print_the_links(links)
    print_stats(stats(links))
  rescue Mechanize::ResponseReadError => e
    page = e.force_parse
  end
else
  puts optparse.banner
end
