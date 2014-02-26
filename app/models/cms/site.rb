class Cms::Site < ActiveRecord::Base
  include Cms::Base

  # -- Relationships --------------------------------------------------------
  with_options :dependent => :destroy do |site|
    site.has_many :layouts
    site.has_many :pages
    site.has_many :snippets
    site.has_many :files
    site.has_many :categories
    site.has_many :groups, class_name: 'Cms::Group'
    site.has_many :contact_forms, class_name: 'Cms::ContactForm'
    site.has_many :contact, class_name: 'Cms::Contact'
  end

  has_many :file_groups,
           -> { where(grouped_type: 'Cms::File') },
           class_name: 'Cms::Group'
  has_many :snippet_groups,
           -> { where(grouped_type: 'Cms::Snippet')},
           class_name: 'Cms::Snippet'


  # -- Callbacks ------------------------------------------------------------
  before_validation :assign_identifier,
                    :assign_hostname,
                    :assign_label
  before_save :clean_path
  after_save  :sync_mirrors

  # -- Validations ----------------------------------------------------------
  validates :identifier,
            :presence   => true,
            :uniqueness => true,
            :format     => { :with => /\A\w[a-z0-9_-]*\z/i }
  validates :label,
            :presence   => true
  validates :hostname,
            :presence   => true,
            :uniqueness => { :scope => :path },
            :format     => { :with => /\A[\w\.\-]+(?:\:\d+)?\z/ }

  # -- Scopes ---------------------------------------------------------------
  scope :mirrored, -> { where(:is_mirrored => true) }

  # -- Class Methods --------------------------------------------------------
  # returning the Cms::Site instance based on host and path
  def self.find_site(host, path = nil)
    return Cms::Site.first if Cms::Site.count == 1
    cms_site = nil
    Cms::Site.where(:hostname => real_host_from_aliases(host)).each do |site|
      if site.path.blank?
        cms_site = site
      elsif "#{path.to_s.split('?')[0]}/".match /^\/#{Regexp.escape(site.path.to_s)}\//
        cms_site = site
        break
      end
    end
    return cms_site
  end

  # -- Instance Methods -----------------------------------------------------
  # When removing entire site, let's not destroy content from other sites
  # Since before_destroy doesn't really work, this does the trick
  def destroy
    self.class.where(:id => self.id).update_all(:is_mirrored => false) if self.is_mirrored?
    super
  end

  def mirrors
    if is_mirrored
      Cms::Site.mirrored
    else
      [self]
    end
  end

  def original_mirror
    if is_mirrored
      Cms::Site.mirrored.first
    else
      self
    end
  end

  # file groups from all mirrors
  def file_group_by_hierarchy_path(path)
    self.mirrors.map{|s| s.groups.files.where(hierarchy_path: path) }.flatten.first
  end

  def contact_fields
    @contact_fields ||= YAML.load(read_attribute(:contact_fields) || '') || []
  end

  # Names of contact fields for translation
  def contact_field_name(contact_field)
    contact_field_translations[contact_field]
  end

  # Types and other options for contact fields
  # Options include:
  # - mandatory: this field cannot be left blank
  # - options: options for select
  # - width/height: dimensions of the field
  # - acceptance: this fields needs to be true
  # - link_url: info link url
  def contact_field_options(contact_field)
    contact_field_definitions[contact_field]
  end

  def contact_field_definitions
    @contact_field_definitions ||= YAML.load(read_attribute(:contact_field_definitions) || '') || {}
  end

  def contact_field_definitions=(defs)
    write_attribute(:contact_field_definitions, defs.to_yaml)
  end

  def contact_field_translations
    @contact_field_translations ||= YAML.load(read_attribute(:contact_field_translations) || '') || {}
  end

  def contact_field_translations=(defs)
    write_attribute(:contact_field_translations, defs.to_yaml)
  end

  def contact_form_wrap_tag
    contact_field_definitions['wrap_tag']
  end

  def css_framework
    'Gumby'
  end

  protected

  def self.real_host_from_aliases(host)
    if aliases = ComfortableMexicanSofa.config.hostname_aliases
      aliases.each do |alias_host, aliases|
        return alias_host if aliases.include?(host)
      end
    end
    host
  end

  def assign_identifier
    self.identifier = self.identifier.blank?? self.hostname.try(:slugify) : self.identifier
  end

  def assign_hostname
    self.hostname ||= self.identifier
  end

  def assign_label
    self.label = self.label.blank?? self.identifier.try(:titleize) : self.label
  end

  def clean_path
    self.path ||= ''
    self.path.squeeze!('/')
    self.path.gsub!(/\/$/, '')
  end

  # When site is marked as a mirror we need to sync its structure
  # with other mirrors.
  def sync_mirrors
    # create a Default Snippet Group
    self.groups.create({ label: 'Default', grouped_type: 'Cms::Snippet' })

    return unless is_mirrored_changed? && is_mirrored?

    [self, Cms::Site.mirrored.where("id != #{id}").first].compact.each do |site|
      (site.layouts(:reload).roots + site.layouts.roots.map(&:descendants)).flatten.map(&:sync_mirror)
      (site.pages(:reload).roots + site.pages.roots.map(&:descendants)).flatten.map(&:sync_mirror)
      site.groups(:reload).snippets.map(&:sync_mirror)
      site.snippets(:reload).map(&:sync_mirror)
    end

    # set all pages as navigation_root that don't have navigation_root and parent_root set
    # this enables the navigations on new mirrored sites
    self.pages.where(parent_id: nil, navigation_root_id: nil).each do |page|
      page.update_attribute(:navigation_root_id, page.id)
    end
  end

end