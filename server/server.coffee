###
# Copyright 2011, Terrence Cole
#
# This file is part of MIN3D.
#
# MIN3D is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# MIN3D is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with MIN3D.  If not, see <http://www.gnu.org/licenses/>.
###

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

    @view('index': -> (
        @title = "Hydra3"
        @scripts = ['/jquery-1.7.1.min', '/hydra3', '/run']
        @stylesheets = ['/hydra3']
        body ->
          div id:'full-page', ->
            div id:'titlebar', "Titlebar"
            div id:'app-area'
            div id:'statusbar', "Status"
    ))
))
