#!/usr/bin/env ruby
$LOAD_PATH << '.'
require 'optparse'
require 'mechanize'
require 'colorize'
require 'array_extension'

class ArgsParser

  def parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    @options = Hash.new

    @opts = OptionParser.new do |opt|
      # Set a banner displayed at the top
      # of the help screen
      opt.banner = "Usage: yawc.rb [options] URI to extract links from"

      opt.on('-o FILEPATH', '--output-file', 'Log the output into the given file') do |filepath|
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
    @options
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
    @agent = Mechanize.new
    @agent.user_agent_alias = 'Linux Mozilla'

    scrape(url)
  end

  def scrape(url)
    @page = @agent.get(URI.parse(url))
    @links = @page.links

    unless @links.empty?
      print "Found #{@links.count} links on #{url}. ".green
      print 'Removing multiple links... '.green
      @links.unique!
      print "#{@links.count} links left. \n".green

      print "Start visiting the pages... \n".green
      visit_pages(@links.clone)
    end
  end

  def visit_pages(links)
    links.each_index do |index|
      link = links[index]
      begin
        if @agent.visited?(link.uri) == nil
          print "#{index}/#{links.count})".light_blue + " Visiting site: #{link.href}"
          begin
            new_page = link.click
            print '. '
            new_links = new_page.links
            print "This site includes #{new_links.count} links."

            new_links_count = new_links.count
            new_links.unique!
            new_links.unique_with(links)

            color = new_links_count == new_links.count ? :yellow : :green
            puts " Adding #{new_links.count} new links to the links array.".colorize(color)

            new_links.each {|new_link| links << new_link} if new_links.count > 0

          rescue Mechanize::ResponseCodeError => e
            print "#{link.uri} - The page does not respond. Skipping...\n".red
            links_not_active += 1
          rescue NoMethodError => e
            print "#{link.uri} - Method not supported. Skipping...\n".red
          rescue OpenSSL::SSL::SSLError => e
            print "#{link.uri} - SSL Error occured. Skipping...\n".red
          rescue SocketError => e
            print "#{link.uri} - Socket error occured. Skipping...\n".red
          rescue URI::InvalidURIError => e
            print "#{link.uri} - Invalid URI error. Skipping...\n".red
          rescue Encoding::CompatibilityError => e
            print "#{link.uri} - Compatibility error. Skipping...\n".red
          end
        else
          print "#{index}/#{links.count})".light_blue + " I already visited the page >#{link.href}<. Skipping...\n".red
        end
      rescue Mechanize::UnsupportedSchemeError => e
        puts "#{index}/#{links.count}) ".light_blue + "The requested protocol is not supported by Mechanize. Skipping link => #{link.href}...".red
      rescue Encoding::CompatibilityError => e
        puts "#{index}/#{links.count}) ".light_blue + "#{link.href} - Compatibility error. Skipping...".red
      rescue URI::InvalidURIError => e
        puts "#{index}/#{links.count}) ".light_blue + "#{link.href} - Invalid URI error. Skipping...".red
      end
    end
  end
end

app = ArgsParser.new(ARGV)
