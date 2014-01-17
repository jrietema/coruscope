class Admin::Cms::GroupsController < Admin::Cms::BaseController

  before_action :build_group, :only => [:new, :create]
  before_action :load_group, :only => [:edit, :update, :destroy]

  def files
    @items = @site.files.includes(:categories).for_category(params[:category]).order('cms_files.position').group_by(&:group_id)
    groups_by_parent('Cms::File')
    render :action => :index, :layout => false
  end

  def snippets
    @items = @site.snippets.includes(:categories).for_category(params[:category]).order('cms_snippets.position').group_by(&:group_id)
    groups_by_parent('Cms::Snippet')
    render :action => :index, :layout => false
  end

  def new
    render
  end

  def edit
    render
  end

  def create
    @group.save!
    flash[:success] = I18n.t('cms.groups.created')
    redirect_to :action => :edit, :id => @group.id
  rescue ActiveRecord::RecordInvalid
    flash.now[:error] = I18n.t('cms.groups.creation_failure')
    render :action => :new
  end

  def update
    @group.update_attributes!(group_params)
    flash[:success] = I18n.t('cms.groups.updated')
    redirect_to :action => :edit, :id => @group.id
  rescue ActiveRecord::RecordInvalid
    flash.now[:error] = I18n.t('cms.groups.update_failure')
    render :action => :edit
  end

  def destroy
    @group.destroy
    flash[:success] = I18n.t('cms.groups.deleted')
    redirect_to eval("admin_cms_site_#{@group.grouped_type.underscore.split('/').pluralize}_url")
  end

  protected

  def groups_by_parent(type)
    @groups = @site.groups.where(grouped_type: type).group_by(&:parent_id)
  end

  def build_group
    type = params[:grouped_type]
    default = @site.groups.where(grouped_type: type).first
    @group = @site.groups.build({grouped_type: type, parent_id: default.nil? ? nil : default.id })
    @group.attributes = group_params
  end

  def load_group
    @group = @site.groups.find(params[:id])
  end

  def group_params
    params.fetch(:group, {}).permit!
  end

end