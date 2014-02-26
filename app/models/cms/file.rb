class Cms::File < ActiveRecord::Base
  include Cms::Base
  translates :description
  globalize_accessors

  IMAGE_MIMETYPES = %w(gif jpeg pjpeg png tiff).collect{|subtype| "image/#{subtype}"}

  cms_is_categorized

  attr_accessor :dimensions

  has_attached_file :file, ComfortableMexicanSofa.config.upload_file_options.merge(
      # dimensions accessor needs to be set before file assignment for this to work
      :styles => lambda { |f|
        if f.respond_to?(:instance) && f.instance.respond_to?(:dimensions)
          (f.instance.dimensions.blank?? { } : { :original => f.instance.dimensions }).merge(
              :cms_thumb => '80x60#',
              :resized => '640x480',
              :mini => '40x30#'
          )
        end
      },
      :path => ':rails_root/public/assets/sites/:site_id/:class/:id/:basename.:style.:extension',
      :url => '/assets/sites/:site_id/:class/:id/:basename.:style.:extension'
  )
  before_post_process :is_image?

  # -- Relationships --------------------------------------------------------
  belongs_to :site
  belongs_to :block

  belongs_to :group,
             inverse_of: :files

  # -- Validations ----------------------------------------------------------
  validates :site_id,
            :presence   => true
  validates_attachment_presence :file
  validates :file_file_name,
            :uniqueness => {:scope => :site_id}

  validates_inclusion_of :site_id,
            if: ->(i) { !i.group.nil? },
            in: ->(i) { [i.group.site_id] }

  # -- Callbacks ------------------------------------------------------------
  before_save   :assign_label
  before_create :assign_position,
                :assign_group_id
  after_save    :reload_page_cache
  after_destroy :reload_page_cache

  # -- Scopes ---------------------------------------------------------------
  default_scope       -> { order 'position ASC, label ASC'}
  scope :images,      -> { where(:file_content_type => IMAGE_MIMETYPES) }
  scope :not_images,  -> { where('file_content_type NOT IN (?)', IMAGE_MIMETYPES) }

  # -- Instance Methods -----------------------------------------------------
  def is_image?
    IMAGE_MIMETYPES.include?(file_content_type)
  end

  # path within the group hierarchy - this is needed for adressing
  # the image for cms layout helper calls
  def cms_path
    [group.hierarchy_path, self.label].select{|p| !p.blank?}.join('/')
  end

  protected

  def assign_label
    self.label = self.label.blank?? self.file_file_name.gsub(/\.[^\.]*?$/, '').titleize : self.label
  end

  def assign_position
    max = Cms::File.maximum(:position)
    self.position = max ? max + 1 : 0
  end

  def assign_group_id
    if self.group_id.nil? && !site.groups.files.empty?
      self.group_id = site.groups.files.root.first.id
    end
  end

  def reload_page_cache
    return unless self.block
    p = self.block.page
    Cms::Page.where(:id => p.id).update_all(:content => nil)
  end

  private

  Paperclip.interpolates :site_id do |file, style|
    file.instance.site.path.split('/').first || 'sites'
  end

end
