var i = 0;
var last = null;
for(i=0; i<10; i++) {
  if(document.getElementById("query_review_"+i)) {
    last = document.getElementById("query_review_"+i);
  } else {
    break;
  }
}
if(i < 10) {
  var container_div = document.createElement("div");
  container_div.style.left = ""+(i * 30 + 1)+"px";
  container_div.setAttribute("id", "query_review_"+i);
  container_div.className = "query_review_container";
  var ihtml = '<%= escape_javascript(render(:partial => "/box_includes"))%>';
  ihtml += '<div class="query_review <%= parent_div_class %>" id = "query_review_header_'+i+'">';
  ihtml += '<%= escape_javascript(render(:partial => "/box_header"))%>';
  ihtml += '</div>    ';
  ihtml += '<div class="query_review_details" id="query_review_details_'+i+'" style="display: none;">';
  ihtml += '<%= escape_javascript(render(:partial => enabled_by_cookie ? "/box_body" : "/box_disabled")) %>';
  ihtml += '</div>';

  container_div.innerHTML = ihtml;

  var parent_div = document.getElementById("query_review_parent")
  if(!parent_div) {
    parent_div = document.createElement("div");
    parent_div.setAttribute("id", "query_review_parent");
    parent_div.className = "query_reivew_parent";
    document.getElementById("body")[0].appendChild(parent_div);
  }

  parent_div.appendChild(container_div);
}