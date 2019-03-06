string evaluate_expression(string expr) {
    // TODO: escape the expression. This is a hack.
    string[] spawn_args = {"bash", "-c", @"echo '$(expr)' | timeout 1s bc -l"};
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
        return stderr.strip();
    } else if (exit_status != 0) {
        return "timeout";
    } else {
        return stdout.strip();
    }
}
