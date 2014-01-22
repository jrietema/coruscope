class Cms::Snippet < ActiveRecord::Base
  include Cms::Base

  cms_is_categorized
  cms_is_mirrored
  cms_has_revisions_for :content

  # -- Relationships --------------------------------------------------------
  belongs_to :site

  belongs_to :group,
             inverse_of: :items

  # -- Callbacks ------------------------------------------------------------
  before_validation :assign_label
  before_create :assign_position,
                :assign_group_id
  after_save    :clear_cached_page_content
  after_destroy :clear_cached_page_content

  # -- Validations ----------------------------------------------------------
  validates :site_id,
            :presence   => true
  validates :label,
            :presence   => true
  validates :identifier,
            :presence   => true,
            :uniqueness => { :scope => :site_id },
            :format     => { :with => /\A\w[a-z0-9_-]*\z/i }

  validates_inclusion_of :site_id,
            if: ->(i) { !i.group.nil? },
            in: ->(i) { [i.group.site_id] }

  # -- Scopes ---------------------------------------------------------------
  default_scope -> { order('cms_snippets.position') }

  protected

  def assign_label
    self.label = self.label.blank?? self.identifier.try(:titleize) : self.label
  end

  def clear_cached_page_content
    Cms::Page.where(:id => site.pages.pluck(:id)).update_all(:content => nil)
  end

  def assign_position
    max = self.site.snippets.maximum(:position)
    self.position = max ? max + 1 : 0
  end

  def assign_group_id
    if self.group_id.nil?
      self.group_id = site.groups.snippets.root.first.id
    end
  end

end
