Hydra = {}

class Hydra.Panel
    constructor: (@parent) ->
        @id = 'top'
        if @parent?
            @id = @parent.childName()

        @child = null

    attachHtml: (elmt) ->
        $(elmt).replaceWith("""
          <div id="#{@id}" class="panel-container">
              <div class="panel-ns-container">
                <div class="panel-corner"></div>
                <div class="panel-ns"></div>
                <div class="panel-corner"></div>
              </div>
              <div class="panel-center-container">
                <div class="panel-we"></div>
                <div class="panel-content"></div>
                <div class="panel-we"></div>
              </div>
              <div class="panel-ns-container">
                <div class="panel-corner"></div>
                <div class="panel-ns"></div>
                <div class="panel-corner"></div>
              </div>
          </div>
        """)

    childName: ->
        return @id + '-0'

    insert: (@child) ->
        tgt = $('#'+@id+'>div.panel-center-container>div.panel-content').get(0)
        elmt = @child.attachHtml(tgt)
        elmt.addClass('panel-content')


class Hydra.TabView
    constructor: (@parent) ->
        @id = 'top'
        if @parent?
            @id = @parent.childName()

    attachHtml: (elmt) ->
        return $(elmt).replaceWith("""
          <div id="#{@id}" class="tabview-container">
            <div class="tabview-tabs">
            </div>
            <div class="tabview-area">
            </div>
          </div>
        """)

# The entry point to the view tree.
Hydra.tree = null

main = ->
    # expand to the full window size and maintain it
    $('#full-page').width($(window).innerWidth())
    $('#full-page').height($(window).innerHeight())

    # install the root panel
    Hydra.tree = new Hydra.Panel(null)
    Hydra.tree.attachHtml($('#app-area'))
    Hydra.tree.insert(new Hydra.TabView(tree))

    # FIXME: setup temp auto-expando
    for s in ['.panel-corner', '.panel-ns-edge', '.panel-we-edge']
        $(s).addClass('panel-expanded')

