module ApplicationHelper
  # Help build gumby forms

  # checkbox with label included, Gumby-style
  def gumby_checkbox(form_builder, method, label, checked=false, value="1")
    name = "#{form_builder.object.class.name.underscore}[#{method}]"
    checkbox = check_box_tag(name, value, checked) + content_tag(:span) + ' ' + label.to_s
    html = label_tag(name, checkbox, :class => "checkbox#{checked ? ' checked' : ''}")
    html + hidden_field_tag(name, (value.to_i == 0) ? '1' : '0', :id => nil)
  end
end
