# Windows Management script collection

These scripts are meant for running X2GoClient from a read-only LAN share.

To use them, copy this folder on a read-only LAN share, say, R:\x2go

Then install X2GoClient on your Admin machine, as Admin

Then copy the entire content of "%programfiles%\x2goclient" (or" %programfiles(x86)%\x2goclient") to R:\x2go\x2goclient

This is important - DO NOT copy the contents of the x2goclient folder directly into "R:\x2go\" - we need an x2goclient subdirectory within that folder!
