const string STANDARD_DEFS = """
pi = a(1) * 4

define ln(x) {
    return l(x)
}

define log(x) {
    return l(x) / l(10)
}

/* https://en.wikipedia.org/wiki/Bc_(programming_language)#A_%22power%22_function_in_POSIX_bc */

define int_part(x) {
    auto s
    s = scale
    scale = 0
    x /= 1   /* round x down */
    scale = s
    return x
}

define pow(x, y) {
    if (y == int_part(y)) {
        return (x ^ y)
    }
    return e(y * l(x))
}
""";

string evaluate_expression(string expr) {
    var extended_expr = shell_escape(STANDARD_DEFS + expr);
    var script = shell_escape(@"echo \"$(extended_expr)\" | timeout 1s bc -l");
    string command = @"bash -c \"$(script)\"";
    string stdout;
    string stderr;
    int exit_status;

    try {
        Process.spawn_command_line_sync(command,
                                        out stdout,
                                        out stderr,
                                        out exit_status);
    } catch (SpawnError error) {
        return "unable to run `bc` command";
    }

    if (stderr != "") {
        try {
            var err_prefix = new Regex("\\(standard_in\\) [0-9]*: ");
            var result = stderr.strip();
            return err_prefix.replace(result, result.length, 0, "");
        } catch (RegexError error) {
            return @"regex error: $(error.message)";
        }
    } else if (exit_status != 0) {
        return "timeout";
    } else {
        var result = stdout.strip();
        while (result.contains(".") && result.has_suffix("0")) {
            result = result[0:-1];
        }
        if (result.has_suffix(".")) {
            result = result[0:-1];
        }
        return result;
    }
}

string shell_escape(string s) {
    var res = s.escape("\n");
    res = res.replace("`", "\\`");
    res = res.replace("$", "\\$");
    return res;
}
