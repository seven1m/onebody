module ActionView
  module TemplateHandlers
    class Prawn < TemplateHandler
      include Compilable

      def compile(template)
        <<-SRC
          controller.response.content_type ||= Mime::PDF
          pdf = @pdf || Prawn::Document.new
          #{template.source}
          pdf.render
        SRC
      end
    end
  end
end

Mime::Type.register "application/pdf", :pdf
ActionView::Template.register_template_handler 'prawn', ActionView::TemplateHandlers::Prawn
