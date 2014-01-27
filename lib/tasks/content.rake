namespace :content do

  desc "Replaces a pattern with a replacement string"
  task :replace, [:pattern, :string] => :environment do |task,args|
    patternstr = args[:pattern]
    string = args[:string]
    if patternstr.empty? || string.empty?
      puts "USAGE:\nrake content:replace[pattern, string]"

    end
  end
end