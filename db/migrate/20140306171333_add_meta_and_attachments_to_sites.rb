class AddMetaAndAttachmentsToSites < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        add_attachment :cms_sites, :favicon
        add_attachment :cms_sites, :identity_image
        add_column :cms_sites, :description, :text
        add_column :cms_sites, :keywords, :string
        add_column :cms_sites, :meta_tags, :text
      end
      dir.down do
        remove_attachment :cms_sites, :favicon
        remove_attachment :cms_sites, :identity_image
        remove_column :cms_sites, :description
        remove_column :cms_sites, :keywords
        remove_column :cms_sites, :meta_tags
      end
    end
  end
end
