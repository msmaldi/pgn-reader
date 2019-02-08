gchess_deps = [
    dependency('glib-2.0'),
    dependency('gio-unix-2.0'),
    lib_pgn_reader_dependency
]

pgn_reader_test = executable (
    'pgn-reader', [ 'pgn-reader-test.vala' ],
    dependencies: gchess_deps,
    c_args: [ '-O3' ],
    install: false
)

test ('PGN Test', pgn_reader_test)