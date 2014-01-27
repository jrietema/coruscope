class Cms::ContactsController < Cms::BaseController

  before_action :load_contact_form, :only => :create
  before_action :build_contact, :only => :create

  # This controller only handles create actions = contact_form submissions
  def create
    unless @contact.valid?

    end

  end

  protected

  def load_contact_form
    @cms_form = @cms_site.contact_forms.select(id: params['contact_form_id']).first
  end

  def build_contact
    @contact = Cms::Contact.new(params['contact'])
  end
end