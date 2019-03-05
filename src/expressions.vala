string evaluate_expression(string expr) {
    // TODO: escape the expression. This is a hack.
    string[] spawn_args = {"bash", "-c", @"echo '$(expr)' | bc -l"};
    string[] spawn_env = GLib.Environ.get();
    string stdout;
    string stderr;

    try {
        GLib.Process.spawn_sync("/",
                                spawn_args,
                                spawn_env,
                                GLib.SpawnFlags.SEARCH_PATH,
                                null,
                                out stdout,
                                out stderr,
                                null);
    } catch (GLib.SpawnError error) {
        return "unable to run `bc` command";
    }

    if (stderr != "") {
        return stderr.strip();
    } else {
        return stdout.strip();
    }
}
