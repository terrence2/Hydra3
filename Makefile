###
# Copyright 2011, Terrence Cole
#
# This file is part of Hydra3.
#
# Hydra3 is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Hydra3 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Hydra3. If not, see <http://www.gnu.org/licenses/>.
###

GOALS = \
	build/main.js \
	${NULL}
TARGET=server/public/hydra3.js
COFFEE=./node_modules/.bin/coffee

all: ${GOALS}
	cat ${GOALS} > ${TARGET}

watch:
	while inotifywait src/*; do sleep 0.1; make; done

clean:
	rm -f build/*.js

build/%.js : src/%.coffee
	${COFFEE} -o build -b -c $<


