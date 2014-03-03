class AddPagesIdentifier < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        add_column :cms_pages, :identifier, :string
        Cms::Page.all.find_each do |page|
          page.identifier = page.send(:assign_identifier)
          page.save
        end
        change_column :cms_pages, :identifier, :string, :null => false
        add_index :cms_pages, [:site_id, :identifier]
      end
      dir.down do
        remove_column :cms_pages, :identifier
      end
    end
  end
end
