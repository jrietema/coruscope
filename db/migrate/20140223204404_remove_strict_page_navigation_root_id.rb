class RemoveStrictPageNavigationRootId < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        change_column :cms_pages, :navigation_root_id, :integer, {null: true}
      end
      dir.down do
        change_column :cms_pages, :navigation_root_id, :integer, {null: false}
      end
    end
  end
end
