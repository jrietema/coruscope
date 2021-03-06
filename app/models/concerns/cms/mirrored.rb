module Cms::Mirrored
  extend ActiveSupport::Concern

  included do
    attr_accessor :is_mirrored

    after_save    :sync_mirror
    after_destroy :destroy_mirror
  end

  # Mirrors of the object found on other sites
  def mirrors
    return [] unless self.site.is_mirrored?
    (self.site.mirrors - [self.site]).collect do |site|
      case self
        when Cms::Layout  then site.layouts.find_by_identifier(self.identifier)
        when Cms::Page    then site.pages.find_by_identifier(self.identifier)
        when Cms::Snippet then site.snippets.find_by_identifier(self.identifier)
        when Cms::Group   then site.groups.find_by_label_and_grouped_type(self.label, self.grouped_type)
      end
    end.compact
  end

  # Creating or updating a mirror object. Relationships are mirrored
  # but content is unique. When updating need to grab mirrors based on
  # self.slug_was, new objects will use self.slug.
  def sync_mirror
    return if self.is_mirrored || !self.site.is_mirrored?

    (Cms::Site.mirrored - [self.site]).each do |site|
      mirror = case self
                 when Cms::Layout
                   m = site.layouts.find_by_identifier(self.identifier_was || self.identifier) || site.layouts.new
                   attr = {
                       :identifier => self.identifier,
                       :label => self.label,
                       :app_layout => self.app_layout,
                       :parent_id  => site.layouts.find_by_identifier(self.parent.try(:identifier)).try(:id)
                   }
                   if m.new_record?
                     attr.merge!({
                                     :content => self.content,
                                     :css => self.css,
                                     :js => self.js,
                                     :is_shared => self.is_shared
                                 })
                   end
                   m.attributes = attr
                   m
                 when Cms::Page
                   m = site.pages.find_by_identifier(self.identifier) || site.pages.new
                   attr = {
                       :parent_id  => site.pages.find_by_identifier(self.parent.try(:identifier)).try(:id),
                       :render_as_page => m.render_as_page
                   }
                   if m.new_record?
                     attr.merge!({
                                     :label      => m.label.blank?? self.label : m.label,
                                     :identifier => m.identifier,
                                     :slug       => self.slug,
                                     :layout     => site.layouts.find_by_identifier(self.layout.try(:identifier)),
                                     :is_published => false
                                 })
                   end
                   m.attributes = attr
                   m
                 when Cms::Snippet
                   m = site.snippets.find_by_identifier(self.identifier_was || self.identifier) || site.snippets.new
                   attr = {
                       :identifier => self.identifier,
                       :label => self.label,
                       :group_id => site.groups.find_by_label(self.group.try(:label)).try(:id)
                   }
                   if m.new_record?
                     attr.merge!({
                                     :content => self.content,
                                     :is_shared => self.is_shared
                                 })
                   end
                   m.attributes = attr
                   m
                 when Cms::Group
                   if self.grouped_type == 'Cms::Snippet'
                     m = site.groups.find_by_label_and_grouped_type(self.label_was || self.label, self.grouped_type) || site.groups.new
                     attr = {
                         :grouped_type => self.grouped_type,
                         :label => self.label,
                     }
                     if m.new_record?
                       attr.merge!({
                                       :parent_id => site.groups.find_by_label_and_grouped_type(self.parent.try(:label), self.grouped_type).try(:id)
                                   })
                     end
                     m.attributes = attr
                     m
                   else
                     nil
                   end
               end
      return if mirror.nil? # File Groups don't get mirrored
      mirror.is_mirrored = true
      begin
        copy_blocks = mirror.is_a?(Cms::Page) && mirror.new_record?
        mirror.save!
        if copy_blocks
          self.blocks.each do |block|
            mirror_block = mirror.blocks.build({
                                                   :identifier => block.identifier,
                                                   :content => block.content
                                               })
            mirror_block.save
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        logger.error(e.message)
        e.backtrace.each{|line| logger.error(line) }
      end
    end
  end

  # Mirrors should be destroyed
  def destroy_mirror
    return if self.is_mirrored || !self.site.is_mirrored?
    mirrors.each do |mirror|
      mirror.is_mirrored = true
      mirror.destroy
    end
  end

end