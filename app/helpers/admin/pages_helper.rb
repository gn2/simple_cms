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
    content_tag(:ul, show_pages(top_level_pages), :class => 'page_tree top', :id => "jstree")
  end

  private
  def show_pages(pages, content='')
    pages.each do |page|
      li_content = content_tag(:a, content_tag(:ins, " ") + page.title.titlecase, :href => admin_page_path(page.id), :class => "page_title")
      span_content = content_tag(:a, "edit", :href => admin_page_path(page.id))
      span_content << " | layout:#{page.layout.name}"
      span_content << " | state:#{page.state}"
      span_content << " | #{page.assets_count}/#{pluralize(page.maximum_assets_count, 'asset')}"
      li_content << content_tag(:span, span_content, :class => "page_tree_info")
      li_content += content_tag(:ul, show_pages(page.children)) if page.children.size > 0
      content += content_tag(:li, li_content, :id => "page_#{page.id}")
    end
    return content
  end
end
