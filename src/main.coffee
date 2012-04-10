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
        @parent = null
        @children = []

    insertChild: (child) ->
        assert this != window
        @children.push(child)
        child.parent = this
        return child # returns the inserted child

    removeChild: (child) ->
        assert @count() > 0
        assert child.parent == this
        pos = @children.indexOf(child)
        assert pos != -1
        @children = @children.slice(pos, pos)
        child.parent = null
        return this # returns prior parent

    count: () ->
        return @children.length


class Hydra.VSplit extends Hydra.Layout
    constructor: (@topHeight) ->
        super()
        @elmt = document.createElement('div')
        $(@elmt).addClass("vsplit-container")
        @elmt.innerHTML = """
          <div class="vsplit-panel vsplit-top" style="height:#{@topHeight}px"></div>
          <div class="vsplit-handle"></div>
          <div class="vsplit-panel vsplit-bottom"></div>
        """

    getHtml: () ->
        return @elmt

    insertSubLayout: (layout) ->
        assert @count() < 2
        @insertChild(layout)
        if @count() == 1
            tgt = $(".vsplit-top", @elmt)[0]
            $(tgt).append(layout.getHtml())
            #$(tgt).addClass("vsplit-top")
        else
            tgt = $(".vsplit-bottom", @elmt)[0]
            $(tgt).append(layout.getHtml())
            #$(tgt).addClass("vsplit-bottom")
        return layout


class Hydra.Panel extends Hydra.Layout
    constructor: () ->
        super()
        @elmt = document.createElement('div')
        $(@elmt).addClass("panel-container")
        @elmt.innerHTML = """
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
              </div>"""
    
    getHtml: () ->
        return @elmt

    getInsertionPoint: () ->
        #out = $("div>div.panel-center-container>div.panel-content", @elmt)
        out = $("div.panel-content", @elmt)
        assert out.length == 1
        return out

    insertSubLayout: (layout) ->
        """Insert a sub-layout under the main area of this layout."""
        assert @count() == 0
        @insertChild(layout)
        # Note: for flow-box layout to work, we can't have an intermediary,
        #   div, so we replace our own and add styles wo we can find it again.
        $(@getInsertionPoint()).replaceWith(layout.getHtml())
        $(layout.getHtml()).addClass('panel-content')
        for dir in ['north', 'south', 'east', 'west']
            this[dir + 'Elmt'] = elmt = $(".panel-" + dir, @elmt)[0]
            assert elmt?
            this[dir + 'Drop'] = dojo.dnd.Source(elmt, {})
        @northSig = dojo.connect(@northDrop, 'onDrop', (src, nodes, copy) =>
            @splitNorth(src, nodes, copy)
        )
        @southSig = dojo.connect(@southDrop, 'onDrop', (src, nodes, copy) =>
            @splitSouth(src, nodes, copy)
        )
        return layout

    removeFromLayout: () ->
        """Remove ourself from the tree and the dom, insert the placeholder,
           and returns the prior parent."""
        dojo.disconnect(@northSig)
        $(@elmt).replaceWith("""<div id="placeholder">placeholder</div>""")
        if @parent
            return @parent.removeChild(this)
        return null

    splitNorth: (src, nodes, copy) ->
        """Replace this panel with a vpane with this panel as the south entry.
        """
        assert @count() == 1

        $(@northElmt).empty()

        initHeight =  Math.ceil($(@elmt).height() / 2)
        priorParent = @removeFromLayout()
        if priorParent
            vsplit = priorParent.insertChild(new Hydra.VSplit(initHeight))
        else
            Hydra.tree = vsplit = new Hydra.VSplit(initHeight)
        $("#placeholder").replaceWith(vsplit.getHtml())

        north = vsplit.insertSubLayout(new Hydra.Panel())
        northTabs = north.insertSubLayout(new Hydra.TabView())
        northTabs.insertPage(new Hydra.Document("bar"))
        northTabs.insertPage(new Hydra.Document("foo"))
        south = vsplit.insertSubLayout(this)

        return vsplit

    splitSouth: (src, nodes, copy) ->
        """Replace this panel with a vpane with this panel as the north entry.
        """
        assert @count() == 1

        $(@southElmt).empty()

        initHeight =  Math.ceil($(@elmt).height() / 2)
        priorParent = @removeFromLayout()
        if priorParent
            vsplit = priorParent.insertChild(new Hydra.VSplit(initHeight))
        else
            Hydra.tree = vsplit = new Hydra.VSplit(initHeight)
        $("#placeholder").replaceWith(vsplit.getHtml())

        north = vsplit.insertSubLayout(this)

        south = vsplit.insertSubLayout(new Hydra.Panel())
        southTabs = south.insertSubLayout(new Hydra.TabView())
        southTabs.insertPage(new Hydra.Document("bar"))
        southTabs.insertPage(new Hydra.Document("foo"))
        
        return vsplit

class Hydra.TabView extends Hydra.Layout
    """A set of tabs embeddable into an H/VPane or a Panel."""
    constructor: () ->
        super()
        @elmt = document.createElement('div')
        $(@elmt).addClass("tabview-container")
        @elmt.innerHTML = """
            <div class="tabview-tabs">
            </div>
            <div class="tabview-area">
            </div>
            """
        args = {
            selfCopy: false
            copyOnly: true
            generateText: false
        }
        @dragSource = dojo.dnd.Source(@getTabInsertionPoint(), args)
        dojo.connect(@dragSource, "onDndCancel", (evt) -> Hydra.hideExpanders())
        dojo.connect(@dragSource, "onDndDrop", (evt) -> Hydra.hideExpanders())
        dojo.connect(@dragSource, "onDndStart", (evt) -> Hydra.showExpanders())

    getHtml: () ->
        return @elmt
    
    getBodyInsertionPoint: () ->
        out = $("div.tabview-area", @elmt)
        assert out.length == 1
        return out[0]

    getTabInsertionPoint: () ->
        out = $("div.tabview-tabs", @elmt)
        assert out.length == 1
        return out[0]

    insertPage: (page) ->
        """Add a page derived widget to the tab set."""
        @insertChild(page)
        @dragSource.insertNodes(false, [page.getTabText()])
        $(@getBodyInsertionPoint()).append(page.getBodyElement())
        return page


class Hydra.Document extends Hydra.Page
    constructor: (@filename) ->
        super()
        @body = document.createElement('div')
        $(@body).addClass('document-body')
        @body.innerHTML = "Lorem Ipsum dom solit plumbum ego solit"

    getTabText: () ->
        return @filename

    getTabIcon: () ->
        return "blank.gif"

    getBodyElement: () ->
        return @body

# The entry point to the view tree.
Hydra.tree = null


main = ->
    _setupMenubar()

    # expand to the full window size and maintain it
    $('#full-page').width($(window).innerWidth())
    $('#full-page').height($(window).innerHeight())

    # install the root panel
    Hydra.tree = new Hydra.Panel()
    $('#app-area').replaceWith(Hydra.tree.getHtml())
    tabs = Hydra.tree.insertSubLayout(new Hydra.TabView())
    tabs.insertPage(new Hydra.Document("hello"))
    tabs.insertPage(new Hydra.Document("world"))

    # FIXME: setup temp auto-expando

