# EV3 Programmer Ruby Representation

Lego Mindstorms EV3 can be programmed in various ways, one of them being
the "EV3 Programmer" for Android tablets.

EV3 Programmer saves the programs in an EV3A format which is a thinly wrapped
JSON format. This library provides a Ruby based language to represent EV3A,
with a bidirectional translator.

## EV3A Files

EV3 Programmer stores the programs in
"Internal Storage"/Android/data/com.lego.mindstorms.ev3programmer/files with
an `ev3a` extension. 

An `ev3a` file is a ZIP archive containing two JSON files: `Viewstate` and
`Program.ev3j`.

### Viewstate

I haven't looked into the details but presumably this file saves the last used
view window.

Example:

`{"x0":930.0,"y0":-187.0,"scale":1.0}`

### Program.ev3j

The EV3J format represents the various kinds of control blocks.

I should make a trivial example with a picture.

See the library reference (TODO).

See the [JSON schema](http://json-schema.org) definition for it (TODO).
(Use python-jsonschema.rpm with
the `jsonschema` validator, once I figure out how it works)

## EV3J Library

The main entry point is the {Ev3j::Robot} class.
