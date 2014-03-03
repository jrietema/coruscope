class AddPagesIdentifier < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        add_column :cms_pages, :identifier, :string
        Cms::Page.all.find_each do |page|
          page.send(:assign_identifier)
          page.save
        end
        change_column :cms_pages, :identifier, :string, :null => false
        begin
          add_index :cms_pages, column: [:site_id, :identifier]
        rescue
        end
      end
      dir.down do
        begin
          remove_index :cms_pages, column: [:site_id, :identifier]
        rescue
        end
        remove_column :cms_pages, :identifier
      end
    end
  end
end
