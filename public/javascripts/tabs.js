  TAB_HEADINGS = 'h2';
  TAB_CLASS = 'tab';
  SECTION_CLASS = 'section';
  QUERY_SECTION_ARG = 'section';
  TAB_SELECTED_CLASS = 'selected';
  TAB_NOT_SELECTED_CLASS = 'not-selected';
  LOADING_ELM_ID = 'loading';
  CONTENT_HOLDER_ID = 'content-holder';

  lastSection = -1
  function checkHash() {
    var section = get_selected();
    if(section != lastSection) {
      show_section(section);
      lastSection = section;
    }
  }

  function get_elements() {
    var divs = document.getElementsByTagName("div");
    var htags = document.getElementsByTagName(TAB_HEADINGS);
    sections = [];
    tabs = [];
    headings = []
    for(var i=0; i<divs.length; i++) {
      if(divs[i].className.indexOf(SECTION_CLASS) > -1) sections.push(divs[i]);
    }
    for(var i=0; i<htags.length; i++) {
      if(htags[i].className.indexOf(TAB_CLASS) > -1) {
        var div = document.createElement("div");
        div.innerHTML = htags[i].innerHTML;
        tabs.push(div);
        headings.push(htags[i]);
      }
    }
  };

  function combine_tabs(){
    if(headings.length == 0)return;
    headings[0].innerHTML = '';
    for(var i=0; i<tabs.length; i++) {
      headings[0].appendChild(tabs[i]);
      if(i > 0) headings[i].parentNode.removeChild(headings[i]);
      headings[i].setAttribute('origId', headings[i].id)
      headings[i].id = null;
    }
    // hack to fix tab alignment
    var div = document.createElement('div');
    div.style.fontSize = '1pt';
    div.style.lineHeight = '1pt';
    div.style.margin = '0';
    div.innerHTML = '&nbsp;'
    headings[0].parentNode.insertBefore(div, headings[0]);
  };

  function hide_all(){
    for(var i=0; i<sections.length; i++) {
      sections[i].style.display = "none";
    }
    for(var i=0; i<tabs.length; i++) {
      tabs[i].className = TAB_NOT_SELECTED_CLASS
    }
  };

  function show_section(index){
    hide_all()
    if(sections.length == 0) return;
    var section = sections[index];
    if(!section) var section = sections[index=0];
    section.style.display = "block";
    tabs[index].className = TAB_SELECTED_CLASS;
    var id = headings[index].getAttribute('origId') || sections[index].getAttribute('id');
    if(id && index != lastSection) {
      //var y = typeof window.pageYOffset != 'undefined' ? window.pageYOffset : document.documentElement.scrollTop;
      if((location.hash == null || lastSection != -1)) location.hash = '#' + id;
      //window.scrollTo(0, y);
      if(typeof load_tab == 'function') load_tab(id);
    }
    lastSection = index;
  };

  function tab_click(e){
    var target = e && e.target || event.srcElement;
    for(var i=0; i<tabs.length; i++) {
      if(target == tabs[i] || target.parentNode == tabs[i]){
        show_section(i);
      }
    }
  };

  function set_handlers(){
    for(var i=0; i<tabs.length; i++) {
      tabs[i].onclick = tab_click;
    }
  };

  function get_selected(){
    var selected = 0;
    if(location.hash) {
      selected = location.hash.substring(1);
    } else if(location.search) {
      var args = location.search.substring(1).split('&');
      for(var i=0; i<args.length; i++) {
        var name = args[i].split('=')[0];
        var value = args[i].split('=')[1];
        if(name == QUERY_SECTION_ARG){
            selected = value;
            break;
        }
      }
    }
    if(isNaN(selected)){
      for(var i=0; i<sections.length; i++){
        if(sections[i].getAttribute('id') == selected || headings[i].getAttribute('origId') == selected){
          selected = i;
          break;
        }
      }
    }
    return selected;
  };

  function set_up_tabs() {
    get_elements();
    combine_tabs();
    var loadingElm = document.getElementById(LOADING_ELM_ID);
    if(loadingElm){
      loadingElm.style.display = "none";
    }
    var contentHolderElm = document.getElementById(CONTENT_HOLDER_ID);
    if(contentHolderElm) {
      contentHolderElm.style.display = "block";
    }
    var selected = get_selected();
    show_section(selected);
    set_handlers();
    setInterval(checkHash, 100);
  };
