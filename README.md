# HAMNET Yealink Phonebook

This scripts crawls the HAMNET HAMSIP APIs to build
a complete phonebook for modern phones like the T54W.

The `make_xml.rb` needs to be run to create the
`output.xml` file, which can be pushed to any
HAMNET Webserver.
Configure your phone to pull it form that webserver.

Note: You can configure this script to run daily by creating
a systemd timer + server unit.