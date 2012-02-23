#!/usr/bin/env ruby
$LOAD_PATH << '.'
require 'optparse'
require 'mechanize'
require 'colorize'
require 'array_extension'
require 'addressable/uri'

class ArgsParser
  def parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    @options = Hash.new

    @opts = OptionParser.new do |opt|
      # Set a banner displayed at the top
      # of the help screen
      opt.banner = "Usage: yawc.rb [options] URI to extract links from"

      opt.on('-o filepath', '--output-file', 'Save the scraped links in file') do |filepath|
        @options[:outputfile] = filepath
      end

      opt.on('-d number', '--depth', 'Determines the depth of recursive scanning') do |number|
        @options[:depth] = number
      end

      # No argument, shows at tail.  This will print an options summary.
      opt.on_tail("-h", "--help", "Show this message") do
        puts opt
        exit
      end
    end

    @opts.parse!(args)
  end

  def initialize(args)
    parse(args)

    unless args.empty?
      spider = Spider.new(args[0])
    else
      puts @opts.banner
    end
  end
end

class Spider
  def initialize(url)
    @visited_uri_collection = Array.new
    @agent = Mechanize.new
    @agent.user_agent_alias = 'Linux Mozilla'

    read_start_page(url)
  end

  def read_start_page(url)
    puts "Now reading the url given..."
    page = @agent.get(URI.parse(url))
    links = page.links

    unless links.empty?
      print "Found #{links.count} links on #{url}. ".green
      print 'Removing multiple links... '.green
      links.unique!
      print "#{links.count} links left. \n".green

      print "Start visiting the pages... \n".green
      visit_pages(links.clone)
    end
  end

  def visit_pages(links)
    links.each_index do |index|
      trap("SIGINT") {
        puts "\nCtrl+c caught => exiting.".blue.on_yellow; 
        puts "Collected links:".yellow
        puts @visited_uri_collection
        exit!
      }

      link = links[index]
      begin
        unless @agent.visited?(link.uri)
          print "#{index}/#{links.count})".light_blue + " Visiting #{link.href} ... ".light_blue
          begin
            new_page = link.click
            new_links = new_page.links
            @visited_uri_collection.push(link.uri)
            print "Found #{new_links.count} links ".yellow

            new_links.unique!
            new_links.unique_with!(links)

            puts "=> #{new_links.count} unique.".green

            links.concat(new_links) if new_links.count > 0

          rescue Mechanize::ResponseCodeError => e
            print "Mechanize::ResponseCodeError. Skipping...\n".red
          rescue NoMethodError => e
            print "NoMethodError. Skipping...\n".red
          rescue OpenSSL::SSL::SSLError => e
            print "OpenSSL::SSL::SSLError. Skipping...\n".red
          rescue SocketError => e
            print "SocketError. Skipping...\n".red
          rescue URI::InvalidURIError => e
            print "URI::InvalidURIError. Skipping...\n".red
          rescue Encoding::CompatibilityError => e
            print "Encoding::CompatibilityError. Skipping...\n".red
          rescue Net::HTTP::Persistent::Error => e
            print "Net::HTTP::Persistent::Error. Skipping...\n".red
          end
        else
          print "#{index}/#{links.count}) #{link.href} visited.\n".red
        end
      rescue Mechanize::UnsupportedSchemeError => e
        puts "#{index}/#{links.count}) Mechanize::UnsupportedSchemeError. #{link.href} => skipping.".red
      rescue Encoding::CompatibilityError => e
        puts "#{index}/#{links.count}) Encoding::CompatibilityError. #{link.href} => skipping.".red
      rescue URI::InvalidURIError => e
        puts "#{index}/#{links.count}) URI::InvalidURIError. #{link.href} => skipping.".red
      end
    end
  end
end

app = ArgsParser.new(ARGV)
