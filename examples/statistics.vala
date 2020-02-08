using GChess;

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

    public override void on_finish () {
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

int main (string[] args)
{
    if (args.length < 2)
    {
        print ("Usage: %s FILE\n", args[0]);
        return 0;
    }

    var infile = GLib.File.new_for_commandline_arg (args[1]);
    if (!infile.query_exists ())
    {
        stderr.printf ("File '%s' does not exist.\n", args[1]);
        return 1;
    }
    try
    {
        var pgn = new PGNReaderStats.from_file (infile);
        pgn.read ();
    }
    catch (Error e)
    {
        print (e.message);
        return 1;
    }

    return 0;
}
