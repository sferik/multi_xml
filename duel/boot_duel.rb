# How long the library takes to load, with its standard-library
# dependencies (bigdecimal, date, time, and yaml).
duel_process "boot: require multi_xml", ruby: %(require "multi_xml")
