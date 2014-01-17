/* Image Modal Dialog for upload or selection of existing images.
   This was adapted from Bass Jobsen's mod of wysihtml5 image upload
   and Rcode5's modification thereof (github.com/rcode5/image-wysiwyg-sample).
 */

var xhrFetchingImages;

wysiHelpers = {
  getImageTemplate: function() {
    /* this is what goes in the wysiwyg content after the image has been chosen */
    var tmpl;
    tmpl = _.template("<img class='<%= klass %>' src='<%= url %>' alt='<%= caption %>'>");
    return tmpl;
  }
};

bootWysiOverrides = {
  initInsertImage: function(toolbar) {
    var self = this;
    var insertImageModal = toolbar.find('.bootstrap-wysihtml5-insert-image-modal');
    var urlInput = insertImageModal.find('.bootstrap-wysihtml5-insert-image-url');
    var insertButton = insertImageModal.find('a.btn-primary');
    var initialValue = urlInput.val();

    var jsonSource = document.location.pathname.match(/^.*sites\/[0-9]+/i) + '/groups/images.json';
    
    var chooser = insertImageModal.find('.image_chooser.images');
    var chooserSave = insertImageModal.find('.insert_image_save');
    var chooserPreview = insertImageModal.find('.image_chooser_preview');
    var chooserResolutionSelect = insertImageModal.find('.resolution_select');
    var chooserOrientationSelect = insertImageModal.find('.orientation_select');
    
    var helpers = wysiHelpers;

    // get a fancytree chooser going
    // TODO: this get's called once for each wysiwyg on the page.  we could
    //       be smarter and cache the results after call 1 and use them later.
    enableFancychooser(chooser, jsonSource);

    var getDataFromChosen = function(el) {
       var chosen = el || chooser.find('.fancytree-active');
        var chosenData = chosen.find('.image-data');
        if(chosenData) { chosen = chosenData; }
        return chosen.data();
    };

    var insertImage = function() {
      var imgData = getDataFromChosen(null);
      if(imgData.url) {
        var clz = 'image_container';
        var doc = self.editor.composer.doc;
        var tmpl = helpers.getImageTemplate();
        var insertData = {
            url: imgData.url,
            caption: imgData.caption,
            klass: chooserOrientationSelect.find('select').val() || 'centered'
        };
        if(imgData.url2) {
           if(chooserResolutionSelect.find('.resized_image_resolution[type=radio]:checked').val() == 'resized') {
               insertData.url = imgData.url2;
           }
        }
        var chunk = tmpl(insertData);
        self.editor.focus();
        self.editor.composer.commands.exec("insertHTML", chunk);
        /* reset */
        chooserResolutionSelect.hide();
        chooserOrientationSelect.hide();
        chooserPreview.hide();
        chooserPreview.attr('src','');
        insertImageModal.find('.uploadresult').html('');
        $('#image_file').val('');
        insertImageModal.find('.fancytree_chooser').show();
        insertImageModal.modal('hide');
      }
    };

    var previewImageFile = function(imgData) {
        chooserPreview.attr('src',imageData.url);
        insertImageModal.find('.fancytree_chooser').hide();
        chooserPreview.show();
        if(imageData.url2) {
            chooserResolutionSelect.show();
        }
        chooserOrientationSelect.show();
    };

    chooserSave.on('click', function(ev) {
      insertImage();
    });
    
    chooser.on('click', '.fancytree-node:not(.fancytree-folder)', function(ev) {
      var imageData = getDataFromChosen($(ev.currentTarget));
      chooserPreview.attr('src',imageData.url);
      insertImageModal.find('.fancytree_chooser').hide();
      chooserPreview.show();
      if(imageData.url2) {
          chooserResolutionSelect.show();
      }
      chooserOrientationSelect.show();
    });
    
    insertImageModal.on('hide', function() {
      self.editor.currentView.element.focus();
    });
    
    toolbar.find('a[data-wysihtml5-command=insertImage]').click(function() {
      var activeButton = $(this).hasClass("wysihtml5-command-active");
      
      if (!activeButton) {
        insertImageModal.modal('show');

          chooserResolutionSelect.hide();
          chooserOrientationSelect.hide();
          chooserPreview.hide();
          chooserPreview.attr('src','');
          insertImageModal.find('.uploadresult').html('');
          $('#image_file').val('');
          insertImageModal.find('.fancytree_chooser').show();
        
        $('#image_file').change(function() {
          $(this).uploadimage('/upload', function(res) {
            if(res.status)
            {
	      // TODO: reload AJAX data
          insertImageModal.find('.uploadresult').html('Upload successful').addClass('alert alert-success');
	    }
	    else
	    {
          insertImageModal.find('.uploadresult').html('Upload failed').addClass('alert alert-error');
            }		
          }, 'json');
        });

        insertImageModal.on('click.dismiss.modal', '[data-dismiss="modal"]', function(e) {
          e.stopPropagation();
        });
        return false;
      }
      else {
        // re-init
        chooser.find('.selected').removeClass('selected');
        insertImageModal.find('.fancytree_chooser').show();
        chooserResolutionSelect.hide();
        chooserPreview.hide();
        chooserOrientationSelect.hide();
        return true;
      }
    });
  }
};

$.extend($.fn.wysihtml5.Constructor.prototype, bootWysiOverrides);

$(function() {

  // override options
  var wysiwygOptions = {
    customTags: {
      "em": {},
      "strong": {},
      "hr": {}
    },
    customStyles: {
      // keys with null are used to preserve items with these classes, but not show them in the styles dropdown
      'shrink_wrap': null,
      'credit': null,
      'tombstone': null,
      'chat': null,
      'caption': null
    }
  };

  $('.tip').tooltip();
  $('textarea.wysi').each(function() {
    $(this).wysihtml5($.extend(wysiwygOptions, {html:true, color:false, stylesheets:[]}));
  });
});
