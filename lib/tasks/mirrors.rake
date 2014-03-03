namespace :mirrors do

  desc "Removes id element from mirrored pages' identifiers to align them"
  task :realign_identifiers => :environment do
    puts "Cleaning up identifiers:"
    count = 0
    Cms::Page.where("identifier LIKE '%:%'").find_each do |page|
      identifier = page.identifier[/^[^:]+/]
      count += Cms::Page.update_all ['identifier = ?', identifier], ['id = ?', page.id]
    end
    puts "Updated #{count} page identifiers."
  end

  desc "Updates contact forms' redirect url to identifier form"
  task :update_contact_forms => :environment do
    puts "Updating contact forms to identifier-based redirects:"
    count = 0
    Cms::ContactForm.all.find_each do |form|
      redirect_url = form.redirect_url
      pages = Cms::Page.where(slug: form.redirect_url.split('/').last).to_a.select{|p| p.full_path == form.redirect_url}
      puts "[#{form.id}]: '#{form.redirect_url}' -> (#{pages.size}) #{pages.first.try(:identifier)}"
      if pages.first
        form.redirect_url = pages.first.identifier
        form.save
        count += 1
      end
    end
    puts "Changed #{count} forms redirect_url"
  end

end