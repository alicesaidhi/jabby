# jabby

jabby is a debugger for [jecs](https://github.com/ukendio/jecs) based off [gorp](https://github.com/aloroid/gorp)

It's still in the early stages of development and is very experimental.

Visit the [documentation!](https://alicesaidhi.github.io/jabby/)

## jabby_core

jabby_core is responsible for creating applets. It gives each applet a unique identifier, which can be used in conjunction with jabby_net to handle communication.

## jabby_net

Responsible for networking logic and permissions, it enables secure networking between client, server and client to client within jabby. It uses an id to uniquely separate packets. Refrain from using identifiers not created by jabby_core. Each applet should use the identifier provided by applet.unique_id for communication.
