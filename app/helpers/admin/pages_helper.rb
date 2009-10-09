module Admin::PagesHelper
  include Admin::ApplicationHelper

  #
  # Form stuff
  #
  def generate_page_form(page_object, layout_object)
    raise "Object is not a page" unless page_object && page_object.kind_of?(Page)
    raise "Object is not a layout" unless layout_object && layout_object.kind_of?(Layout)

    form_content = ""
    prefix = "page[page_parts_attributes][]"

    layout_object.layout_parts.ordered.each do |layout_part|
      page_part = page_object.page_parts.with_layout_part(layout_part.id)

      form_content += hidden_field_tag("#{prefix}[layout_part_id]", layout_part.id)
      form_content += hidden_field_tag("#{prefix}[id]", page_part.id) if page_part && !page_object.new_record?

      form_content += case layout_part.content_type.to_sym
      when :string
        textfield_input(layout_part.name, page_object.page_parts.content(layout_part.name), :prefix => prefix, :attribute => 'content')
      when :text
        textarea_input(layout_part.name, page_object.page_parts.content(layout_part.name), :prefix => prefix, :attribute => 'content', :options => {:class => "text_area resizable markItUp"})
      else
        ""
      end
    end
    return form_content
  end

  #
  # Pages
  #
  def pages_breadcrumbs(current_page)
    current_page.ancestors.reverse.inject("") do |breadcrumbs, page|
      breadcrumbs += link_to(h(page.title.titlecase), admin_page_path(page)) + " &gt; "
    end + h(current_page.title.titlecase)
  end


  def show_page_tree(top_level_pages)
    content_tag(:ul, show_pages(top_level_pages), :class => 'page_tree top')
  end

  private
  def show_pages(page, content='')
    page.each do |child|
      li_content = content_tag(:a, child.title.titlecase, :href => admin_page_path(child.id))
      li_content << content_tag(:span, "layout:#{child.layout.name} | state:#{child.state} | #{pluralize(child.assets_count, 'asset')}", :class => "page_tree_info")
      content += content_tag(:li, li_content)
      content += content_tag(:ul, show_pages(child.children))
    end
    return content
  end
end
