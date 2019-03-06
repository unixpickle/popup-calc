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
    var extended_expr = (STANDARD_DEFS + expr).escape("\n");
    string[] spawn_args = {"bash", "-c", @"echo \"$(extended_expr)\" | timeout 1s bc -l"};
    string[] spawn_env = GLib.Environ.get();
    string stdout;
    string stderr;
    int exit_status;

    try {
        GLib.Process.spawn_sync("/",
                                spawn_args,
                                spawn_env,
                                GLib.SpawnFlags.SEARCH_PATH,
                                null,
                                out stdout,
                                out stderr,
                                out exit_status);
    } catch (GLib.SpawnError error) {
        return "unable to run `bc` command";
    }

    if (stderr != "") {
        return stderr.strip().replace("(standard_in) 2: ", "");
    } else if (exit_status != 0) {
        return "timeout";
    } else {
        return stdout.strip();
    }
}
