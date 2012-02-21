class Array
  def unique!
    strip(self)
  end

  def unique
    strip(self.clone)
  end

  def unique_with!(existing_links)
    check_uniqueness_between(self, existing_links.clone)
  end

  def unique_with(existing_links)
    check_uniqueness_between(self.clone, existing_links.clone)
  end

  def strip(links)
    links_clone = links.clone

    links_clone.each do |link_clone|
      duplicates = Array.new
      links.each {|link| duplicates << link if link.href == link_clone.href}
      unless duplicates.empty?
        duplicates.each {|duplicate| links.delete(duplicate)} if duplicates.pop != nil
      end
    end
    links
  end

  def check_uniqueness_between(new_links, links)
    duplicates = Array.new

    new_links.each {|new_link|
      links.each {|link| duplicates << new_link if new_link.href == link.href}
    }
    duplicates.each {|duplicate| new_links.delete(duplicate)} unless duplicates.empty?

    new_links
  end

  private :strip, :check_uniqueness_between
end
