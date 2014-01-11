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
    "$('##{dom_id}').attr('href','#{eval(action_url)}');"
  end

  # renders hidden fields with behavior to copy from the data-attribute=true field on submit
  def data_copy_field_for(model, attribute, data_tag=nil)
    data_tag ||= attribute
    hidden_field_tag "#{model}[#{attribute}]", eval("@#{model}.#{attribute}"), id: "copy_#{data_tag}", data: {copy: data_tag}
  end
end
