/********************************************************************
 * openWYSIWYG popup functions Copyright (c) 2006 openWebWare.com
 * Contact us at devs@openwebware.com
 * This copyright notice MUST stay intact for use.
 *
 * $Id: wysiwyg-popup.js,v 1.2 2007/01/22 23:45:30 xhaggi Exp $
 ********************************************************************/
var WYSIWYG_Popup = {

	/**
	 * Return the value of an given URL parameter.
	 * 
	 * @param param Parameter
	 * @return Value of the given parameter
	 */
	getParam: function(param) {
	  var query = window.location.search.substring(1);
	  var parms = query.split('&');
	  for (var i=0; i<parms.length; i++) {
	    var pos = parms[i].indexOf('=');
	    if (pos > 0) {
	       var key = parms[i].substring(0,pos).toLowerCase();
	       var val = parms[i].substring(pos+1);
	       if(key == param.toLowerCase()) 
	       	return val;
	    }
	  }
	  return null;
	}
}

// close the popup if the opener does not hold the WYSIWYG object
if(!window.opener) window.close();

// bind objects on local vars
var WYSIWYG = window.opener.WYSIWYG;	
var WYSIWYG_Core = window.opener.WYSIWYG_Core;
var WYSIWYG_Table = window.opener.WYSIWYG_Table;