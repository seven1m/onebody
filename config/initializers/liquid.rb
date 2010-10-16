class LiquidView

  include ApplicationHelper

  def initialize(action_view)
    @action_view = action_view
  end

  def self.call(template)
    "LiquidView.new(self).render(\"#{template_source(template)}\")"
  end

  def self.template_source(template)
    template.source.gsub('"', '\\"')
  end

  def render(source)
    @action_view.controller.headers["Content-Type"] ||= 'text/html; charset=utf-8'
    assigns = @action_view.assigns.dup

    content_for = @action_view.instance_variable_get("@_content_for")
    assigns['content_for_layout'] = content_for[:layout]

    @action_view.controller._helpers.instance_methods.each do |method|
      assigns[method.to_s] = Proc.new { @action_view.send(method) }
    end

    @action_view.instance_variables.each do |name|
      assigns[name.to_s.sub('@', '')] = @action_view.instance_eval(name)
    end

    liquid = Liquid::Template.parse(source)
    html = liquid.render(assigns, :registers => {:action_view => @action_view, :controller => @action_view.controller})
    if html.respond_to?(:encode)
      html.encode("iso-8859-1", :undef => :replace, :invalid => :replace)
    else
      html
    end
  end

  def compilable?
    false
  end

end

ActionView::Template.register_template_handler(:liquid, LiquidView)
