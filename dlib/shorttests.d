module dlib.shorttests;

private bool _is_low_alpha(char[] c)
{
    return (c == "a" || c == "b" || c == "c" || c == "d" || c == "e" ||
            c == "f" || c == "g" || c == "h" || c == "i" || c == "j" ||
            c == "k" || c == "l" || c == "m" || c == "n" || c == "o" ||
            c == "p" || c == "q" || c == "r" || c == "s" || c == "t" ||
            c == "u" || c == "v" || c == "w" || c == "x" || c == "y" || c == "z");
}

private bool _is_up_alpha(char[] c)
{
    return (c == "A" || c == "B" || c == "C" || c == "D" || c == "E" ||
            c == "F" || c == "G" || c == "H" || c == "I" || c == "J" ||
            c == "K" || c == "L" || c == "M" || c == "N" || c == "O" ||
            c == "P" || c == "Q" || c == "R" || c == "S" || c == "T" ||
            c == "U" || c == "V" || c == "W" || c == "X" || c == "Y" || c == "Z");
}

bool is_alpha(char[] c)
{
     return (_is_low_alpha(c) || _is_up_alpha(c));
}

bool is_comma(char[] c)
{
    return (c == ",");
}

bool is_digit(char[] c)
{
    return (c == "0" || c == "1" || c == "2" || c == "3" || c == "4" ||
            c == "5" || c == "6" || c == "7" || c == "8" || c == "9");
}

bool is_dot(char[] c)
{
    return (c == ".");
}

bool is_equals(char[] c)
{
    return (c == "=");
}

private bool _is_open_paren(char[] c)
{
    return (c == "(");
}

private bool _is_close_paren(char[] c)
{
    return (c == ")");
}

bool is_paren(char[] c)
{
    return (_is_open_paren(c) || _is_close_paren(c));
}

bool is_pow2(int x)
{
    int a = 2;
    while (a < x)
    {
        a *= 2;
    }
    return a == x;
}

bool is_semi(char[] c)
{
    return (c == ";");
}

bool is_space(char[] c)
{
    return (c == " ");
}

bool is_under(char[] c)
{
    return (c == "_");
}

unittest {
    assert(is_alpha("a"));
    assert(is_alpha("Z"));
    assert(!is_alpha("3"));
    assert(is_comma(","));
    assert(!is_comma("x"));
    assert(is_digit("1"));
    assert(!is_digit("p"));
    assert(is_dot("."));
    assert(!is_dot("|"));
    assert(is_equals("="));
    assert(!is_equals("*"));
    assert(is_paren("("));
    assert(!is_paren("()"));
    assert(is_pow2(1024));
    assert(!is_pow2(1026));
    assert(is_semi(";"));
    assert(!is_semi(":"));
    assert(is_space(" "));
    assert(!is_space("_"));
    assert(is_under("_"));
    assert(!is_under("'"));
}
