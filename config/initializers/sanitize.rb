class Sanitize
  module Config
    ONEBODY = {
      :elements => %w(
        a b blockquote br caption cite code col colgroup dd div dl dt em font h1 h2 h3 h4 h5 h6
        i img li ol p pre q small strike strong sub sup table tbody td tfoot th thead tr u ul
      ),

      :attributes => {
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

      :protocols => {
        'a'          => {'href' => ['ftp', 'http', 'https', 'mailto', :relative]},
        'blockquote' => {'cite' => ['http', 'https', :relative                 ]},
        'img'        => {'src'  => ['http', 'https', :relative                 ]},
        'q'          => {'cite' => ['http', 'https', :relative                 ]}
      },

      :remove_contents => %w(script style)
    }
  end
end
