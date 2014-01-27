class AddContactFieldOptionsToContactForm < ActiveRecord::Migration

  def change
    change_table :cms_contact_forms do |t|
      t.text :contact_field_options
      t.text :contact_field_translations
    end
  end

end
