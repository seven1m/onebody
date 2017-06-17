module Administration::SettingsHelper
  def section_tab(label, name, active = false)
    content_tag(:li, class: active ? 'active' : nil) do
      link_to label, "##{name}", data: { toggle: 'tab' }
    end
  end

  def setting_row(section, name, options = {}, &block)
    return unless (@setting = @settings[section][name])
    content_tag(:div, class: "form-group setting#{@setting.id}") do
      label_tag(@setting.id, setting_name(@setting), class: 'col-sm-2 control-label') +
        content_tag(:div, class: 'col-sm-10') do
          if block_given?
            capture(&block)
          else
            setting_field(options)
          end +
            (options[:description] || setting_description(@setting))
        end
    end
  end

  def setting_field(options = {})
    @setting = @settings[options[:section]][options[:name]] if options[:section] && options[:name]
    if @setting.format == 'boolean'
      content_tag(:div, class: 'setting-checkbox-group') do
        hidden_field_tag(@setting.id, false, id: '') + \
          check_box_tag(@setting.id, true, @setting.value?)
      end
    elsif @setting.format == 'list'
      text_area_tag(@setting.id, Array(@setting.value).join("\n"), rows: 3, cols: 40, class: 'form-control')
    elsif options[:options]
      select_tag(@setting.id, options_for_select(options[:options], @setting.value), class: 'form-control')
    else
      text_field_tag(@setting.id, @setting.value, size: 30, class: 'form-control')
    end
  end

  def setting_name(setting)
    I18n.t('name', scope: ['admin.settings', setting.section, setting.name], default: setting.name)
  end

  def setting_description(setting)
    content_tag(:span, class: 'help-block') do
      scope = ['admin.settings', setting.section, setting.name]
      I18n.t('description', scope: scope, default: '')
    end
  end
end
