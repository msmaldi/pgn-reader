examples_dependencies = [
    dependency('glib-2.0'),
    dependency('gio-unix-2.0'),
    lib_pgn_reader_dependency
]

executable (
    'statistics', [ 'statistics.vala' ],
    dependencies: examples_dependencies,
    c_args: [ '-O3' ],
    install: false
)