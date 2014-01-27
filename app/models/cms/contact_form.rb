class Cms::ContactForm < ActiveRecord::Base
  include Cms::Base

  belongs_to :site
  belongs_to :contact_form, class_name: 'Cms::ContactForm'
  has_many :contact_forms, class_name: 'Cms::ContactForm'
  has_many :contacts, class_name: 'Cms::Contact'

  def contact_fields
    YAML.load(read_attribute(:contact_fields) || '') || []
  end

  def contact_fields=(fields)
    field_array = case fields
                    when String
                      fields.split(/\s+/)
                    else
                      fields
                  end
    write_attribute :contact_fields, field_array.to_yaml
  end

  def build_contact(field_values={})
    contact = self.contacts.new
    contact.contact_form = self
    contact.send(:contact_fields=, field_values)
    contact
  end

end