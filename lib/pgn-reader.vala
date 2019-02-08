namespace GChess 
{
    public errordomain PGNReaderError
    {
        LOAD_ERROR
    }

    enum State
    {
        SYMBOL,
        MOVE_TEXT,
        TAGS,
        LINE_COMMENT,
        BRACE_COMMENT,
        TAG_START,
        TAG_NAME,
        PRE_TAG_VALUE,
        TAG_VALUE,
        POST_TAG_VALUE,
        NAG,
        ANNOTATION,
        RAV,
        ERROR
    }

    public class PGNReader
    { 
        public static string RESULT_IN_PROGRESS = "*";
        public static string RESULT_DRAW        = "1/2-1/2";
        public static string RESULT_WHITE       = "1-0";
        public static string RESULT_BLACK       = "0-1";

        public virtual void on_start () { }
        public virtual void on_newline () { }
        public virtual void on_inline_comment (string comment) { }
        public virtual void on_brace_comment (string comment) { }
        public virtual void on_tag (string tag_name, string tag_value) { }
        public virtual void on_tags_finish () { }
        public virtual void on_san (string move) { }
        public virtual void on_nag (int nag) { }
        public virtual void on_rav_up () { }
        public virtual void on_rav_down () { }
        public virtual void on_annotation () { }
        public virtual void on_game_finish (string result) { }
        public virtual void on_finish () { }
        public virtual void on_error (char c) throws PGNReaderError
        {
            throw new PGNReaderError.LOAD_ERROR ("Unexpected character '%c'.", c);
        }

        public GLib.File file { get; private set; }

        public PGNReader.from_file (GLib.File file)
        {
            this.file = file;
        }

        public void read () throws PGNReaderError, Error
        {
            uint8 buffer[8192];
            FileInputStream stream = file.read ();          
            long size = 0;

            bool in_escape = false;
            State state = State.TAGS;

            var tag_name_sb = new StringBuilder.sized (256);            
            var tag_value_sb = new StringBuilder.sized (256);
            var inline_comment_sb = new StringBuilder.sized (256);
            var comment_sb = new StringBuilder.sized (8192);
            
            // Used buffer and pointer causes StringBuilder
            // hurts on code performance.
            char symbol_buffer[256];
            char *symbol_ptr = symbol_buffer;

            int nag_number = 0;
            char previous_annotation = '\0';

            int rav_level = 0;

            on_start ();
            while ((size = stream.read(buffer)) > 0)
            {
                for (long offset = 0; offset < size; offset++)
                {
                    char c = (char)(buffer)[offset];

                    switch (state)
                    {
                    case State.SYMBOL:
                        // NOTE: '/' not in spec but required for 1/2-1/2 symbol
                        //       ':' is in spec but not necessary in symbol
                        if (c.isalnum () || c == '+' || c == '#' || c == '=' || c == '/' || c == '-')
                        {
                            if (not_overflow (symbol_buffer, symbol_ptr, 255))
                                *symbol_ptr++ = c;
                            else
                                state = State.ERROR;
                        }
                        else
                        {
                            *symbol_ptr = '\0';
                            unowned string symbol = (string)symbol_buffer;

                            bool first_is_number = symbol[0].isdigit ();
                            state = State.MOVE_TEXT;

                            if (!first_is_number)
                            {
                                on_san (symbol);
                            }
                            else if (symbol == RESULT_DRAW || symbol == RESULT_WHITE || symbol == RESULT_BLACK)
                            {
                                on_game_finish (symbol);
                                if (rav_level == 0)
                                    state = State.TAGS;
                            }
                            symbol_ptr = symbol_buffer;
                            offset--;
                        }
                        break;                    
                    case State.MOVE_TEXT:
                        if (c == '\n')
                            on_newline ();  
                        else if (c.isspace ())
                            continue;            
                        else if (c == ';')
                            state = State.LINE_COMMENT;
                        else if (c == '{')
                            state = State.BRACE_COMMENT;
                        else if (c == '*')
                        {
                            on_game_finish (RESULT_IN_PROGRESS);
                            if (rav_level == 0)
                                state = State.TAGS;
                        }
                        else if (c == '.')
                            continue;
                        else if (c.isalnum ())
                        {
                            *symbol_ptr++ = c;
                            state = State.SYMBOL;
                        }
                        else if (c == '$')
                        {
                            nag_number = 0;
                            state = State.NAG;
                        }
                        else if (c == '!' || c == '?')
                        {
                            previous_annotation = c;
                            state = State.ANNOTATION;
                        }
                        else if (c == '(')
                        {
                            rav_level++;
                            on_rav_up ();
                        }
                        else if (c == ')')
                        {
                            if (rav_level == 0)
                            {
                                offset--;
                                state = State.ERROR;
                            }
                            else
                            {
                                rav_level--;
                                on_rav_down ();
                            }
                        }
                        else if (rav_level != 0)
                            continue;
                        else
                        {
                            offset--;
                            state = State.ERROR;
                        }
                        break;
                    case State.TAGS:
                        if (c == '[')
                        {
                            state = State.TAG_START;
                        }
                        else if (c == '\n')
                            on_newline ();
                        else if (c.isdigit())
                        {
                            on_tags_finish ();
                            *symbol_ptr++ = c;
                            state = State.SYMBOL;
                        }
                        else if  (c == '*')
                        {
                            on_tags_finish ();
                            offset--;
                            state = State.MOVE_TEXT;                            
                        }
                        else if (!c.isspace ())
                        {
                            offset--;
                            state = State.ERROR;
                        }
                        break;
                    case State.LINE_COMMENT:
                        if (c == '\n')
                        {
                            state = MOVE_TEXT;
                            on_inline_comment (inline_comment_sb.str);
                            on_newline ();
                        }
                        else
                        {
                            inline_comment_sb.append_c (c);
                        }
                        break;
                    case State.BRACE_COMMENT:
                        if (c == '\n')
                        {
                            comment_sb.append_c (' ');
                            on_newline ();
                        }
                        else if (c == '}')
                        {
                            state = State.MOVE_TEXT;
                            on_brace_comment (comment_sb.str);
                            comment_sb.erase ();
                        }
                        else
                        {
                            comment_sb.append_c (c);
                        }
                        break;
                    case State.TAG_START:
                        if (c == ' ')
                            continue;
                        else if (c.isalnum ())
                        {
                            tag_name_sb.append_c (c);
                            state = State.TAG_NAME;
                        }
                        else
                        {
                            state = State.ERROR;
                        }
                        break;
                    case State.TAG_NAME:
                        if (c == ' ')
                        {
                            state = State.PRE_TAG_VALUE;
                        }
                        else
                        {
                            tag_name_sb.append_c (c);
                        }
                        break;
                    case State.PRE_TAG_VALUE:
                        if (c == ' ')
                            continue;
                        else if (c == '"')
                        {
                            state = State.TAG_VALUE;
                        }
                        else
                        {
                            state = State.ERROR;
                        }
                        break;
                    case State.TAG_VALUE:
                        if (c == '\\' && !in_escape)
                            in_escape = true;
                        if (c == '"' && !in_escape)
                        {
                            state = State.POST_TAG_VALUE;
                        }
                        else if (in_escape && c == '\\')
                        {
                            tag_value_sb.append_c ('\\');
                            tag_value_sb.append_c ('\\');
                        }
                        else
                        {
                            tag_value_sb.append_c (c);
                            in_escape = false;                          
                        }
                        break;

                    case State.POST_TAG_VALUE:
                        if (c == ' ')
                            continue;
                        else if (c == ']')
                        {
                            state = State.TAGS;
                            on_tag (tag_name_sb.str, tag_value_sb.str);
                            tag_name_sb.erase ();
                            tag_value_sb.erase ();
                        }
                        break;
                    case State.NAG:
                        if (c.isdigit ())
                        {
                            int c_digit = c - '0';
                            nag_number = (nag_number * 10) + c_digit;
                        }
                        else
                        {
                            on_nag (nag_number);
                            state = State.MOVE_TEXT;
                            offset--;
                        }
                        break;
                    case State.ANNOTATION:
                        if (c == '!')
                        {
                            //  3    very good move (traditional "!!")
                            if (previous_annotation == '!')
                                on_nag (3);

                            //  6    questionable move (traditional "?!")
                            else if (previous_annotation == '?')
                                on_nag (6);
                            
                            previous_annotation = '\0';
                            state = MOVE_TEXT;
                        }
                        else if (c == '?')
                        {
                            //  5    speculative move (traditional "!?")
                            if (previous_annotation == '!')
                                on_nag (5);

                            //  4    very poor move (traditional "??")
                            else if (previous_annotation == '?')
                                on_nag (4);
                            
                            previous_annotation = '\0';
                            state = MOVE_TEXT;
                        }
                        else
                        {
                            //  1    good move (traditional "!")
                            if (previous_annotation == '!')
                                on_nag (1);
                            //  2    poor move (traditional "?")
                            else if (previous_annotation == '?')
                                on_nag (2);  
                            
                            previous_annotation = '\0';
                            state = MOVE_TEXT;
                            offset--;
                        }
                        break;
                    case State.ERROR:
                        on_error (c);  
                        break;       
                    }
                }              
            }
            if (state == State.SYMBOL)    
            {
                *symbol_ptr = '\0';
                unowned string symbol = (string)symbol_buffer;

                bool first_is_number = symbol[0].isdigit ();

                /* Game termination markers */
                if (!first_is_number)
                {
                    on_san (symbol);
                }
                else if (symbol == RESULT_DRAW || symbol == RESULT_WHITE || symbol == RESULT_BLACK)
                {
                    on_game_finish (symbol);
                }
            }
            on_finish ();
        }

        static inline bool not_overflow (char *buffer, char *ptr, int size)
        {
            return ((ptr - buffer) < size);
        }
    }    
}