Hydra = {}

assert = (cond) ->
    if !cond
        alert("Failed condition")
        debugger

_setupMenubar = ->
    dojo.require("dijit.MenuBar")
    dojo.require("dijit.PopupMenuBarItem")
    dojo.require("dijit.Menu")
    dojo.require("dijit.MenuItem")
    dojo.require("dojo.dnd.Source")

    dojo.ready ->
        pMenuBar = new dijit.MenuBar({});

        pSubMenu = new dijit.DropDownMenu({});
        pSubMenu.addChild(new dijit.MenuItem({
            label:"New Project"
        }));
        pSubMenu.addChild(new dijit.MenuItem({
            label:"Create Data Source",
            onClick: () -> Hydra.onCreateDataSource()
        }));
        pSubMenu.addChild(new dijit.MenuItem({
            label:"Create Transformer"
        }));
        pSubMenu.addChild(new dijit.MenuItem({
            label:"Create Plot"
        }));
        pMenuBar.addChild(new dijit.PopupMenuBarItem({
            label:"File",
            popup:pSubMenu
        }));

        pSubMenu2 = new dijit.DropDownMenu({});
        pSubMenu2.addChild(new dijit.MenuItem({
            label:"Edit item #1"
        }));
        pSubMenu2.addChild(new dijit.MenuItem({
            label:"Edit item #2"
        }));
        pMenuBar.addChild(new dijit.PopupMenuBarItem({
            label:"Edit",
            popup:pSubMenu2
        }));

        pMenuBar.placeAt("titlebar");
        pMenuBar.startup();

class Hydra.DataSource extends Panel.Page
    constructor: () ->
        super()
        @name = "Source"

    getTabText: () ->
        return @name

    getTabIcon: () ->
        return "blank.gif"

    getBodyElement: () ->
        return "<div><b>Source!</b></div>"


Hydra.onCreateDataSource = ->
    page = new Hydra.DataSource()
    Hydra.panel.addPage(page)
    

        
class Hydra.ProjectList extends Panel.Page
    constructor: () ->
        
    getTabText: () ->
        return "Project"

    getTabIcon: () ->
        return "blank.gif"

    getBodyElement: () ->
        return @body


_setupComms = (socket, layout) ->
    socket = io.connect('http://localhost')
    socket.on('hello', (data) ->
        console.log("Connected to: #{data.app}-#{data.version}")
        socket.emit('getTUList', {})
    )
    socket.on('TUList', (data) ->
        console.log("Got TU List: #{data}")
        Hydra.panel.addPage(new Hydra.ProjectFilesList())
    )


#Hydra.showExpanders = ->
#    for s in ['.panel-corner', '.panel-ns', '.panel-we']
#        $(s).addClass('expanded')

#Hydra.hideExpanders = ->
#    for s in ['.panel-corner', '.panel-ns', '.panel-we']
#        $(s).removeClass('expanded')



# The entry point to the view tree.
Hydra.panel = null

# The comm socket entry point.
Hydra.socket = null

main = ->
    _setupMenubar()

    # expand to the full window size and maintain it
    $('#full-page').width($(window).innerWidth())
    $('#full-page').height($(window).innerHeight())

    # install the root panel
    Hydra.panel = new Panel($('#app-area'))
    #$('#app-area').replaceWith(Hydra.tree.getHtml())
    #tabs = Hydra.tree.insertSubLayout(new Hydra.TabView())
    #tabs.insertPage(new Hydra.Document("hello"))
    #tabs.insertPage(new Hydra.Document("world"))

    _setupComms(Hydra.socket, Hydra.tree)

