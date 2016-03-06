window.addOrUpdateURLParam = (name, value) ->
  if location.href.match(new RegExp("(\\?|&)#{name}="))
    location.href = location.href.replace(new RegExp("(\\?|&)#{name}=[^&]+"), "$1#{name}=#{value}")
  else
    location.href = location.href + getURLParamSeparator() + "#{name}=#{value}"

window.getURLParamSeparator = ->
  if location.href.match(/\?/)
    '&'
  else
    '?'
