namespace :images do

  desc "Imports images in groups from a filesystem path"
  task :import, [:path,:site_id] => :environment do |task,args|

    dir = args[:path]
    id = args[:site_id]
    if dir.blank? || id.blank?
      puts "Arguments:\n1. Directory for import\n2. Id of Site\nPlease provide valid arguments for both."
      exit
    end
    raise "Directory not found '#{dir}'. Aborting." unless File.exist?(dir)
    site = Cms::Site.find(id)
    raise "No such site (id: #{id}). Aborting." if site.nil?

    created_groups = []
    file_count = 0
    files_created = 0

    Dir.glob(File.join(dir, '**/*.{jpg,JPG,png,PNG}')).each do |file|
      tokens = file.sub!(dir,'').split('/').select{|p|!p.blank?}
      filename = tokens.pop
      subdir = File.join(dir, tokens)
      parent_id = site.groups.files.root.first.id
      crumbs = []
      group_label = ''
      tokens.each do |group_name|
        pretty_name = group_name.split(/[-_\s]+/).map{|s| s.capitalize}.join(' ').gsub(/[^-_\w\d\süÜäÄöÖ]/,'')
        group = site.groups.files.where(["label LIKE ? OR label LIKE ?", group_name.downcase, pretty_name]).first
        if group.nil?
          puts "Assigned new group '#{pretty_name}' for '#{group_name}'"
          pos = site.groups.files.where(parent_id: parent_id).count
          group = site.groups.files.create({label: pretty_name, parent_id: parent_id, position: pos})
          created_groups << crumbs.join('/')
        end
        crumbs << group.label
        parent_id = group.id
        group_label = crumbs.last.split(/[^\w\d]+/).flatten.uniq.map{|s| s.capitalize}.join('_')
      end
      file_count += 1
      # use parent_is as group_id from here on
      if parent_id.nil?
        puts "Skipping import of file: #{filename} - no group to import into."
      else
        # prettify filename
        pretty = filename.gsub(/(\d{6})\d+/,'\1').gsub(/([-_]+\d{3})\d+/,'\1')
        unless pretty =~ /^[A-Za-züÜäÄöÖ]/ || pretty =~ /\w{6}/
          # slap a label on it if it doesn't begin with letters
          pretty = group_label.concat('_' + pretty.gsub(/[-_]+\d+/,''))
        end
        # downcase file ending
        pretties = pretty.split('.')
        ending = pretties.pop.downcase
        pretty = (pretties << ending).join('.')
        unless pretty == filename
          # move the original file
          FileUtils.mv(File.join(subdir, filename), File.join(subdir, pretty))
          puts "Renamed '#{filename}' to '#{pretty}'"
        end
        # check if file exists in this group already
        # - only trying to make this task not process the same image twice,
        # not matching with uploaded content
        label = pretty.gsub('_',' ').sub(/\.\w+$/,'').capitalize
        existing_image = site.files.where(['label = ? AND group_id = ?', label, parent_id]).first
        if existing_image.nil?
          obj = site.files.create do |image|
            image.label = label
            image.file = File.open(File.join(subdir, pretty))
            image.group_id = parent_id
          end
          if obj.valid?
            files_created += 1
            puts "#{filename} @ #{crumbs.join('/')}"
          else
            puts "Could not create a file object for: #{pretty}\nReason: #{obj.errors.full_messages}"
          end
        end
      end
    end
    # Report
    puts "Created #{files_created} out of #{file_count} files found. The following groups were also created:"
    created_groups.each do |name|
      puts name
    end
    puts "Done."

  end

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
