require 'extras/liquid_view'

class LiquidView            

  include ApplicationHelper

  def initialize(action_view)
    @action_view = action_view
  end              

  def self.call(template)
    "LiquidView.new(self).render(template, local_assigns)"
  end  

  def render(template, local_assigns_for_rails_less_than_2_1_0 = nil)
    @action_view.controller.headers["Content-Type"] ||= 'text/html; charset=utf-8'
    assigns = @action_view.assigns.dup

    # template is a Template object in Rails >=2.1.0, a source string previously.
    if template.respond_to? :source
      source = template.source
      local_assigns = local_assigns_for_rails_less_than_2_1_0
      local_assigns = template.locals if template.respond_to? :locals     
    else
      source = template
      local_assigns = local_assigns_for_rails_less_than_2_1_0
    end

    if content_for_layout = @action_view.instance_variable_get("@content_for_layout")
      assigns['content_for_layout'] = content_for_layout
    end
    assigns.merge!(local_assigns)
    
    @action_view.controller.master_helper_module.instance_methods.each do |method|
      assigns[method.to_s] = Proc.new { @action_view.send(method) }
    end
    
    @action_view.instance_variables.each do |name|
      assigns[name.to_s.sub('@', '')] = @action_view.instance_eval(name)
    end
    
    liquid = Liquid::Template.parse(source)
    liquid.render(assigns, :registers => {:action_view => @action_view, :controller => @action_view.controller})
  end

  def compilable?
    false
  end

end

if defined? ActionView::Template and ActionView::Template.respond_to? :register_template_handler
  ActionView::Template
else
  ActionView::Base
end.register_template_handler(:liquid, LiquidView)
