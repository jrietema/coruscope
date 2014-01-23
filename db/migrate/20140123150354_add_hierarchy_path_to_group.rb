class AddHierarchyPathToGroup < ActiveRecord::Migration

  def change
    change_table :cms_groups do |t|
      t.string :hierarchy_path
    end

    reversible do |db|
      db.up do
        Cms::Group.all.each do |group|
          # saving again should auto-assign the hierarchy_path
          group.save
        end
      end
      db.down do
        # nothing
      end
    end
  end

end
