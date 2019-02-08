pgn-reader
===

A fast non-allocating and streaming reader for chess games in PGN notation, implemented in vala.

Introduction
------------


`PGNReader` parses games and calls methods of a user provided `ExtentedPGNReader`. Implementing and overriding virtual methods of a custom `ExtentedPGNReader` allows for maximum flexibility:
* The reader has some buffers to store tag names, tag values and comments. The reader only reserves the buffers at the beginning of the reading, but is automatically resized when necessary.
* The reader does not validate move legality. This allows implementing support for custom chess variants, or delaying move validation.

Example
-------

This reader count moves, nags, games, comments, tags, rav and line found.

```vala
public class PGNReaderStats : PGNReader
{
    long move_count = 0;
    long nag_count = 0;
    long game_count = 0;
    long comment_count = 0;
    long tag_count = 0;
    long rav_count = 0;
    long line_count = 0;

    public override void on_newline ()
    {
        line_count++;
    }

    public override void on_tag (string tag_name, string tag_value)
    {
        tag_count++;
    }

    public override void on_san (string move)
    {            
        move_count++;
    }

    public override void on_nag (int nag)
    {            
        nag_count++;
    }

    public override void on_rav_up ()
    {
        rav_count++;
    }

    public override void on_inline_comment (string comment)
    {
        comment_count++;
    }

    public override void on_brace_comment (string comment)
    {
        comment_count++;
    }

    public override void on_game_finish (string result)
    {
        game_count++;
    }
    
    public override void on_finish ()
    {
        print ("Total Line Found:     %ld\n", line_count);
        print ("Total Tag Found:      %ld\n", tag_count);
        print ("Total Move Found:     %ld\n", move_count);
        print ("Total Game Found:     %ld\n", game_count);
        print ("Total Nag Found:      %ld\n", nag_count);
        print ("Total RAV Found:      %ld\n", rav_count);
        print ("Total Comment Found:  %ld\n", comment_count);
    }

    public PGNReaderStats.from_file (GLib.File file)
    {
        base.from_file (file);
    }
}
```

Benckmarks (v0.1.0)
----------
Run with [lichess_db_standard_rated_2013-02.pgn] on:

* Kingston HyperX Savage SHSS37A/240G
* Intel Core i3-4010U (1.7 GHz)
* 4.15.0-45-generic #48-Ubuntu SMP x86_64 GNU/Linux
* gcc-8 (Ubuntu 8.2.0-1ubuntu2~18.04) 8.2.0
* cflags [ -O3 ]

Benchmark | Time | Throughput
---|---|---
grep -F "[Event " -c | 0.200s | 463 MBps
.examples/statistics | 0.657s | 141 MBps

