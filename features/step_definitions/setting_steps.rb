Given /^setting "([^\"]*)" in category "([^\"]*)" is (.+)$/ do |name, category, value|
  value = case value
    when 'enabled' then true
    when 'disabled' then false
    else value
  end
  Setting.set(Site.current.id, category, name, value)
end