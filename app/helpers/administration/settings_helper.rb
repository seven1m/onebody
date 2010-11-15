module Administration::SettingsHelper

  def section_name(section)
    I18n.t(:name, :scope => [:admin, :settings, section], :default => section)
  end

  def section_row(section)
    content_tag(:tr) do
      content_tag(:td, :colspan => 2) do
        content_tag(:h3) do
          section
        end
      end
    end
  end

  def subsection_row(text)
    content_tag(:tr, :class => 'subsection') do
      content_tag(:td, :colspan => 2) do
        text
      end
    end
  end

  def setting_row(section, name, options={}, &block)
    if @setting = @settings[section][name]
      content_tag(:tr, :class => "detail setting#{@setting.id}") do
        content_tag(:td, :class => 'label') do
          label_tag @setting.id, @setting.name
        end + \
        content_tag(:td) do
          if block_given?
            capture(&block)
          else
            setting_field(options)
          end
        end
      end + \
      content_tag(:tr, :class => "description setting#{@setting.id}") do
        content_tag(:td) + \
        content_tag(:td) do
          @setting.description
        end
      end
    end
  end

  def setting_field(options={})
    @setting = @settings[options[:section]][options[:name]] if options[:section] and options[:name]
    if @setting.format == 'boolean'
      hidden_field_tag(@setting.id, false, :id => '') + \
      check_box_tag(@setting.id, true, @setting.value?) + \
      label_tag(@setting.id, options[:label] == :name ? @setting.name : t('admin.settings.enabled'), :class => 'inline')
    elsif @setting.format == 'list'
      text_area_tag(@setting.id, Array(@setting.value).join("\n"), :rows => 3, :cols => 40)
    elsif options[:options]
      select_tag(@setting.id, options_for_select(options[:options], @setting.value))
    else
      text_field_tag(@setting.id, @setting.value, :size => 30)
    end
  end

end
