class Cms::ContactsController < Cms::BaseController

  before_action :load_contact_form, :only => :create
  before_action :build_contact, :only => :create

  # This controller only handles create actions = contact_form submissions
  def create
    if @cms_form.contact_form.nil?
      # don't render a second-stage form on success and save the contact
      if @contact.save
        Cms::ContactMailer.contact_mail(@contact, @cms_form.site.mirrors.first.locale).deliver
        render_success
      else
        re_render_form
      end
    else
      # perform a validation and re-render or pass on to second form stage
      if @contact.valid?
        render_followup_form
      else
        re_render_form
      end
    end
  end

  protected

  def re_render_form
    respond_to do |format|
      format.html do
        # render the referring page
        @referring_page = params['referring_page'] unless params['referring_page'].blank?
        @referring_page ||= Rails.application.routes.recognize_path(request.env['HTTP_REFERER'])[:cms_path]
        redirect_url = reconstruct_page_path(@referring_page) + "##{@cms_form.identifier}-wrapper"
        redirect_to [redirect_url, serialize_contact_parameters].select{|e|!e.blank?}.join("?")
      end
      format.js do
        # update the form on the page
        render :template => :create_fails, :layout => false
      end
    end
  end

  def render_success
    # redirect to form's redirect_url
    respond_to do |format|
      redirect_url = reconstruct_page_path(@cms_form.redirect_url(@cms_site))
      format.html do
        redirect_to redirect_url
      end
      format.js do
        render :inline => "$(document).href = '#{redirect_url}'"
      end
    end
  end

  def render_followup_form
    # redirect to the page containing the form (given by the redirect url)
    path = @cms_form.redirect_url(@cms_site)
    path = File.join(@cms_site.path, path) unless path.start_with?(@cms_site.path, "/#{@cms_site.path}")
    redirect_to "/#{path.sub(/^\/+/,'')}?#{serialize_contact_params}##{path.split('/').last.concat('-wrapper')}"
  end

  def load_contact_form
    @cms_form = @cms_site.mirrors.map{|s| s.contact_forms.where(id: params['contact_form_id'])}.flatten.compact.first
  end

  def build_contact
    @contact = @cms_form.build_contact(contact_params)
  end

  def reconstruct_page_path(slug)
    tokens = slug.sub(/\A\//,'').split('#')
    path = tokens.shift
    path = File.join(@cms_site.path, path) unless path.start_with?(@cms_site.path, "/#{@cms_site.path}")
    url = cms_render_page_path(:cms_path => path.split('/').compact)
    unless tokens.empty?
      url << "##{tokens[1]}"
    end
    url.gsub(/\/+/,'/')
  end

  def serialize_contact_params
    {:contact => contact_params}.to_query
  end

  private

  def contact_params
    @contact_params = params.require(:contact).permit(@cms_site.mirrors.select{|s| !s.contact_fields.blank? }.first.try(:contact_fields)) || {}
  end

end