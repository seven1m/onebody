onload = function() {
  setup_verses();
}

function setup_verses() {
  $$('.verse').each(function(v){
    var html = v.innerHTML;
    var ref_parts = v.getAttribute('id').split(/\-/);
    v.innerHTML = '<span class="reference">v' + ref_parts[ref_parts.length-1] + '</span><span class="text">' + html + '</span>';
    v.onmousedown = verse_mousedown;
    v.onmouseover = verse_mouseover;
    v.onmouseup   = verse_mouseup;
  });
}

function verse_mouseover(e) {
  e = e || event;
  if(selecting_from_verse)
    toggle_highlight_between(selecting_from_verse, get_verse_id(e.target))
}

function verse_mousedown(e) {
  e = e || event;
  start_selecting(get_verse_id(e.target), e.ctrlKey || e.shiftKey);
  return false;
}

function verse_mouseup(e) {
  e = e || event;
  done_selecting(get_verse_id(e.target))
}

function st(text) {
  $('highlighted_reference').innerHTML = text;
}

selected_verses = [];
prev_selected_verses = [];

function select_verse(id, reference, text) {
  selected_verses.push([id, reference, text]);
  update_scratchpad();
}

function unselect_verse(id) {
  for(var i=0; i<selected_verses.length; i++) {
    if(selected_verses[i] && selected_verses[i][0] == reference) {
      delete selected_verses[i];
      update_scratchpad();
      return
    }
  }
}

function update_scratchpad() {
  if(selected_verses.length == 0) return;
  selected_verses = selected_verses.sortBy(function(v){return parseInt(v[0].split('-')[2])});
  var html = '<strong>' + book_name + ' ' + selected_verses[0][1]
  for(var i=0; i<selected_verses.length; i++) {
    var v = selected_verses[i];
    if(i>0) {
      var l = selected_verses[i-1];
      if(parseInt(v[0].split('-')[2]) != parseInt(l[0].split('-')[2])+1) {
        if(html.substring(html.length-1) == '-') html += l[1];
        html += ',' + v[1];
      } else if(html.substring(html.length-1) != '-') {
        html += '-';
        if(i == selected_verses.length-1) html += v[1];
      } else if(i == selected_verses.length-1) {
        html += v[1];
      }
    }
  }
  html += '</strong><br/>';
  var last_id = null;
  selected_verses.each(function(v){
    if(last_id && parseInt(v[0]) != parseInt(last_id)+1) html += '... ';
    html += v[2] + ' ';
    last_id = v[0];
  });
  $('selected_verses').innerHTML = html;
}

function toggle_highlight(id, object) {
  object = object || $(id);
  if(object.className == 'verse selected-verse') {
    object.className = 'verse';
    return false;
  } else {
    object.className = 'verse selected-verse';
    return true;
  }
}

function unselect_all() {
  $$('.selected-verse').each(function(v){
    v.className = 'verse';
  });
}

function highlight_selected() {
  unselect_all();
  selected_verses.each(function(v){
    toggle_highlight(v[0]);
  })
}

function toggle_highlight_between(from_id, to_id) {
  selected_verses = [];
  from_id_num = from_id.split('-')[2];
  to_id_num = to_id.split('-')[2];
  var book_and_chapter = from_id.replace(/\d+$/, '')
  for(var i=from_id_num; i<=to_id_num; i++) {
    selected_verses.push(get_verse(book_and_chapter + i));
  }
  highlight_selected();
  update_scratchpad();
}

selecting_from_verse = null;

function start_selecting(start_id, adding) {
  if(adding) selected_verses.each(function(v){prev_selected_verses.push(v)});
  selecting_from_verse = start_id;
}

function done_selecting(done_id) {
  if(selecting_from_verse) {
    toggle_highlight_between(selecting_from_verse, done_id);
    if(prev_selected_verses.length > 0) {
      selected_verses = prev_selected_verses.concat(selected_verses);
      highlight_selected();
      update_scratchpad();
    }
    selecting_from_verse = null;
    prev_selected_verses = [];
  }
}

function get_verse(id) {
  verse_parts = id.split(/\-/)
  return [id, verse_parts[1] + ':' + verse_parts[2], $$('#' + id + ' .text')[0].innerHTML]
}

function get_verse_id(target) {
  var id;
  while(!(id = target.getAttribute('id'))) {
    target = target.parentNode;
  }
  return id;
}