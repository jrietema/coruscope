namespace :translations do

  desc "Re-sets a specific language's translation of a site's files"
  task :reset_for_site, [:language, :site_id] => :environment do |task, args|

    site = Cms::Site.find(args[:site_id].to_i)
    raise "Could not find site for site_id=#{args[:site_id]}! Aborting." if site.nil?

    language = args[:language].to_sym
    raise "Invalid locale given: #{args[:language]}. Aborting." unless I18n.available_locales.include?(language)
    method = "description_#{language.downcase}="

    puts "Resetting #{language} translations for #{site.label}."

    count = 0

    site.files.find_each do |file|
      begin
        file.send(method, '')
        file.save
        count += 1
      rescue Exception => e
        puts "ERROR: #{e.message}\n#{e.backtrace}"
        break
      end
    end
    puts "Done. #{count} files #{language} translations reset."
  end

end