class Cms::Contact < ActiveRecord::Base
  include Cms::Base

  belongs_to :site
  belongs_to :contact_form

  def getFieldValue(field)
    if contact_form.contact_fields.include?(field.to_s)
      contact_fields[field.to_sym] || nil
    end
  end

  def setFieldValue(field, value)
    value_hash = contact_fields
    value_hash[field.to_sym] = value
    contact_fields = value_hash
  end

  protected

  def contact_fields
    @fields ||= (YAML.load(read_attribute(:contact_fields) || '')) || {}
    @fields.symbolize_keys! unless @fields.empty?
    @fields
  end

  def contact_fields=(value_hash)
    # don't store an ActiveRecord::Parameters instance
    fields = {}
    value_hash.keys.each do |field|
      fields[field] = value_hash[field]
    end
    write_attribute(:contact_fields, fields.to_yaml)
  end

  private

  def method_missing(method_name, *args)
    # attempt to get a field value
    if(!contact_form.nil? && contact_form.contact_fields.include?(method_name.to_s))
      return getFieldValue(args.first)
    else
      super(method_name, *args)
    end
  end
end