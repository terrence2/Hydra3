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
            label:"File item #1"
        }));
        pSubMenu.addChild(new dijit.MenuItem({
            label:"File item #2"
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



Hydra.showExpanders = ->
    for s in ['.panel-corner', '.panel-ns', '.panel-we']
        $(s).addClass('expanded')

Hydra.hideExpanders = ->
    for s in ['.panel-corner', '.panel-ns', '.panel-we']
        $(s).removeClass('expanded')


class Hydra.Page


class Hydra.Layout
    constructor: () ->
        @elmt = null
        @children = []

    insert: (child) ->
        @children.push(child)

class Hydra.VSplit extends Hydra.Layout
    insert: (child) ->
        super(child)
        return child

    attachHtml: (elmt) ->
        parent = $(elmt).parent()
        initHeight = Math.ceil($(parent).height() / 2);
        $(elmt).replaceWith("""
          <div class="vsplit split-container">
            <div class="split-top" style="height:#{initHeight}px"></div>
            <div class="vsplit-handle split-handle"></div>
            <div class="split-bottom"></div>
          </div>
        """)

class Hydra.Panel extends Hydra.Layout
    insert: (child) ->
        super(child)
        elmt = child.attachHtml(@insertElmt)
        elmt.addClass('panel-content')
        return child

    attachHtml: (elmt) ->
        parent = $(elmt).parent()
        $(elmt).replaceWith("""
          <div class="panel-container">
              <div class="panel-ns-container">
                <div class="panel-corner"></div>
                <div class="panel-ns panel-north"></div>
                <div class="panel-corner"></div>
              </div>
              <div class="panel-center-container">
                <div class="panel-we panel-west"></div>
                <div class="panel-content"></div>
                <div class="panel-we panel-east"></div>
              </div>
              <div class="panel-ns-container">
                <div class="panel-corner"></div>
                <div class="panel-ns panel-south"></div>
                <div class="panel-corner"></div>
              </div>
          </div>
        """)
        @elmt = $("div.panel-container", parent)
        @insertElmt = $("div.panel-center-container>div.panel-content", @elmt)
        for dir in ['north', 'south', 'east', 'west']
            this[dir + 'Elmt'] = $(".panel-" + dir, @elmt)[0]
            this[dir + 'Drop'] = src = dojo.dnd.Source(this[dir + 'Elmt'])
        dojo.connect(@northDrop, 'onDrop', (src, nodes, copy) =>
            @splitNorth()
        )
        return @insertElmt

    splitNorth: () ->
        assert(@children.length == 1)
        # grab prior child so we can re-root it inside the panel
        priorChild = @children[0]
        priorParent = $(@elmt).parent()
        # create the new thing we will root here
        @children[0] = new Hydra.VSplit()
        # Replace the panel with a temp div.
        tgt = $(@elmt).replaceWith("""<div class="target">""")
        # Replace the temp div with the new vsplitter.
        debugger
        @children[0].attachHtml($(".target", priorParent))


# A set of tabs embeddable into an H/VPane or a Panel
class Hydra.TabView extends Hydra.Layout
    # Add a Hydra.Page derived class to this tabview.
    insert: (page) ->
        super(page)
        @dragSource.insertNodes(false, [page.getTabText()])
        return page

    attachHtml: (elmt) ->
        parent = $(elmt).parent()
        $(elmt).replaceWith("""
          <div id="#{@id}" class="tabview-container">
            <div class="tabview-tabs">
            </div>
            <div class="tabview-area">
            </div>
          </div>
        """)
        @elmt = $("div.tabview-container", parent)
        @tabElmt = $("div.tabview-tabs", @elmt)
        @viewElmt = $("div.tabview-area", @elmt)
        @dragSource = dojo.dnd.Source($(@tabElmt)[0])
        dojo.connect(@dragSource, 'onDndCancel', (evt) -> Hydra.hideExpanders())
        dojo.connect(@dragSource, 'onDndDrop', (evt) -> Hydra.hideExpanders())
        dojo.connect(@dragSource, 'onDndStart', (evt) -> Hydra.showExpanders())
        return @elmt


class Hydra.Document extends Hydra.Page
    constructor: (@filename) ->
        super()

    getTabText: () ->
        return @filename

    getTabIcon: () ->
        return "blank.gif"


# The entry point to the view tree.
Hydra.tree = null


main = ->
    _setupMenubar()

    # expand to the full window size and maintain it
    $('#full-page').width($(window).innerWidth())
    $('#full-page').height($(window).innerHeight())

    # install the root panel
    Hydra.tree = new Hydra.Panel()
    Hydra.tree.attachHtml($('#app-area'))
    tabs = Hydra.tree.insert(new Hydra.TabView())
    tabs.insert(new Hydra.Document("hello"))
    tabs.insert(new Hydra.Document("world"))

    # FIXME: setup temp auto-expando

