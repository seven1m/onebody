/********************************************************************
 * openWYSIWYG color chooser Copyright (c) 2006 openWebWare.com
 * Contact us at devs@openwebware.com
 * This copyright notice MUST stay intact for use.
 *
 * $Id: wysiwyg-color.js,v 1.1 2007/01/29 19:19:49 xhaggi Exp $
 ********************************************************************/
function WYSIWYG_Color() {
	
	// colors
	var COLORS = new Array(
		"#000000","#993300","#333300","#003300","#003366","#000080",
		"#333399","#333333","#800000","#FF6600","#808000","#008000",
		"#008080","#0000FF","#666699","#808080","#FF0000","#FF9900",
		"#99CC00","#339966","#33CCCC","#3366FF","#800080","#999999",
		"#FF00FF","#FFCC00","#FFFF00","#00FF00","#00CCFF","#993366",
		"#C0C0C0","#FF99CC","#FFCC99","#FFFF99","#CCFFCC","#CCFFFF",
		"#99CCFF","#666699","#777777","#999999","#EEEEEE","#FFFFFF"	
	);
	
	// div id of the color table
	var CHOOSER_DIV_ID = "colorpicker-div";

	/**
	 * Init the color picker
	 */
	this.init = function() {
		var div = document.createElement("DIV");
		div.id = CHOOSER_DIV_ID;
		div.style.position = "absolute";
		div.style.visibility = "hidden";		
		document.body.appendChild(div);
	};
	
	
	/**
	 * Open the color chooser to choose a color.
	 * 
	 * @param {String} element Element identifier 
	 */
	this.choose = function(element) {
		var div = document.getElementById(CHOOSER_DIV_ID);
		if(div == null) {
			alert("Initialisation of color picker failed.");
			return;
		}
				
		// writes the content of the color picker
		write(element);
								
		// Display color picker
		var x = window.event.clientX + document.body.scrollLeft;
		var y = window.event.clientY + document.body.scrollTop;
		var winsize = windowSize();
		if(x + div.offsetWidth > winsize.width) x = winsize.width - div.offsetWidth - 5;
		if(y + div.offsetHeight > winsize.height) y = winsize.height - div.offsetHeight - 5;
		div.style.left = x + "px";
		div.style.top = y + "px";
		div.style.visibility = "visible";				
	};
	
	/**
	 * Set the color in the given field
	 *
	 * @param {String} n Element identifier
	 * @param {String} color HexColor String
	 */
	this.select = function(n, color) {
		var div = document.getElementById(CHOOSER_DIV_ID);
		var elm = document.getElementById(n);
		elm.value = color;
		elm.style.color = color;
		elm.style.backgroundColor = color;
		div.style.visibility = "hidden";
	}
	
	
	/**
	 * Write the color table
	 * @param {String} n Element identifier
	 * @private
	 */
	function write(n) {
		
		var div = document.getElementById(CHOOSER_DIV_ID);
		
		var output = "";
		output += '<table border="1" cellpadding="0" cellspacing="0" class="wysiwyg-color-picker-table"><tr>';
		for(var i = 0; i < COLORS.length;i++) {
			var color = COLORS[i];
			output += '<td class="selectColorBorder" ';
			output += 'onmouseover="this.className=\'selectColorOn\';" ';
			output += 'onmouseout="this.className=\'selectColorOff\';" ';
			output += 'onclick="WYSIWYG_ColorInst.select(\'' + n + '\', \'' + color + '\');"> ';
			output += '<div style="background-color:' + color + ';" class="wysiwyg-color-picker-div">&nbsp;</div> ';
			output += '</td>';
			
			if(((i+1) % Math.round(Math.sqrt(COLORS.length))) == 0) {
				output += "</tr><tr>";
			}
		}
		
		output += '</tr></table>';	
		
		// write to div element
		div.innerHTML = output;
	};
	
	/**
	 * Set the window.event on Mozilla Browser
	 * @private
	 */
	function _event_tracker(event) { 
		if (!document.all && document.getElementById) {
			window.event = event;
		}
	}	
	document.onmousedown = _event_tracker;
	
	/**
	 * Get the window size
	 * @private
	 */
	function windowSize() {
		if (window.innerWidth) {
	  		return {width: window.innerWidth, height: window.innerHeight};
	  	} 
		else if (document.body && document.body.offsetWidth) {
	  		return {width: document.body.offsetWidth, height: document.body.offsetHeight};
	  	} 
		else {
	  		return {width: 0, height: 0};
	  	}
	}
}

var WYSIWYG_ColorInst = new WYSIWYG_Color();