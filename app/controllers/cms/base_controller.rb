class Cms::BaseController < ApplicationController

  before_action :load_cms_site

  protected

  # This method has many problems...
  # Requests either have to
  #   a) provide a site_id  - OR -
  #   b) utilize the host name and the site path configured for the site
  #
  # This doesn't seem to be the case with some technical direct-access
  # routes for assets (javascript/css/images), files, and the
  # contact form features
  def load_cms_site
    @cms_site ||= if params[:site_id]
                    ::Cms::Site.find_by_id(params[:site_id])
                  else
                    ::Cms::Site.find_site(request.host_with_port.downcase, request.fullpath)
                  end

    if @cms_site
      if @cms_site.path.present?
        unless %w(assets files contacts).include?(controller_name)
          if params[:cms_path] && params[:cms_path].match(/\A#{@cms_site.path}/)
            params[:cms_path].gsub!(/\A#{@cms_site.path}/, '')
            params[:cms_path] && params[:cms_path].gsub!(/\A\//, '')
          else
            raise ActionController::RoutingError.new('Site Not Found')
          end
        end
      end
      I18n.locale = @cms_site.locale
    else
      I18n.locale = I18n.default_locale
      raise ActionController::RoutingError.new('Site Not Found')
    end
  end

end