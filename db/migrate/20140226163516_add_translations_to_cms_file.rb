class AddTranslationsToCmsFile < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        Cms::File.create_translation_table!({
                                                :description => :text
                                            }, {
                                                :migrate_data => false
                                            })
      end
      dir.down do
        Cms::File.drop_translation_table! :migrate_data => false
      end
    end
  end
end
