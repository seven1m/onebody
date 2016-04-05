class Sanitize
  module Config
    ONEBODY = {
      elements: %w(
        a b blockquote br caption cite code col colgroup dd div dl dt em h1 h2 h3 h4 h5 h6
        i img li ol p pre q small span strike strong sub sup table tbody td tfoot th thead tr u ul
      ),

      attributes: {
        :all         => %w(style                                ),
        'a'          => %w(href title                           ),
        'blockquote' => %w(cite                                 ),
        'col'        => %w(span width                           ),
        'colgroup'   => %w(span width                           ),
        'font'       => %w(size color                           ),
        'img'        => %w(align alt height src title width     ),
        'ol'         => %w(start type                           ),
        'q'          => %w(cite                                 ),
        'table'      => %w(summary width                        ),
        'td'         => %w(abbr axis colspan rowspan width      ),
        'th'         => %w(abbr axis colspan rowspan scope width),
        'ul'         => %w(type                                 )
      },

      protocols: {
        'a'          => { 'href' => ['ftp', 'http', 'https', 'mailto', :relative] },
        'blockquote' => { 'cite' => ['http', 'https', :relative] },
        'img'        => { 'src'  => ['http', 'https', :relative] },
        'q'          => { 'cite' => ['http', 'https', :relative] }
      },

      css: {
        # These properties are often used in emails crafted by Outlook and seem safe enough.
        # If you have need to add others properties here, be careful not to add any that would
        # allow placing anything that looks like a button or link outside these region of the
        # email displayed on screen, which might allow an attacker to trick a user into thinking
        # their button is a part of the OneBody UI (absolute positioning, background colors, etc.).
        # A better approach would be to display HTML emails in an iFrame, but that's for another day...
        properties: %w(
          display
          color
          font font-family font-size font-weight line-height
          margin margin-top margin-right margin-bottom margin-left
        )
      },

      remove_contents: %w(script style)
    }.freeze
  end
end
