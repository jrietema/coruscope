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
end