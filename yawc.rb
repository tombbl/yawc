#!/usr/bin/env ruby
require 'mechanize'
require 'colorize'

# sets the depth of scanning
# 0 - no limits
# 1 - given domain only
# 2 - the given domain and the whole external domain found as the first during scanning
# 3 - etc.
depth = 1

class Array
  def unique_links()
    # Clone the given ary
    links_clone = links.clone

    # Check href field of every link of the cloned ary with all elements in original ary.
    # If in original ary you find links with the same href field, put the links into another, newly created ary.
    links_clone.each do |link_clone|
      links_to_delete = Array.new
      links.each {|link| links_to_delete << link if link.href == link_clone.href}
      unless links_to_delete.empty?
        # Pop one of the collected links (if we don't do it, we'd delete all the links, which have the same href).
        # If there's not nil in return, go through links_to_delete and delete the links from original links ary.
        links_to_delete.each {|link_to_delete| links.delete(link_to_delete)} if links_to_delete.pop != nil
      end
    end
    links
  end
end

def leave_only_unique_links(links)
  # Clone the given ary
  links_clone = links.clone
  
  # Check href field of every link of the cloned ary with all elements in original ary.
  # If in original ary you find links with the same href field, put the links into another, newly created ary.
  links_clone.each do |link_clone|
    links_to_delete = Array.new
    links.each {|link| links_to_delete << link if link.href == link_clone.href}
    unless links_to_delete.empty?
      # Pop one of the collected links (if we don't do it, we'd delete all the links, which have the same href).
      # If there's not nil in return, go through links_to_delete and delete the links from original links ary.
      links_to_delete.each {|link_to_delete| links.delete(link_to_delete)} if links_to_delete.pop != nil
    end
  end
  links
end

def check_uniqueness_between_arrays(links, newlinks)
  new_links = newlinks.clone
  new_links_to_delete = Array.new
  new_links.each {|new_link|
    links.each {|link| new_links_to_delete << new_link if new_link.href == link.href}
  }
  new_links_to_delete.each {|link_to_delete| new_links.delete(link_to_delete)} unless new_links_to_delete.empty?

  new_links
end

if ARGV.empty? == false
  agent = Mechanize.new
  agent.user_agent_alias = 'Linux Mozilla'

  page = agent.get(URI.parse(ARGV[0]))
  links = page.links
  puts "Found #{links.count} links on #{ARGV[0]}".green
  print 'Removing multiple links... '.green

  links = leave_only_unique_links(links)

  puts "#{links.count} links left.".green
  puts "Start visiting the links...\n".green

  counter = 1
  links_visited = 0
  links_not_active = 0

  links.each do |link|
    begin
      if agent.visited?(link.uri) == nil
        print "#{counter}/#{links.count})".blue + " Visiting site: #{link.href}"
        begin
          new_page = link.click
          print '. '
          new_links = new_page.links
          print "This site includes #{new_links.count} links."

          new_unique_links = leave_only_unique_links(new_links)
          verified_new_links = check_uniqueness_between_arrays(links, new_unique_links)
          verified_new_links.compact!
          color = verified_new_links.count == new_links.count ? :yellow : :green
          puts " Adding #{verified_new_links.count} new links to the links array.".colorize(color)

          verified_new_links.each {|new_link| links << new_link} if verified_new_links.count > 0

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
