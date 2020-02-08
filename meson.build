project('msmaldi-pgn-reader', [ 'vala', 'c' ],
    version: '0.1.1'
)

c_recomend_flags = [ '-O3' ]

glib = dependency('glib-2.0')
gio_unix = dependency('gio-2.0')

subdir('lib')

lib_pgn_reader_dependecies = [
    glib,
    gio_unix
]

lib_pgn_reader = static_library ('pgnreader',
    lib_pgn_reader_sources,
    dependencies: lib_pgn_reader_dependecies,
    c_args: [ c_recomend_flags ]
)

lib_pgn_reader_dependency = declare_dependency (
    link_with: lib_pgn_reader,
    include_directories: include_directories('.'),
)

subdir('examples')
subdir('test')