class Admin::Cms::GroupsController < Admin::Cms::BaseController

  before_action :build_group, :only => [:new, :create]
  before_action :load_group, :only => [:edit, :update, :destroy]

  def files
    mirrored_site_ids
    @items = Cms::File.includes(:categories).for_category(params[:category]).where(['site_id IN (?)', @site_ids]).order('cms_files.position').group_by(&:group_id)
    groups_by_parent('Cms::File')
    render :action => :index, :layout => false
  end

  def snippets
    @site_ids = [@site.id]
    @items = @site.snippets.includes(:categories).for_category(params[:category]).order('cms_snippets.position').group_by(&:group_id)
    groups_by_parent('Cms::Snippet')
    logger.info("@@@ SNIPPET GROUPS: #{@groups.inspect}")
    render :action => :snippets, :layout => false
  end

  def images
    mirrored_site_ids
    @items = Cms::File.includes(:categories).for_category(params[:category]).where(["file_content_type LIKE 'image%' AND site_id IN (?)", @site_ids]).order('cms_files.position').group_by(&:group_id)
    groups_by_parent('Cms::File')
    render :template => '/admin/cms/groups/images', :layout => false
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

  def mirrored_site_ids
    @site_ids = (@site.mirrors).uniq.map(&:id)
  end

  def groups_by_parent(type)
    @groups = Cms::Group.where(['grouped_type = ? AND site_id IN (?)', type, @site_ids]).group_by(&:parent_id)
  end

  def build_group
    type = params[:grouped_type]
    case type
      when 'Cms::Snippet'
        # create to this site
        default = @site.groups.where(grouped_type: type).first
        @group = @site.groups.build({grouped_type: type, parent_id: default.nil? ? nil : default.id })
      else
        # create on the original mirror
        default = @site.original_mirror.groups.where(grouped_type: type).first
        @group = @site.original_mirror.groups.build({grouped_type: type, parent_id: default.nil? ? nil : default.id })
    end
    @group.attributes = group_params
  end

  def load_group
    @group = Cms::Group.where(['id = ? AND site_id IN (?)', params[:id], @site.mirrors.map(&:id)]).first
  end

  def group_params
    params.fetch(:group, {}).permit!
  end

end