module ApplicationHelper
  # Help build gumby forms

  # checkbox with label included, Gumby-style
  def gumby_checkbox(form_builder, method, label, checked=false, value="1")
    name = "#{form_builder.object.class.name.underscore}[#{method}]"
    checkbox = check_box_tag(name, value, checked) + content_tag(:span) + ' ' + label.to_s
    html = label_tag(name, checkbox, :class => "checkbox#{checked ? ' checked' : ''}")
    html + hidden_field_tag(name, (value.to_i == 0) ? '1' : '0', :id => nil)
  end

  def fancytree_pages_hash(pages, branch_id=nil)
    pages[branch_id].map do |page|
      child_pages = pages[page.id] || []
      page_hash = { title: page.label, key: page.id, href: edit_admin_cms_site_page_path(site_id: @site.id, id: page.id, format: :js) }
      unless child_pages.empty?
        page_hash.merge!({ folder: true, children: fancytree_pages_hash(pages, page.id)})
      end
      page_hash
    end
  end
end
