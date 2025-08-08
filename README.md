# Astroids from scratch zig

Astroids from scratch is a personal project to explore writing a videogame for linux as low level as possible but using correct(ish) technologys.

The current plan is to use wayland, a custom built software renderer, and maybe pipewire.

## Librarys

### xml_parser

A very basic xml parser written in zig. currently only used by wayland_scanner

### wayland_client

An implimentation of the wayland wire protocol.

Also uses wayland_scanner to export request interface for wayland protocols.

#### wayland_scanner

wayland_scanner takes in a list of wayland protocol xml definitions and outputs a generated zig file with binding to those protocols using wayland_client.

Used by wayland client.

### window_lib

TODO

### pipewire_client

TODO

### audio_lib

TODO
