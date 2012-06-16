###
# Copyright 2011-2012, Terrence Cole
###
APPNAME = "HydraServer"
VERSION = 0

server = require('zappa')
server('127.0.0.1', 8080, -> (
    @enable 'default layout'
    @use 'static'

    @get('/': ->
        @render('index')
    )

    @coffee '/run.js': ->
        $(document).ready ->
            main()

    @on connection: () ->
        @emit hello: {app: APPNAME, version: VERSION}

    @on getTUList: () ->
        @emit TUList: [{relpath: "js/src/jsgc.cpp"},
                     {relpath: "js/src/jsgcmark.cpp"},
                     {relpath: "js/src/gc/Memory.cpp"},
                     {relpath: "js/src/gc/Nursery.cpp"},
                     {relpath: "js/src/gc/StoreBuffer.cpp"},
                    ]

    @view('index': -> (
        @title = "Hydra3"
        @scripts = [
          '/jquery-1.7.1.min',
          '/dojo-release-1.7.1/dojo/dojo',
          '/socket.io/socket.io',
          '/hydra3',
          '/run'
        ]
        @stylesheets = [
          '/hydra3',
        ]
        body 'class':'claro', ->
          div id:'full-page', ->
            div id:'titlebar'
            div id:'app-area'
            div id:'statusbar', "Status"
    ))
))
