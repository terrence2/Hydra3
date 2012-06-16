"""
Panel.cs/js is a page-oriented display framework for coffeescript and javascript.  It is focused on allowing users to flexably organize and intuitively reconfigure their content, on the fly.

Panel has a simple interface.  One simply creates a new Panel and adds Pages to it.  The main Panel class represents a view tree composed of layout information and pages.  All pages reside in a TabPane.  All TabPanes reside in a FullPane or a SplitPane.  An API user can give addPage additional information about the type of page to help the Panel pick a good location for the new Page, or it can add in a specific location. 

TreeNode
  FullPane
  SplitPane
    VSplitPane
    HSplitPane
  TabPane

Page
  WelcomePage
"""

class Panel
    """
    Panel is the entry point for panel.cs and all of its functionality.
    
    Example:
        p = new Panel('target-div-id')
    """
    constructor: (target) ->
        @tree = new Panel.FullPane(this)
        $(target).replaceWith(@tree.getHtml())
        tabs = @tree.insertSubLayout(new Panel.TabPane(this))
        tabs.insertPage(new Panel.WelcomePage())

    _showExpanders: () ->
        for s in ['.panel-corner', '.panel-ns', '.panel-we']
            $(s).addClass('expanded')

    _hideExpanders: () ->
        for s in ['.panel-corner', '.panel-ns', '.panel-we']
            $(s).removeClass('expanded')

    addPage: (page, req) ->
        pane = @tree.findNearestTabPane()
        pane.insertPage(page)
    

class Panel.Page
    """
    The base class for all Pages.  Pages are the views that present documents
    in the Panel tree.  Pages can be placed into a TabPane
    """
    constructor: (@docName) ->
        @id = Panel.Page.globalIdNum++
    getId: () -> @id
    getPageId: () -> "panel-page-num-#{@id}"
    getTabId: () -> "panel-tab-num-#{@id}"
    
    getTabText: () ->
        "Override to set the tab text for this document."
        return "<unset-#{@id}>"

    getTabIcon: () ->
        "Override to customize the icon shown for documents of this type."
        return "blank.gif"

    getBodyElement: () ->
        return "No Body Set : #{@id}"

Panel.Page.globalIdNum = 0

class Panel.WelcomePage extends Panel.Page
    constructor: () ->
        super()
        @elmt = document.createElement("div")
        @elmt.innerHTML = """
          <b>Hello, World!</b>
        """
    getTabText: () -> "Welcome"
    getTabIcon: () -> "blank.gif"
    getBodyElement: () -> @elmt

class Panel.TreeNode
    constructor: (@panel) ->
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

    findNearestTabPane: () ->
        for child in @children
            if child instanceof Panel.TabPane
                return child
        for child in @children
            tp = child.findNearestTabPane()
            if tp?
                return tp
        return
    

class Panel.SplitPane extends Panel.TreeNode

class Panel.VSplitPane extends Panel.SplitPane
    constructor: (panel, @topHeight) ->
        super(panel)
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
        else
            tgt = $(".vsplit-bottom", @elmt)[0]
            $(tgt).append(layout.getHtml())
        return layout

class Panel.HSplitPane extends Panel.SplitPane
    constructor: (panel, @leftWidth) ->
        super(panel)
        @elmt = document.createElement('div')
        $(@elmt).addClass("hsplit-container")
        @elmt.innerHTML = """
          <div class="hsplit-panel hsplit-left" style="width:#{@leftWidth}px"></div>
          <div class="hsplit-handle"></div>
          <div class="hsplit-panel hsplit-right"></div>
        """

    getHtml: () ->
        return @elmt

    insertSubLayout: (layout) ->
        assert @count() < 2
        @insertChild(layout)
        if @count() == 1
            tgt = $(".hsplit-left", @elmt)[0]
            $(tgt).append(layout.getHtml())
        else
            tgt = $(".hsplit-right", @elmt)[0]
            $(tgt).append(layout.getHtml())
        return layout


class Panel.FullPane extends Panel.TreeNode
    constructor: (panel) ->
        super(panel)
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
        @westSig = dojo.connect(@westDrop, 'onDrop', (src, nodes, copy) =>
            @splitWest(src, nodes, copy)
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
            vsplit = priorParent.insertChild(new Panel.VSplitPane(@panel, initHeight))
        else
            @panel.tree = vsplit = new Panel.VSplitPane(@panel, initHeight)
        $("#placeholder").replaceWith(vsplit.getHtml())

        north = vsplit.insertSubLayout(new Panel.FullPane(@panel))
        northTabs = north.insertSubLayout(new Panel.TabPane(@panel))
        northTabs.insertPage(new Panel.TestPage("bar"))
        northTabs.insertPage(new Panel.TestPage("foo"))
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
            vsplit = priorParent.insertChild(new Panel.VSplitPane(@panel, initHeight))
        else
            @panel.tree = vsplit = new Panel.VSplitPane(@panel, initHeight)
        $("#placeholder").replaceWith(vsplit.getHtml())

        north = vsplit.insertSubLayout(this)

        south = vsplit.insertSubLayout(new Panel.FullPane(@panel))
        southTabs = south.insertSubLayout(new Panel.TabPane(@panel))
        southTabs.insertPage(new Panel.TestPage("bar"))
        southTabs.insertPage(new Panel.TestPage("foo"))
        
        return vsplit

    splitWest: (src, nodes, copy) ->
        """Replace this panel with a vpane with this panel as the east entry.
        """
        assert @count() == 1

        $(@westElmt).empty()

        initWidth =  Math.ceil($(@elmt).width() / 2)
        priorParent = @removeFromLayout()
        if priorParent
            hsplit = priorParent.insertChild(new Panel.HSplitPane(@panel, initWidth))
        else
            @panel.tree = hsplit = new Panel.HSplitPane(@panel, initWidth)
        $("#placeholder").replaceWith(hsplit.getHtml())


        west = hsplit.insertSubLayout(new Panel.FullPane(@panel))
        westTabs = west.insertSubLayout(new Panel.TabPane(@panel))
        westTabs.insertPage(new Panel.TestPage("bar"))
        westTabs.insertPage(new Panel.TestPage("foo"))

        east = hsplit.insertSubLayout(this)
        
        return hsplit
        

class Panel.TabPane extends Panel.TreeNode
    """A set of tabs embeddable into an H/VPane or a Panel."""
    constructor: (panel) ->
        super(panel)
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
        dojo.connect(@dragSource, "onDndCancel", (evt) => @panel._hideExpanders())
        dojo.connect(@dragSource, "onDndDrop", (evt) => @panel._hideExpanders())
        dojo.connect(@dragSource, "onDndStart", (evt) => @panel._showExpanders())
        @sourcePageMap = {}

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
        # insert the page logically into this tabview
        @insertChild(page)
        
        # create and insert the tab text
        tab = document.createElement('div')
        tab.id = page.getTabId()
        tab.innerHTML = """<table id="#{page.getTabId()}"><tr>
                <td>#{page.getTabText()}</td>
                <td><div class="tabview-close-button">x</div></td>
            </tr></table>"""
        @sourcePageMap[page.getId()] = @dragSource.insertNodes(false, [tab])
        $(tab).click(
            ((e) => @setCurrentPage(page)))

        # add all dynamic stuff to the tab
        $("##{page.getTabId()} .tabview-close-button").hide()
        $("##{page.getTabId()}").hover(
            ((e) -> $("##{page.getTabId()} .tabview-close-button").show()),
            ((e) -> $("##{page.getTabId()} .tabview-close-button").hide()))
        $("##{page.getTabId()} .tabview-close-button").hover(
            ((e) -> $("##{page.getTabId()} .tabview-close-button")
                .css('text-decoration', 'underline')
                .css('font-weight', 'bold')),
            ((e) -> $("##{page.getTabId()} .tabview-close-button")
                .css('text-decoration', '')
                .css('font-weight', 'normal')))
        $("##{page.getTabId()} .tabview-close-button").click(
            ((e) =>
                # FIXME: if last page, remove tabview
                # FIXME: if last tabview, show welcome page
                @removePage(page)
            ))

        # create and insert the body
        $(@getBodyInsertionPoint()).append(page.getBodyElement())
        
        # set as current page
        @setCurrentPage(page)
        
        return page

    removePage: (page) ->
        @removeChild(page)
        @dragSource.delItem(@sourcePageMap[page.getId()])
        $("##{page.getTabId()}").remove()
        $("##{page.getPageId()}").remove()

    setCurrentPage: (page) ->
        for e in $("div", @getTabInsertionPoint())
            $(e).removeClass("tabview-tab-current")
        for e in $("div", @getBodyInsertionPoint())
            $(e).hide()
        $("div#" + page.getTabId(), @getTabInsertionPoint()).addClass("tabview-tab-current")
        $("div#" + page.getPageId(), @getBodyInsertionPoint()).show()


class Panel.TestPage extends Panel.Page
    constructor: (@filename) ->
        super()
        @body = document.createElement('div')
        $(@body).addClass('document-body')
        @body.innerHTML = "<div id=\"#{@getPageId()}\">Lorem Ipsum dom solit plumbum ego solit</div>"

    getTabText: () ->
        return @filename

    getTabIcon: () ->
        return "blank.gif"

    getBodyElement: () ->
        return @body

