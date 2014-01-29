class Cms::ContactForm < ActiveRecord::Base
  include Cms::Base

  belongs_to :site
  belongs_to :contact_form, class_name: 'Cms::ContactForm'
  has_many :contact_forms, class_name: 'Cms::ContactForm'
  has_many :contacts, class_name: 'Cms::Contact'

  def contact_field_names
    contact_fields.flatten
  end

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

  def contact_field_options_for(field)
    contact_field_options[field]
  end

  def contact_field_options
    @options ||= begin
      options = {}
      form_overrides = YAML.load(read_attribute(:contact_field_options) || '') || {}
      site.contact_field_definitions.each do |field, value|
        options[field] = value.merge(form_overrides[field] || {})
      end
      options
    end
  end

  def contact_field_options=(options)
    site_options = site.contact_field_definitions
    site_options.keys.each do |field|
      options.delete(field) if site_options[field] == options[field]
    end
    write_attribute :contact_field_options, options.to_yaml
  end

  def contact_field_translations
    @translations ||= site.contact_field_translations.merge(YAML.load(read_attribute(:contact_field_translations) || '') || {})
  end

  def contact_field_translations=(translations)
    site_translations = site.contact_field_translations
    site_translations.keys.each do |field|
      translations.delete(field) if site_translations[field] == translations[field]
    end
    write_attribute :contact_field_translations, translations.to_yaml
  end

  def redirect_url
    ['', read_attribute(:redirect_url).split('/')].flatten.join('/').gsub(/\/+/,'/')
  end

  def build_contact(field_values={})
    contact = self.contacts.new
    contact.contact_form = self
    contact.send(:contact_fields=, field_values)
    contact
  end

end