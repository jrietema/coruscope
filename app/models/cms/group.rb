# This class can be used to group cms content (files, snippets esp)
# within a hierarchical tree. It has no layout purposes, but for images
# it can hold resizing/cropping configurations.
class Cms::Group < ActiveRecord::Base
  include Cms::Base

  GROUPABLES = %w(Cms::Snippet Cms::File)

  cms_acts_as_tree :counter_cache => :children_count
  cms_is_categorized

  # -- Relationships --------------------------------------------------------
  belongs_to :site
  has_many :items,
           -> { order 'position ASC, label ASC'},
           class_name: -> (i) { i.grouped_type }

  # -- Callbacks ------------------------------------------------------------
  before_create     :assign_position

  # -- Validations ----------------------------------------------------------
  validates :site_id,
            presence: true
  validates :label,
            presence: true
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

end