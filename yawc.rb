#!/usr/bin/env ruby
require 'mechanize'
require 'colorize'

depth = 1

if ARGV.empty? == false
  agent = Mechanize.new
  agent.user_agent_alias = 'Linux Mozilla'

  page = agent.get(URI.parse(ARGV[0]))
  links = page.links
  uri_links = links.map {|link| link.href}
  puts "Found #{links.length} links on #{ARGV[0]}.".green
  puts "I will try visiting every link now...\n".green

  counter = 1
  links_visited = 0
  links_not_active = 0

  links.each do |link|
    begin
      if agent.visited?(link.uri) == nil && link.uri.host == URI.parse(ARGV[0]).host
        print "#{counter}/#{links.count})".blue + " Visiting site: #{link.href}"
        begin
          new_page = link.click
          print '. '
          new_links = new_page.links
          print "This site includes #{new_links.count.to_s} links."

          new_unique_links = []
          new_links.each do |new_link|
            new_unique_links.push(new_link) unless uri_links.include?(new_link.href)
          end
          color = new_unique_links.length == new_links.length ? :yellow : :green
          puts " Adding #{new_unique_links.length} new links to the links array.".colorize(color)
          new_unique_links.each { |new_unique_link| links << new_unique_link; uri_links << new_unique_link.href} if new_unique_links.length > 0

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
        print "#{counter}/#{links.count})".blue + " I already visited the page >#{link.href}<. Skipping...\n".red
        links_visited += 1
      end
      counter += 1
    rescue Mechanize::UnsupportedSchemeError => e
      puts "#{counter}/#{links.count}) ".blue + "The requested protocol is not supported by Mechanize. Skipping link => #{link.href}...".red
      counter += 1
    rescue Encoding::CompatibilityError => e
      puts "#{counter}/#{links.count}) ".blue + "#{link.href} - Compatibility error. Skipping...".red
    rescue URI::InvalidURIError => e
      puts "#{counter}/#{links.count}) ".blue + "#{link.href} - Invalid URI error. Skipping...".red
    end
  end
  puts "Number of doubled links: #{links_visited}".yellow
  puts "Number of broken links: #{links_not_active}".yellow
else
  puts 'Please, type in address of the web site you want to crawl.'
end
