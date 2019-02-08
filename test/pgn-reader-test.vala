using GChess;

int main ()
{
    string folder = "../test/pgn/";
    try
    {
        Dir dir = Dir.open (folder, 0);
        string? file_name = null;
        while ((file_name = dir.read_name()) != null)
        {
            var path = "%s%s".printf (folder, file_name);
            var file = GLib.File.new_for_path (path);
            var pgn = new PGNReader.from_file (file);
            pgn.read ();
        }
    }
    catch (Error e)
    {
        print (e.message);
        return 1;
    }

    return 0;
}