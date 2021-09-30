void main(string[] args) {
    bool gnome_center = false;
    var entry = OptionEntry();
    entry.long_name = "gnome-center";
    entry.short_name = 'g';
    entry.flags = 0;
    entry.arg = OptionArg.NONE;
    entry.arg_data = &gnome_center;
    entry.description = "explicitly tell GNOME to center the window";
    entry.arg_description = "BOOL";
    OptionEntry[] options = {entry};

    try {
        var opt_ctx = new OptionContext("popup_calc");
        opt_ctx.set_help_enabled(true);
        opt_ctx.add_main_entries(options, null);
        opt_ctx.parse(ref args);
    } catch (OptionError e) {
        stderr.printf("%s\n", e.message);
        return 1;
    }

    Gtk.init(ref args);
    new Popup(gnome_center).show_all();
    Gtk.main();
}