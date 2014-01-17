class CreateCmsGroups < ActiveRecord::Migration
  def change

    create_table :cms_groups do |t|
      t.string :label, :null => false
      t.string :grouped_type, :null => false
      t.belongs_to :site, :null => false
      t.belongs_to :parent
      t.integer :position, :default => 0
      t.string :description, limit: 2048
      t.text :presets, limit: 3064
      t.integer :children_count
    end

    change_table :cms_files do |t|
      t.belongs_to :group
    end

    change_table :cms_snippets do |t|
      t.belongs_to :group
    end

    reversible do |db|
      db.up do
        Cms::Site.all.each do |site|
          Cms::Group::GROUPABLES.each do |type|
            group = site.groups.create({ label: 'Default',grouped_type: type })
            type.constantize.where(site_id: site.id).each do |item|
              item.update_attribute :group_id, group.id
            end
          end
        end
      end
      db.down do
        # nothing - the tables & columns are getting removed
      end
    end
  end

end
