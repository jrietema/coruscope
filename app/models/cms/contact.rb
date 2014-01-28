class Cms::Contact < ActiveRecord::Base
  include Cms::Base

  belongs_to :site
  belongs_to :contact_form

  before_validation :set_email_from_contact_field,
                    :set_message_body_from_contact_fields

  validate :contact_field_validation
  validates :contact_form_id,
            :presence => true
  validates_associated :contact_form
=begin
  # leave this to JS validation for now
  validates :email,
            :presence => true,
            :format => /\A[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\z/i
=end

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

  def set_message_body_from_contact_fields
    body = ''
    contact_form.contact_field_options.keys.each do |field|
      next unless contact_form.contact_field_options[field]['body']
      body << "<p>#{getFieldValue(field)}</p>"
    end
    body
  end

  protected

  def set_email_from_contact_field
    self.email = getFieldValue('email')
  end

  private

  # currently validates:
  # - presence of mandatory contact fields
  def contact_field_validation
    field_definitions = self.contact_form.contact_field_options
    field_definitions.keys.each do |field|
      next unless field_definitions[field][:mandatory]
      if contact_fields[field].blank?
        self.errors.add(field.to_sym, :required_field)
      end
    end
  end

  # accessors to contact fields
  def method_missing(method_name, *args)
    # attempt to get a field value
    if(!contact_form.nil? && contact_form.contact_fields.include?(method_name.to_s))
      return getFieldValue(method_name.to_s)
    elsif (!contact_form.nil?) && contact_form.contact_fields.map{|f| "#{f.to_s}=" }.include?(method_name.to_s)
      setFieldValue(method_name.to_s.sub('=',''), args.first)
    else
      super(method_name, *args)
    end
  end
end