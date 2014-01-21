class AddPageNavigationRootId < ActiveRecord::Migration
  def change
    change_table :cms_pages do |t|
      t.integer :navigation_root_id, :null => false
      t.boolean :render_as_page, :default => true
    end

    reversible do |db|
      db.up do
        Cms::Page.all.each do |page|
          page.navigation_root_id = page.site.pages.root.id
          page.save
        end
      end
      db.down do
        # nothing
      end
    end
  end
end
