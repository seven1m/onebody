PrawnTemplateHandler
====================

Uber simple template handler for Prawn PDF views.

Installation
------------

Add the following to your environment.rb Initializer block:

    config.gem 'seven1m-prawn_template_handler', :source => 'http://gems.github.com', :lib => 'prawn_template_handler'

Then run "sudo rake gems:install" to install as a dependency.

Or, use the traditional plugin install method:

    script/plugin install git://github.com/seven1m/prawn_template_handler.git

Usage
-----

In show.pdf.prawn:

    pdf.move_down 200
    pdf.text 'Hello World'

If you need to specify document options, add a @pdf line to your show method (optional):

    def show
      @pdf = Prawn::Document.new(:page_layout => :landscape)
    end

License
-------

Released into the Public Domain.
