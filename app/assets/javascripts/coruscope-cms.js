/* Utility Functions for JS navigation UI */

$(document).ready(function(){
    $("[data-copy] form").submit(copyFormData)
});

function copyFormData() {
    $(this).children('[data-copy][type="hidden"]').each(function(i){
        var copyField = $(this).attr('data-copy');
        var copyValue = $('input[data-'+copyField+'=true]').val();
        if(copyValue) {
            $('#copy_' + copyField).val(copyValue);
        }
    });
}

function loadOnFancytreeAction(url, method, parameters) {
    var updateElement = $('#dynamic-content');
    $('#dynamic-overlay').show();
    if(!parameters) {
        parameters = {};
    }
    switch(method) {
        case 'POST':
            $.post(url, parameters).done(function(data) {
                updateElement.html(data);
            }).always(function(){
                $('#dynamic-overlay').hide();
            });
            break;
        default:
            $.get(url, parameters).done(function(data) {
                updateElement.html(data);
            }).always(function(){
                $('#dynamic-overlay').hide();
            });
    }
    $.get(url, function(data) {
        updateElement.html(data);
    }).always(function(){
        $('#dynamic-overlay').hide();
    });
}

function enableFancytree(selector, dataUrl, options) {
    if(!window.fancytrees) {
        window.fancytrees = {};
    }
    window.fancytrees[selector] = $(selector).fancytree({
        // minExpandLevel: 1,
        extensions: [
            'dnd', 'persist'
        ],
        source: { url: dataUrl},
        persist: {
            cookiePrefix: 'ft-' + selector.match(/\w+/)[0] + '-',
            cookie: {
                expires: 1
            },
            types: 'active expanded'
        },
        dnd:
        {
            preventVoidMoves: true, // Prevent dropping nodes 'before self', etc.
            preventRecursiveMoves: true, // Prevent dropping nodes on own descendants
            autoExpandMS: 400,
            onDragStart: function(node) {
                // This function MUST be defined to enable dragging for the tree.
                // Return false to cancel dragging of node.
                return true;
            },
            onDragEnter: function(node, sourceNode) {
                // sourceNode may be null for non-fancytree droppables.
                // Return false to disallow dropping on node. In this case
                // onDragOver and onDragLeave are not called.
                // Return 'over', 'before, or 'after' to force a hitMode.
                // Return ['before', 'after'] to restrict available hitModes.
                // Any other return value will calc the hitMode from the cursor position.
                //
                // Prevent dropping a parent below another parent (only sort
                // nodes under the same parent)
                //   if(node.parent !== sourceNode.parent){
                //     return false;
                //   }
                // Don't allow dropping *over* a node (would create a child)
                // return ["before", "after"];
                //
                return true;
            },
            onDrop: function(node, sourceNode, hitMode, ui, draggable) {
                // This function MUST be defined to enable dropping of items on
                // the tree.
                sourceNode.moveTo(node, hitMode);
            }
        },
        lazyload: function(event, data) {
            var node = data.node;
            data.result = {
                url: dataUrl,
                data: {node: node.key},
                cache: false
            }
        },
        click: function(event, data) {
            var node = $(data.originalEvent.target);
            if(node.parents('.node-actions').length != 0) {
                // ensure action node not display element
                while(!node.parent().hasClass('node-actions')) {
                    node = node.parent();
                }
                // handle node action events
                var actions = node.attr('class').split('-');
                var nodeData = data.node.data;
                if(nodeData.href) {
                    for(var i=0; i < actions.length; i++) {
                        switch(actions[i]) {
                            case 'edit':
                                // GET request on nodeData.href
                                loadOnFancytreeAction(nodeData.href, 'GET', null);
                                break;
                            case 'delete':
                                alert('Called DELETE');
                                break;
                        }
                    }
                }
            } else {
                // move node actions into the current node
                if(!node.hasClass('fancytree-node')) {
                    node = node.parents('.fancytree-node');
                }
                // Remove and reinsert actionControls into the node
                var actionControl = data.tree.$div.find('.node-actions');
                if(node != actionControl.parent()) {
                    actionControl.detach();
                    node.append(actionControl);
                    actionControl.show();
                }
            }
        }
    });
    window.fancytrees[selector].dataUrl = dataUrl;
    $(selector).css('position', 'relative');
    var actionControl = $('<div/>',{
        class: 'node-actions',
        style: 'position: absolute; top: 0; right: 0; display: none;'
    });
    actionControl.append($('<a/>', {
        html: '<i class="icon-edit"/>',
        title: 'Bearbeiten',
        class: 'node-edit',
        style: 'cursor: pointer;'
    }));
    actionControl.append($('<a/>', {html: '<i class="icon-remove"/>', title: 'Löschen', class: 'node-delete', style: 'cursor: pointer;'}));
    $(selector).append(actionControl);
};

/* A select-like element */
function enableFancychooser(selector, dataUrl) {
    $(selector).fancytree({
        minExpandLevel: 1,
        // prevent navigation on re-load
        postinit: function(isReloading, isError) {
            this.reactivate();
        },
        extensions: [
            // , 'persist'
        ],
        source: { url: dataUrl},
        //[
        //{ title: '#{t('admin.cms.base.sites')}', href: '#{admin_cms_sites_path}' },
        //{ title: '#{@site.label} actions', key: 'actions', folder: true, children:
        //[
        //{ title: '#{t('admin.cms.base.layouts')}', href: '#{admin_cms_site_layouts_path(@site)}'},
        //{ title: '#{t('admin.cms.base.pages')}', href: '#{admin_cms_site_pages_path(@site)}'},
        //{ title: '#{t('admin.cms.base.snippets')}', href: '#{admin_cms_site_snippets_path(@site)}'},
        //{ title: '#{t('admin.cms.base.files')}', href: '#{admin_cms_site_files_path(@site)}'}
        //]
        //}],
        /*,
        click: function(event, data) {
            var node = data.node;
            // Use href attribute to load the content
            if( node.data.href ){
                // Open target via AJAX and update dynamic-content
                $.get(node.data.href, function(data) {
                    $('#dynamic-content').html(data);
                });
            }
        }
        */
    })
};