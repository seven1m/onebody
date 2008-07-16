<?php
/********************************************************************
 * openImageLibrary addon v0.2.2 Copyright (c) 2006 openWebWare.com
 * Contact us at devs@openwebware.com
 * This copyright notice MUST stay intact for use.
 * 
 * $Id: config.inc.php,v 1.7 2006/12/17 21:34:28 xhaggi Exp $
 * 
 * An open source image library addon for the openWYSIWYG.
 * This library gives you the possibility to upload, browse and select 
 * images on your webserver.
 * 
 * Requirements: 
 * - PHP 4.1.x or later
 * - openWYSIWYG v1.4.6 or later
 ********************************************************************/
 
/*
 * Path to a directory which holds the images.
 */
$imagebasedir = '../../uploads';

/*
 * An absolute or relative URL to the image folder.
 * This url is used to generate the source of the image.
 */
$imagebaseurl = 'uploads';

/*
 * Allow your users to browse the subdir of the defined basedir.
 */
$browsedirs = true;

/*
 * If enabled users will be able to upload 
 * files to any viewable directory. You should really only enable
 * this if the area this script is in is already password protected.
 */
$allowuploads = true;

/*
 * If a user uploads a file with the same
 * name as an existing file do you want the existing file
 * to be overwritten?
*/
$overwrite = false;

/*
 * Define the extentions you want to show within the 
 * directory listing. The extensions also limit the 
 * files the user can upload to your image folders.   
 */
$supportedextentions = array(
	'gif', 
	'png', 
	'jpeg', 
	'jpg',
	'bmp'
);
			
/*
 * If you want to add your own special file icons use 
 * this section below. Each entry relates to the extension of the 
 * given file, in the form <extension> => <filename>. 
 * These files must be located within the dlf directory.
 */
$filetypes = array (
	'png' => 'jpg.gif',
	'jpeg' => 'jpg.gif',
	'bmp' => 'jpg.gif',
	'jpg' => 'jpg.gif', 
	'gif' => 'gif.gif',
	'psd' => 'psd.gif',
);
	
?>
