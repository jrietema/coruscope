class ExpandContactFields < ActiveRecord::Migration

  def change
    reversible do |dir|
      dir.up do
        change_column :cms_sites, :contact_fields, :string, {limit: 600}
        change_column :cms_contact_forms, :contact_fields, :string, {limit: 600}
      end
      dir.down do
        change_column :cms_sites, :contact_fields, :string
        change_column :cms_contact_forms, :contact_fields, :string
      end
    end
  end

end
