vala_lint_conf = join_paths(meson.source_root(), 'test', 'vala-lint.conf')
vala_lint = find_program('io.elementary.vala-lint', required: false)
if (vala_lint.found())
    test ('Vala Lint', vala_lint,
        args: [ '-c', vala_lint_conf, meson.source_root() ]
    )
endif

gchess_deps = [
    glib,
    gio_unix,
    lib_pgn_reader_dependency
]

pgn_reader_test = executable (
    'pgn-reader', [ 'pgn-reader-test.vala' ],
    dependencies: gchess_deps,
    c_args: [ c_recomend_flags ],
    install: false
)

lichess_2013_02_pgn = join_paths (meson.source_root(), 'test/pgn/')

test ('PGN Test', pgn_reader_test, args: [ lichess_2013_02_pgn ])