class Cms::AssetsController < Cms::BaseController
  before_action :load_cms_layout

  def render_css
    # avoid multiple retrieval due to several on-page web editors
    response.headers['Cache-Control'] = 'max-age=60, must-revalidate'
    render :text => @cms_layout.css, :content_type => 'text/css'
  end

  def render_js
    render :text => @cms_layout.js, :content_type => 'text/javascript'
  end

  protected

  def load_cms_layout
    @cms_layout = @cms_site.layouts.find_by_identifier!(params[:identifier])
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => 404
  end
end