module ApplicationHelper
  # Help build gumby forms

  def page_path(page)
    site_path = page.site.path
    path_elems = [page.slug.to_s]
    while !page.parent.nil?
      page = page.parent
      path_elems << page.slug.to_s
    end
    File.join('/', site_path, path_elems.reverse.compact)
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

  def fancytree_pages_hash(pages, branch_id=nil)
    item_model = pages[branch_id].first.class.name.underscore.split('/').last unless pages[branch_id].empty?
    pages[branch_id].map do |page|
      child_pages = pages[page.id] || []
      page_hash = { title: page.label, key: page.id, href: method("edit_admin_cms_site_#{item_model}_path".sub('site_site','site')).call({site_id: @site.id, id: page.id, format: :js}) }
      unless child_pages.empty?
        page_hash.merge!({ folder: true, children: fancytree_pages_hash(pages, page.id)})
      end
      page_hash
    end
  end

  def fancytree_grouped_hash(groups, items, branch_id=nil, top_node=true, new_link=true, &labelling)
    item_model = groups[branch_id].first.grouped_type.underscore.split('/').last unless groups[branch_id].empty?
    labelling = ->(item) { fancytree_label_for(item) } unless block_given?
    collection = groups[branch_id].map do |group|
      child_groups = groups[group.id] || []
      page_hash = { title: group.label, key: group.id, href: method("edit_admin_cms_site_group_path".sub('site_site','site')).call({site_id: @site.id, id: group.id, format: :js}) }
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
      if top_node
        # just return the children, skip the root node
        child_contents
      else
        # page and collection as children
        page_hash
      end
    end
    if top_node && new_link
      collection = collection.first # remove array nesting
      grouped_type = groups[branch_id].first.grouped_type.underscore.split('/').last
      html = link_to content_tag(:i, '', :class => 'icon-plus').concat(t(:new_link, :scope => 'admin.cms.groups')), eval("admin_cms_new_#{grouped_type}_group_path(site_id: #{@site.id})")
      collection << { title: html }
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
end
