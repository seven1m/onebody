// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function custom_select_val(select_elm, prompt_text){
  if(val = prompt(prompt_text, '')) {
    var option = document.createElement('option');
    option.setAttribute('value', val);
    option.innerHTML = val;
    option.selected = true;
    select_elm.appendChild(option);
  } else {
    select_elm.options[0].selected = true;
  }
};