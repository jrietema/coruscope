# This class can be used to group cms content (files, snippets esp)
# within a hierarchical tree. It has no layout purposes, but for images
# it can hold resizing/cropping configurations.
class Cms::Group < ActiveRecord::Base
  include Cms::Base
  include Cms::Mirrored

  GROUPABLES = %w(Cms::Snippet Cms::File)

  cms_acts_as_tree :counter_cache => :children_count
  cms_is_categorized

  # -- Relationships --------------------------------------------------------
  belongs_to :site
  has_many :files,
           class_name: 'Cms::File'
  has_many :snippets,
           class_name: 'Cms::Snippet'

  # -- Callbacks ------------------------------------------------------------
  before_create     :assign_position
  before_save       :assign_hierarchy_path

  # -- Validations ----------------------------------------------------------
  validates :site_id,
            presence: true
  validates :label,
            presence: true
  validates :label,
            uniqueness: { scope: :parent_id }
  validates :grouped_type,
            inclusion: GROUPABLES

  # -- Scopes ---------------------------------------------------------------
  default_scope -> { order('cms_groups.position') }
  scope :root, -> { where(parent_id: nil) }
  scope :files, -> { where(grouped_type: 'Cms::File') }
  scope :snippets, -> { where(grouped_type: 'Cms::Snippet') }

  protected

  def assign_position
    return unless self.parent
    return if self.position.to_i > 0
    max = self.parent.children.maximum(:position)
    self.position = max ? max + 1 : 0
  end

  def assign_hierarchy_path
    hierarchy = []
    group = self
    # stop before reaching the default group with parent_id=nil
    while !group.nil? && !group.parent_id.nil?
      hierarchy << group.label.strip
      group = group.parent
    end
    self.hierarchy_path = hierarchy.reverse.join('/')
  end

end