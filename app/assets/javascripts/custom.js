/* Inserts Anchors and Link Elements for internal page navigation */

function initPageNav(list, selector, offset) {
    var idx = 0;
    var navId = $(list).parent('div, nav').attr('id');
    $(selector).each(function() {
       var name = $(this).html().trim();
       if(name == '') { return; }
       var id = idx++;
       var newLink = document.createElement('a');
       $(newLink).attr('href', '#section' + id);
       $(newLink).attr('id', 'goto-section' + id);
       newLink.innerHTML = name;
       var listItem = document.createElement('li');
       $(listItem).append(newLink);
       $(list).append(listItem);
       $(this).attr('id', 'section' + id);
       $(this).addClass('goto-section' + id);
    });
    if(idx == 0) {
        $(navId).remove();
    } else {
        $('#' + navId).smint({verticalOffset: offset || 0});
    }
}