# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include TagsHelper
  include PicturesHelper
  include PhotosHelper
  
  def heading
    if (logo = Setting.get(:appearance, :logo)).to_s.any?
	    "<a href=\"/\">#{image_tag logo, :alt => Setting.get(:name, :site), :class => 'no-border', :style => 'float:left;margin-right:10px;'}</a>"
	  elsif !@page or @page.for_members?
	    "<a href=\"/people\">#{h Setting.get(:name, :site)}</a>"
	  else
	    "<a href=\"/\">#{h Setting.get(:name, :church)}</a>"
    end
  end
  
  def subheading
    if !@page or @page.for_members?
      html = simple_url(Setting.get(:url, :site))
    else
      html = simple_url(Setting.get(:url, :visitor))
    end
    if Setting.get(:name, :slogan).to_s.any?
      html << " | <span id=\"news_headlines\" style=\"position:relative;background-color:#fff;\">#{h Setting.get(:name, :slogan)}</span>"
    end
    html
  end
  
  def tab_link(title, url, active=false)
    link_to(title, url, :class => active ? 'active' : nil)
  end
  
  def nav_links
    html = ''
    if Setting.get(:features, :content_management_system)
      html << "<li>#{tab_link 'Home', '/', params[:controller] == 'pages' && @page && @page.home?}</li>"
    end
    html << "<li>#{tab_link 'Profile', @logged_in || people_path, params[:controller] == 'people' && me?}</li>"
    html << "<li>#{tab_link 'Directory', new_search_path, %w(searches printable_directories).include?(params[:controller])}</li>"
    if Setting.get(:features, :groups) and (Site.current.max_groups.nil? or Site.current.max_groups > 0)
      html << "<li>#{ tab_link 'Groups', groups_path, params[:controller] == 'groups'}</li>"
    end
    html << "<li>#{ tab_link 'More', shares_path, %w(shares events pictures verses recipes).include?(params[:controller])}</li>"
    html
  end
  
  def notice
    if flash[:warning] or flash[:notice]
      <<-HTML
        <div id="notice" #{flash[:warning] ? 'class="warning"' : nil}>#{flash[:warning] || flash[:notice]}</div>
        <script type="text/javascript">
          setTimeout("new Effect.Fade('notice');", 15000)
        </script>
      HTML
    end
  end
  
  def personal_nav_links
    html = ''
    if @logged_in
      html << "<li class=\"personal\">"
      html << link_to('sign out', session_path, :method => 'delete')
      html << "</li>"
      if @logged_in.admin?
        html << "<li class=\"personal\">"
        html << link_to('admin', admin_path)
        html << "</li>"
      end
    else
      html << "<li class=\"personal\">"
      html << link_to('sign in', new_session_path)
      html << "</li>"
    end
    html
  end
  
  def news_js
    unless @logged_in.nil?
      "<script type=\"text/javascript\" src=\"/news.js\"></script>"
    end
  end
  
  def analytics_js
    if Rails.env.production?
      Setting.get(:services, :analytics)
    end
  end

  def preserve_breaks(text, make_safe=true)
    text = h(text.to_s) if make_safe
    simple_format(text.to_s)
  end
  
  def remove_excess_breaks(text)
    text.gsub(/(\n\s*){3,}/, "\n\n")
  end
  
  def hide_contact_details(text)
    text.gsub(/\(?\d\d\d\)?[\s\-\.]?\d\d\d[\s\-\.]\d\d\d\d/, '[phone number protected]').gsub(/[a-z\-_\.0-9]+@[a-z\-0-9\.]+\.[a-z]{2,4}/, '[email address protected]')
  end
  
  def image_tag(location, options)
    options[:title] = options[:alt] if options[:alt]
    super(location, options)
  end
  
  def simple_url(url)
    url.gsub(/^https?:\/\//, '').gsub(/\/$/, '')
  end
  
  def me?
    @logged_in and @person and @logged_in == @person
  end
  
  def help_path(name=nil)
    page_for_public_path("help/#{name}")
  end
  
  def system_path(name=nil)
    page_for_public_path("system/#{name}")
  end
  
  def render_page_content(path)
    Page.find_by_path(path).body rescue ''
  end
  
  def format_phone(phone, mobile=false)
    format = Setting.get(:formats, mobile ? :mobile_phone : :phone)
    return phone if format.blank?
    groupings = format.scan(/d+/).map { |g| g.length }
    groupings = [3, 3, 4] unless groupings.length == 3
    ActionController::Base.helpers.number_to_phone(
      phone,
      :area_code => format.index('(') ? true : false,
      :groupings => groupings,
      :delimiter => format.reverse.match(/[^d]/).to_s
    )
  end
  
  def custom_field_name(index)
    n = Setting.get(:features, :custom_person_fields).to_a[index]
    n ? n.sub(/\*/, '') : nil
  end
  
  class << self
    include ApplicationHelper
  end
end

module ActionView
  module Helpers
    module FormHelper
      def phone_field(object_name, method, options = {})
        options[:value] = format_phone(options[:object][method], mobile=(method.to_s =~ /mobile/))
        options[:size] ||= 15
        InstanceTag.new(object_name, method, self, options.delete(:object)).to_input_field_tag("text", options)
      end
      def date_field(object_name, method, options = {})
        options[:value] = options[:object][method].to_s(:date) rescue ''
        options[:size] ||= 12
        InstanceTag.new(object_name, method, self, options.delete(:object)).to_input_field_tag("text", options)
      end  
    end
    class FormBuilder
      def phone_field(method, options = {})
        @template.phone_field(@object_name, method, options.merge(:object => @object))
      end
      def date_field(method, options = {})
        options = {:time => false, :size => 15, :buttons => false}.merge(options)
        calendar_date_select(method, options)
      end
    end
    module FormTagHelper
      def date_field_tag(name, value = nil, options = {})
        options = {:time => false, :size => 15, :buttons => false}.merge(options)
        calendar_date_select_tag(name, value, options)
      end
    end
  end
end
