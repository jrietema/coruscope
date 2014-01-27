class AddContactDefinitionsToSite < ActiveRecord::Migration

  def change
    change_table :cms_sites do |t|
      t.string  :contact_fields
      t.text    :contact_field_translations
      t.text    :contact_field_definitions
      t.string  :default_addressee
    end

    create_table :cms_contact_forms do |t|
      t.belongs_to  :site, :null => false
      t.string  :identifier, :null => false
      t.string  :contact_fields
      t.string  :addressee
      t.string  :mailer_subject
      t.string  :submit_label
      t.string  :redirect_url, :null => false
      t.text  :mailer_body
      t.belongs_to  :contact_form
    end

    create_table :cms_contacts do |t|
      t.belongs_to :site
      t.belongs_to :contact_form
      t.datetime  :created_at
      t.string  :email
      t.string  :contact_type
      t.text  :contact_fields
      t.text  :message_body
    end
  end

end
