/* Inserts Anchors and Link Elements for internal page navigation */

function initPageNav(list, selector) {
    var idx = 0;
    $(selector).each(function() {
       var name = $(this).html().trim();
       if(name == '') { return; }
       var id = idx++;
       var newLink = document.createElement('a');
       $(newLink).attr('href', '#section' + id);
       newLink.innerHTML = name;
       var listItem = document.createElement('li');
       $(listItem).append(newLink);
       $(list).append(listItem);
       $(this).attr('id', 'section' + id);
    });
}