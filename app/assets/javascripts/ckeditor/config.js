CKEDITOR.editorConfig = function(config) {
  //config.language = 'es'; //this could be any language
  //config.width = '800';
  config.height = '400';
  config.uiColor = "#367fa9";
  config.toolbar_Menu = [
    { name: 'document', items: ['Preview', '-', 'Print', '-', 'Templates'] }, 
    { name: 'clipboard', items: ['Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord', '-', 'Undo', 'Redo'] }, 
    { name: 'editing', items: ['Find', 'Replace', '-', 'SelectAll', '-', 'SpellChecker', 'Scayt'] }, 
    { name: 'tools', items: ['Maximize', 'ShowBlocks', '-', 'About'] }, 
    { name: 'basicstyles', items: ['Bold', 'Italic', 'Underline', 'Strike'] }, 
    { name: 'paragraph', items: ['NumberedList', 'BulletedList', '-', 'Outdent', 'Indent', '-', 'Blockquote', '-', 'JustifyLeft', 'JustifyCenter', 'JustifyRight', 'JustifyBlock', '-', 'BidiLtr', 'BidiRtl'] }, 
    { name: 'links', items: ['Link', 'Unlink'] },
    { name: 'styles', items: ['Styles', 'Format', 'Font', 'FontSize'] }, 
    { name: 'colors', items: ['TextColor', 'BGColor'] }, 
    { name: 'insert', items: ['Table', 'HorizontalRule', 'Smiley', 'SpecialChar', 'PageBreak'] }
  ];
  config.toolbar = 'Menu';
  return true;
};