namespace :images do

  desc "Rename a part (for instance resolution) of existing image paths, in the filesystem and DB"
  task :reprocess_or_delete, [:site] => :environment do |task,args|

    conditions = ''
    unless args[:site].blank?
      site_id = args[:site].to_i == 0 ? Cms::Site.where(['identifier = ? OR hostname = ? OR path = ?', args[:site], args[:site], args[:site]]).first.id : args[:site].to_i
      conditions = ['site_id = ?', site_id]
    end

    count = 0
    deleted = 0

    Cms::File.where(conditions).find_each do |file|
      if File.exist?(file.file.path)
        if file.is_image?
          file.file.reprocess!
          count += 1
        end
      else
        file.destroy
        puts "Removing missing file [#{file.id}]: #{file.file.path}"
        deleted += 1
      end
    end

    puts "Done. Reprocessed #{count} images, deleted #{deleted} files."

  end

end
