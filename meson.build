project('msmaldi-pgn-reader', [ 'vala', 'c' ],
    version: '0.1.0'
)

lib_pgn_reader_sources = [
    'lib/pgn-reader.vala'
]

lib_pgn_reader_dependecies = [
    dependency('glib-2.0'),
    dependency('gio-unix-2.0')
]

lib_pgn_reader = static_library ('pgnreader', 
    lib_pgn_reader_sources,
    dependencies: lib_pgn_reader_dependecies,
    c_args: [ '-O3' ]
)

lib_pgn_reader_dependency = declare_dependency (
    link_with: lib_pgn_reader,
    include_directories: include_directories('.'),
)

subdir('examples')
subdir('test')