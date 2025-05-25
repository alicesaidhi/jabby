# jabby_net

Provides the networking interface used to make jabby work. It's designed to allow us to send data to any player, vm or actor.

## Requirements

- It needs to be able to send data to the server, player or another actor.
- Developers must be able to handle this securely so that the server will filter out any requests to another client if not permitted.
- It needs to provide events to allow for one-way communication
- It needs to provide functions to allow for two-way communication where it will expect a single response.
- It needs to provide a socket, allowing for establishing a connection for bidirectional communication, only needing to check permissions when establishing the connection.

## Design

Applets inside jabby each have a unique number within that client. The networking library will use this number to filter and operate on events. Together with the host, this data is formatted as:

```luau
type TargetInfo = {
    to: Player | "server",
    id: number
}
```

We use a BindableEvent to facilitate actor to actor communication on the client and a single RemoteEvent from client to server and client to client. Sockets and functions will be built upon the base event class.

In order to avoid making unnecessary connections, to receive an event you need to call `:connect(id)` to obtain the necessary interface. Everything else will operate through something like `:fire(target, packet)` as most of the time, you don't need an id. -1 is reserved specifically for cases where no id is associated.
