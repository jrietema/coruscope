module ApplicationHelper
  # Help build gumby forms

  def page_path(page, include_site=true)
    site_path = page.site.path
    path_elems = [page.slug.to_s]
    while !page.parent.nil?
      page = page.parent
      path_elems << page.slug.to_s
    end
    if include_site && page.site.render_site_path
      File.join('/', site_path, path_elems.reverse.compact)
    else
      File.join('/', path_elems.reverse.compact).gsub('//','/')
    end
  end

  # path to static assets for cms site
  def cms_site_asset_path(site, relpath='assets')
    relpath = relpath.split('/')
    prefix = relpath.shift
    File.join('/', prefix, cms_site_handle(site), relpath.join('/'))
  end

  def cms_site_handle(site)
    site.path.split('/').first
  end

  # this is a helper to retrieve related page's content in layouts/snippets
  def page_content_for(slug, identifier)
    page = @cms_site.pages.find_by_slug(identifier.to_s)
    return '' if page.nil?
    block = page.blocks.find_by_identifier(identifier)
    return '' if block.nil?
    return block.inspect
    case block.tag
      # This just handles very simple text content atm
      when ComfortableMexicanSofa::Tag::PageFile
        ''
      when ComfortableMexicanSofa::Tag::PageFiles
        ''
      else
        ComfortableMexicanSofa::Tag.sanitize_irb(block.content)
    end
  end

  # returns an array of page objects or properies of pages of hierarchical relationships
  def breadcrumbs(page, method=nil)
    crumbs = []
    while !page.nil?
      crumbs << (method ? page.send(method) : page)
      page = page.parent
      return (crumbs << page.site.pages.root) if !page.nil? && page.is_leaf_node # don't add leaf_node parents to breadcrumbs
    end
    crumbs
  end

  # checkbox with label included, Gumby-style
  def gumby_checkbox(form_builder, method, label, checked=false, value="1")
    name = "#{form_builder.object.class.name.underscore}[#{method}]"
    checkbox = check_box_tag(name, value, checked) + content_tag(:span) + ' ' + label.to_s
    html = label_tag(name, checkbox, :class => "checkbox#{checked ? ' checked' : ''}")
    html + hidden_field_tag(name, (value.to_i == 0) ? '1' : '0', :id => nil)
  end

  def fancytree_pages_hash(pages, branch_id=nil, &labelling)
    item_model = pages[branch_id].first.class.name.underscore.split('/').last unless pages[branch_id].empty?
    labelling = ->(item) { fancytree_label_for(item) } unless block_given?
    pages[branch_id].map do |page|
      child_pages = pages[page.id] || []
      page_hash = { title: labelling.call(page), key: page.id, href: method("edit_admin_cms_site_#{item_model}_path".sub('site_site','site')).call({site_id: (@site.nil? ? nil : @site.id), id: page.id, format: :js}) }
      unless child_pages.empty?
        page_hash.merge!({ folder: true, children: fancytree_pages_hash(pages, page.id, &labelling)})
      end
      page_hash
    end
  end

  def fancytree_grouped_hash(groups, items, branch_id=nil, top_node=true, new_link=true, lazy=true, &labelling)
    # use the containing group to determine model type if this is empty
    model_group = groups[branch_id]
    model_group ||= groups[groups.select{|k,g| g.include?(branch_id)}.keys.first]
    item_model = model_group.first.grouped_type.underscore.split('/').last
    labelling = ->(item) { fancytree_label_for(item) } unless block_given?
    collection = groups[branch_id].nil? ? [] : groups[branch_id].map do |group|
      child_groups = groups[group.id] || []
      page_hash = { title: group.label, key: group.id, folder: true, href: method("edit_admin_cms_site_group_path".sub('site_site','site')).call({site_id: @site.id, id: group.id, format: :js}) }
      if lazy && !top_node
        if !(child_groups.empty? && (items[group.id] || []).empty?)
          # add lazy flag
          page_hash.merge!({lazy: true})
        end
      else
        # add child groups/folders
        child_contents = []
        unless child_groups.empty?
          child_contents = (fancytree_grouped_hash(groups, items, group.id, false, false, &labelling))
        end
        child_items = items[group.id] || []
        unless child_items.empty?
          child_items.each do |item|
            child_contents << { title: labelling.call(item), key: item.id, href: method("edit_admin_cms_site_#{item_model}_path".sub('site_site','site')).call({site_id: @site.id, id: item.id, format: :js})}
          end
        end
        page_hash.merge!({folder: true, children: child_contents})
      end
      if top_node
        # just return the children, skip the root node
        child_contents
      else
        # page and collection as children
        page_hash
      end
    end
    if top_node
      if new_link
        # add a link to add an item
        collection = collection.first # remove array nesting
        grouped_type = groups[branch_id].first.grouped_type.underscore.split('/').last
        html = link_to content_tag(:i, '', :class => 'icon-plus').concat(t(:new_link, :scope => 'admin.cms.groups')), eval("admin_cms_new_#{grouped_type}_group_path(site_id: #{@site.id})")
        collection << { title: html }
      end
    elsif !defined?(page_hash) && collection.empty?
      # this is a leaf node, we just return the child_items
      child_items = items[branch_id] || []
      unless child_items.empty?
        child_items.each do |item|
          collection << { title: labelling.call(item), key: item.id, href: method("edit_admin_cms_site_#{item_model}_path".sub('site_site','site')).call({site_id: @site.id, id: item.id, format: :js})}
        end
      end
    end
    collection
  end

  # simplify standard calls for grouped items
  def fancytree_group_select_hash(groups, items, labelling)
    fancytree_grouped_hash(groups, items, nil, true, true, &labelling)
  end

  def fancytree_label_for(item)
    case item
      when Cms::File # need not be an image!
        item.is_image? ? image_tag(item.file.url(:mini), class: :fullsize, alt: nil) + ' ' + item.label : item.label
      else
        item.label
    end
  end

  # any collection is transformed into a hash ordered by parent_id, for building fancytrees
  def collection_to_parent_id_ordered_hash(collection)
    hash = {}
    collection.inject(hash) do |hash, item|
      hash[item.parent_id] ||= []
      hash[item.parent_id] << item
      hash
    end
  end

  def options_for_page_select(site, from_page = nil, current_page = nil, depth = 0, exclude_self = true, spacer = ' -')
    current_page ||= site.pages.root
    return [] if (current_page == from_page && exclude_self) || !current_page
    out = []
    out << [ "#{spacer*depth}#{current_page.label}", current_page.id ] unless current_page == from_page
    child_pages = Cms::Page.all.where(parent_id: current_page.id, site_id: site.id)
    child_pages.each do |child|
      opt = options_for_page_select(site, from_page, child, depth + 1, exclude_self, spacer)
      out += opt
    end if child_pages.size.nonzero?
    return out.compact
  end

  def options_for_group_select(site, from=nil, type=nil, current=nil, depth=0, exclude_self=true, spacer=' -')
    type ||= from.grouped_type unless from.nil?
    return [] if type.nil?
    current ||= site.groups.root.where(grouped_type: type).first
    return [] if (current == from && exclude_self) || !current
    out = []
    label = current.parent_id.nil? ? t(:none, :scope => 'admin.cms.groups') : current.label
    out << [ "#{spacer*depth}#{label}", current.id ] unless current == from
    child_pages = Cms::Group.all.where(parent_id: current.id, site_id: site.id, grouped_type: type)
    child_pages.each do |child|
      opt = options_for_group_select(site, from, type, child, depth + 1, exclude_self, spacer)
      out += opt
    end if child_pages.size.nonzero?
    return out.compact
  end

  # much simpler call with defaults to options_for_group_select
  def simple_options_group_select_for(obj)
    options_for_group_select(obj.site || @site, nil, obj.class.name, nil, 0, false)
  end

  # hierarchical hash with group image contents across all levels
  def image_content_for_group(group, group_name=nil)
    images = []
    unless group.nil?
      images = group.files.images.map{|i| {src: i.file.url(:original), normal: i.file.url(:resized), thumb: i.file.url(:cms_thumb), title: i.description, group: group_name || '' }}
      group.children.each do |subgroup|
        images << image_content_for_group(subgroup, subgroup.label)
      end
    end
    images
  end


  def content_for_ajax(name, content = nil, options = {}, &block)
    if block_given?
      options = content if content
      content = capture(&block)
    end
    if request.xhr? && (content || block_given?)
      # Render a javascript_tag for jquery update of target or name
      javascript_tag "$('##{options[:target] || name}').html('#{escape_javascript(content)}')"
    else
      content_for(name, content, options)
      nil
    end
  end

  # Override active_link_to here to also compare local href hashes
  # in order to get the nav tabs to work.
  def is_active_link?(url, condition = nil)
    # check hashes against controller name
    active_hash = (url[/^#[_a-z]*/i] || '').sub('#','')
    unless active_hash.blank?
      if %(sites pages layouts snippets files).include?(controller_name)
        if action_name == 'edit'
          return active_hash == 'meta_pane'
        else
          return active_hash == controller_name
        end
      else
        # pages is the default active tab
        return active_hash == 'pages'
      end
    else
      url = url_for(url).sub(/\?.*/, '') # ignore GET params
      case condition
      when :inclusive, nil
        !request.fullpath.match(/^#{Regexp.escape(url).chomp('/')}(\/.*|\?.*)?$/).blank?
      when :exclusive
        !request.fullpath.match(/^#{Regexp.escape(url)}\/?(\?.*)?$/).blank?
      when Regexp
        !request.fullpath.match(condition).blank?
      when Array
        controllers = [*condition[0]]
        actions = [*condition[1]]
        (controllers.blank? || controllers.member?(params[:controller])) &&
        (actions.blank? || actions.member?(params[:action]))
      when TrueClass
        true
      when FalseClass
        false
      end
    end
  end

  # Generates a visible title for the current context
  def current_context_title(tag=:span, separator = ' | ')
    if %(sites pages layouts snippets files).include?(controller_name)
      instance = eval("@#{controller_name.singularize}")
      text = [t("cms/#{controller_name.singularize}", :scope => 'activerecord.models'), (instance.nil? ? nil : instance.label)].compact.join(separator)
      tag.nil? ? text : content_tag(tag, text)
    else
      ''
    end
  end

  # This is a helper for passing the current subpage's slug to the Comfy Layout
  def subpage_slug
    if defined?(@cms_subpage)
      @cms_subpage.slug
    else
      'content_' + (@cms_subcontent_index = (defined?(@cms_subcontent_index) ? (@cms_subcontent_index += 1) : 1)).to_s.strip
    end
  end

  # Helper for generating a gallery image tag
  def image(path, caption=true, klass='fancybox')
    path_tokens = path.split('/')
    image_name = path_tokens.pop
    group = path_tokens.empty? ? @cms_site.groups.files.root : @cms_site.groups.files.where(['hierarchy_path LIKE ?', path_tokens.join('/')]).first
    return '' if group.nil?
    image = @cms_site.files.images.where(['label LIKE ? AND group_id = ?', image_name, group.id]).first
    return '' if image.nil? || image.file.nil?
    html = link_to image_tag(image.file.url(:resized)), image.file.url, class: klass, title: image.description
    html << content_tag(:span, image.description, class: 'caption')
    content_tag(:div, html, class: klass + '-wrapper')
  end

  # Helper for generating a gallery image tag displaying an image's original size
  def original_size_image(path, caption=true, klass='fancybox')
    path_tokens = path.split('/')
    image_name = path_tokens.pop
    group = path_tokens.empty? ? @cms_site.groups.files.root : @cms_site.groups.files.where(['hierarchy_path LIKE ?', path_tokens.join('/')]).first
    return '' if group.nil?
    image = @cms_site.files.images.where(['label LIKE ? AND group_id = ?', image_name, group.id]).first
    return '' if image.nil? || image.file.nil?
    html = link_to image_tag(image.file.url), image.file.url, class: klass, title: image.description
    html << content_tag(:span, image.description, class: 'caption')
    content_tag(:div, html, class: klass + '-wrapper')
  end

  # Override the
  def comfy_form_for(record, options = {}, &proc)
    options[:builder] = ComfortableMexicanSofa::FormBuilder
    options[:type] ||= :horizontal
    formatted_form_for(record, options, &proc)
  end

  def click_action_for(dom_id, model, action)
    if %w(site layout page snippet file).include?(model.to_s) && %w(new update destroy).include?(action.to_s)
      action_url_method = [action.to_s, 'admin_cms_site', (model.to_s == 'site' ? nil : model.to_s), 'path'].compact.join('_')
      unless @site.nil? || @site.new_record?
        action_url = action_url_method.concat "(:site_id => #{@site.id})"
      end
    end
    "$('##{dom_id}').attr('href','#{eval(action_url || action_url_method)}'); initializeTreeTab('#{model}s-tree');"
  end

  # renders hidden fields with behavior to copy from the data-attribute=true field on submit
  def data_copy_field_for(model, attribute, data_tag=nil)
    data_tag ||= attribute
    hidden_field_tag "#{model}[#{attribute}]", eval("@#{model}.#{attribute}"), id: "copy_#{data_tag}", data: {copy: data_tag}
  end

  # Creates formatted form fields according to contact_form_definitions
  def contact_form_field(form_builder, contact_form, field, value=nil)
    value ||= @contact.getFieldValue(field)
    contact_field_definition = contact_form.contact_field_options_for(field).symbolize_keys
    wrap_tag = contact_form.site.contact_form_wrap_tag
    translations = contact_form.contact_field_translations
    options_for_html = {}
    %w(width height prepend append in label values mandatory).each do |dim|
      options = contact_field_definition[dim.to_sym]
      next if options.blank? || (options.is_a?(Enumerable) && options.empty?)
      options_for_html[dim] = contact_field_definition[dim.to_sym]
    end
    unless contact_field_definition[:options].blank?
      options_for_html['options'] ||= {}
      contact_field_definition[:options].keys.each do |k|
        options_for_html['options'][t(k, :scope => "cms.contact_form.#{field}")] = contact_field_definition[:options][k]
      end
    end
    label = t((options_for_html[:label].blank? ? (translations[field] || field) : options_for_html[:label]), :scope => 'cms.contact_form.fields')
    options_for_html[:label] = h(label)
    case @cms_site.css_framework.underscore.to_sym
      when :gumby
        gumby_field_tag(form_builder, contact_field_definition[:type], field, options_for_html, value, wrap_tag)
      else
        bootstrap_field_tag(form_builder, contact_field_definition[:type], field, options_for_html, value, wrap_tag)
    end
  end
end

def gumby_field_tag(form_builder, type, field, options_for_html, value, wrap_tag=nil)
  prepend = options_for_html.delete('prepend')
  append = options_for_html.delete('append')
  mandatory = options_for_html.delete('mandatory')
  label = options_for_html.delete(:label) + (mandatory ? ' *' : '')
  options_for_html.merge!({:placeholder => (value.blank? ? label : value)})
  if mandatory
    options_for_html.merge!({:required => true})
  end
  klasses = %w(field)
  klasses << 'completed' unless value.blank?
  label_tag = content_tag(:label, label, { class: 'inline', for: "contact[#{field}]" })
  html = case type.underscore.to_sym
           when :string, :datetimer
             text_field_tag "contact[#{field}]", value, options_for_html.merge!({class: 'input'})
           when :password
             password_field_tag "contact[#{field}]", value, options_for_html.merge!({class: 'input'})
           when :number
             number_field_tag "contact[#{field}]", value, options_for_html.merge!({class: 'input'})
           when :email
             email_field_tag "contact[#{field}]", value, options_for_html.merge!({class: 'input'})
           when :phone
             phone_field_tag "contact[#{field}]", value, options_for_html.merge!({class: 'input'})
           when :country
             options = localized_country_options_for_select(value, [:DE, :AT, :CH, :GB, :US])
             label_tag + content_tag(:div, select_tag("contact[#{field}]", options, options_for_html), class: 'picker')
           when :select
            options = options_for_select((options_for_html.delete('options') || {}), value)
             label_tag + content_tag(:div, select_tag("contact[#{field}]", options, options_for_html), class: 'picker')
           when :checkbox
             content_tag(:label, label + check_box_tag("contact[#{field}]", 1, !value.false?, options_for_html.merge!({class: 'input'})), { for: "contact[#{field}]"})
           when :textarea, :text
             label_tag + text_area_tag("contact[#{field}]", value, options_for_html.merge!({class: 'input'}))
           else
             # Text field
             text_field_tag "contact[#{field}]", value, options_for_html.merge!({class: 'input'})
         end
  unless prepend.blank?
    html = content_tag(:span, content_tag(:i, '', class: prepend), class: 'adjoined') + html
    klasses << 'prepend'
  end
  unless append.blank?
    html = html + content_tag(:span, content_tag(:i, '', class: append), class: 'adjoined')
    klasses << 'append'
  end
  html = content_tag(wrap_tag || :li, html, class: klasses.join(' '))
  html
end

def bootstrap_field_tag(form_builder, type, field, options_for_html, value, wrap_tag=nil)
  html = case type.underscore.to_sym
           when :text
             form_builder.textarea field, options_for_html
           when :password
             form_builder.password_field field, options_for_html
           when :number
             form_builder.number_field field, options_for_html
           when :email
             form_builder.email_field field, options_for_html
           when :phone
             form_builder.phone_field field, options_for_html
           when :select
             form_builder.select field, options_for_html.delete(:options), options_for_html
           when :checkbox
             options_for_html[:values].nil? ? /
                 form_builder.check_box(options_for_html.delete(:values), options_for_html) /
             : form_builder.check_box(field, options_for_html)
           when :datetime
             form_builder.text_field field, options_for_html.merge!({class: 'datetime'})
           else
             # Text field
             form_builder.text_field field, options_for_html
         end
  html = content_tag(wrap_tag, html, class: :field) unless wrap_tag.blank?
  html
end
