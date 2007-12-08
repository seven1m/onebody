/*
  = Test Framework
    version 1.0
    created by M@ McCray (http://www.mattmccray.com)
  
  This is a simple JavaScript test framework.
  
  = TODO:
  
   * Add support for calling Tests.setup() and Tests.teardown()
   * Documentation!
   * Add support for methods that don't start with 'test'?
   * Make test method names more English?
*/

// We're gonna run all this in it's own scope so it doesn't pollute the test namespace
(function(){
  var HTML = {
    _all_tags: ['a','abbr','acronym','address','area','b','base','bdo','big','blockquote','body','br','button','caption','cite','code','col','colgroup','dd','del','dfn','div','dl','DOCTYPE','dt','em','fieldset','form','h1','h2','h3','h4','h5','h6','head','html','hr','i','img','input','ins','kbd','label','legend','li','link','map','meta','noscript','object','ol','optgroup','option','p','param','pre','q','samp','script','select','small','span','strong','style','sub','sup','table','tbody','td','textarea','tfoot','th','thead','title','tr','tt','ul'],
    _init: function() {
      for(var $i=0; $i<this._all_tags.length; $i++) {
        var $tag = this._all_tags[$i]
        eval( 'HTML.'+ $tag +' = function (){ return HTML._write_tag("'+ $tag +'", arguments); }' );
        //this[$tag] = new Function("return HTML._write_tag('"+ $tag +"', arguments);")
        this.namespace += ';var '+ $tag +' = HTML.'+ $tag;
      }
    },
    _write_tag: function(tag, options) {
      var $content = ''; var $atts = "";
      for(var $i=0; $i<options.length; $i++) {
        var $arg = options[$i];
        if (typeof($arg) == 'string' || typeof($arg) == 'number')
          $content += $arg.toString();
        else if (typeof($arg) == 'function')
          $content += $arg();
        else if ( $arg instanceof Object)
          for($prop in $arg) $atts += ' '+ $prop +'="'+ $arg[$prop] +'"'; 
      }
      if($content == '')
        return '<'+ tag + $atts +'/>';
      else
        return '<'+ tag + $atts +'>'+ $content +'</'+ tag +'>';
    },
    namespace: 'var text = HTML.text',
    toString: function() { return this.namespace; },
    text: function() { 
      var $content=''; 
      for(var $i=0; $i<arguments.length; $i++) $content += arguments[$i].toString(); 
      return $content; 
    }
  };
  HTML._init();
  eval(HTML.namespace);
  
  var list_html = "";
  var page_title = "Test Cases";
  var page_desc = "";
  
  window.methodList = [];
  if( typeof(Tests) != 'undefined' ) {
    if(Tests.title) page_title = Tests.title;
    if(Tests.description) page_desc = Tests.description;

    for(func in Tests) {
      if(/test/.test(func)) {
        methodList.push(func);
        list_html += li ({id:func, 'class':'untested'},
          span (func.toString()),
          div (' ', {id: (func +'-error')})
        )
      }
    }    
  } else {
    list_html = li('No tests defined!', {'class':'fail'})
  }
  
// Generate HTML

  if( page_desc != '' ) page_desc = p( page_desc,{'class':'description'});
  
  document.write( 
    head (
      title ( "(", page_title, ")", " :: JavaScript Test Framework" ),
      style (
        "BODY { font-family:Helvetica,Verdana,Sans-Serif; background:#E0E0E0; }",
        "LI { padding:3px; }",
        "H1 { margin-top:0; color:navy; }",
        "INPUT { font-size:105%; font-weight:bold; }",
        "#main { width:650px; margin:0 auto; background:#FFF; padding:20px; border:1px solid #BBB; }",
        "#status { padding:10px; }",
        "#sidebar { background:#F0F0F0; float:right; width:200px; padding:5px 15px; font-size:85%; border:10px solid white; border-top:0px; }",
        ".description { background:#FFC; padding:10px; font-size:85%;   }",
        ".credit { padding:0px 2px; font-size:90%; color:gray; }",
        ".untested { color:#C5C5C5; }",
        ".untested SPAN { color:black; }",
        ".pass { color:#0F0; }",
        ".pass SPAN { color:#363; }",
        ".fail { color:red; }",
        ".fail DIV { font-size:85%; color:#666; }",
        ".fail SPAN { color:maroon; }",
        ".fail UL { margin:0px; padding:0px; padding-left:10px; list-style:none; }",
        ".fail LI { padding:2px;  }",
        ".assertion-type { color:black !important; font-weight:bold; }",
        ".exception-type { color:red !important; font-weight:bold; }"
      )
    ),
    body (
      div ({id:'main'},
        div ({id:'sidebar'},
          p ("This is a simple JavaScript test framework."),
          p ("To read the tests, just view-source."),
          p ("Created by M@ McCray. Released under the MIT license.", {'class':'credit'})
        ),
        h1 (page_title),
        page_desc,
        ul ({id:'test-list'},
          list_html
        ),
        table( tr(
          td(
            input ({ type:'button', onclick:'runAllTests()', value:'Run All Tests'})
          ),
          td(
            div ('&nbsp;',{id:'status'})
          )
        ))
      ),
      div ('&nbsp;', {id:'work-area'})
    )
  );

  window.assertionCount = 0;
  window.assertionFailCount = 0;
  window.assertionErrorCount = 0;
  
  var assertionFailures = [];

  // Exported functions
  window.runAllTests = function() {
    var errors = [];
    assertionCount = 0;
    assertionFailCount = 0;
    
    forEach(methodList, function(func){
      setStatus('Evaluating '+ func +'...');
      
      assertionFailures = [];
      assertionExceptions = [];
      try {
        Tests[func]()
      } catch (ex) {
        assertionErrorCount++;
        assertionExceptions.push(ex)
      }
      if( assertionFailures.length == 0 && assertionExceptions.length == 0) {
        $(func).className = 'pass';
      } else {
        $(func).className = 'fail';
        var results = ""

        forEach(assertionFailures, function(err){
          results += li (
            span (err.assertionType, {'class':'assertion-type'}), ': ',
            (err.message || err.extraInformation)
          );
        });

        forEach(assertionExceptions, function(err){
          results += li (
            span ('Error', {'class':'exception-type'}), ': ',
            (err.description || err.message || err)
          );
        });
        
        setResults( func, ul (results) )
      }
    });

    setStatus( div (
      assertionCount,
      " assertions, ",
      span ((assertionCount - assertionFailCount), {'class':'pass'}), 
      " passed",
      show_if (assertionFailCount, text( ", ",
        span (assertionFailCount, {'class':'fail'}),
        " failed" )
      ),
      show_if (assertionErrorCount, text( ", ",
        span (assertionErrorCount, {'class':'fail'}),
        " error(s)")
      ), 
      "."
    ));
  }
  
// Assertions
  window.assert = function(condition, msg) {
    window.assertionCount++;
    if(!condition) {
      ex = 'true was expected, but value was '+ condition;
      assertError(msg, 'assert', ex);
    }
  }

  window.assertFalse = function(condition, msg) {
    window.assertionCount++;
    if(condition) {
      ex = 'false was expected, but value was '+ condition;
      assertError(msg, 'assertFalse', ex);
    }
  }

  window.assertNull = function(condition, msg) {
    window.assertionCount++;
    if(null != condition) {
      ex = 'null was expected, but value was '+ condition;
      assertError(msg, 'assertNull', ex);
    }
  }

  window.assertNotNull = function(condition, msg) {
    window.assertionCount++;
    if(null == condition) {
      ex = 'null was not expected, but value was '+ condition;
      assertError(msg, 'assertNotNull', ex);
    }    
  }

  window.assertEqual = function(condition1, condition2, msg) {
    window.assertionCount++;
    ex = condition1 +' was expected, but value was '+ condition2;
    if(condition1 != condition2) {
      assertError(msg, 'assertEqual', ex);
    }
  }
  
  window.assertNotEqual = function(condition1, condition2, msg) {
    window.assertionCount++;
    if(condition1 == condition2) {
      ex = condition1 +' was not expected, but value was '+ condition2;
      assertError(msg, 'assertNotEqual', ex);
    }
  }
  
  window.assertUndefined = function(object, msg) {
    window.assertionCount++;
    if(object != 'undefined' ) {
      ex = object +' was defined';
      assertError(msg, 'assertUndefined', ex);
    }
  }

  window.assertDefined = function(object, msg) {
    window.assertionCount++;
    if(object == 'undefined' ) {
      ex = object +' was undefined';
      assertError(msg, 'assertDefined', ex);
    }
  }
  
// Private functions
  function $(elem) {
    return document.getElementById(elem);
  }
  
  function log() {
    var msg = [];
    forEach(arguments, function(arg){ msg.push( arg || '' ); });
    if(window.console && window.console.log) {
      window.console.log(msg.join(' '))
    } else if(window.console && window.console.info) {
      window.console.info(msg.join(' '))
    }
  }
  
  function forEach(array, block, context) {
      for (var i = 0; i < array.length; i++) {
        block.call(context, array[i], i, array);
      }
  }
  
  function show_if(list, html) {
    if(list > 0)
      return html;
    else
      return '';
  }
  
  function setStatus(msg) {
    $('status').innerHTML = msg;
  }
  
  function setResults(func, msg) {
    $(func+'-error').innerHTML = msg;
  }
  
  function assertError(errorMessage, assertionType, extraInfo) {
    window.assertionFailCount++;
    assertionFailures.push({
      assertionType: assertionType,
      message: errorMessage,
      extraInformation: extraInfo.toString().replace(/</g, '&lt;'),
      description: errorMessage +"\n"+ extraInfo.toString().replace(/</g, '&lt;')
    });
  }

})();