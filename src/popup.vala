using Gtk;

class Popup : Window {
    private static int WIDTH = 400;
    private static int ENTRY_HEIGHT = 70;

    private Entry entry;

    public Popup() {
        var container = new Box(VERTICAL, 0);

        this.entry = new Entry();
        this.entry.set_size_request(WIDTH, ENTRY_HEIGHT);
        this.style_entry();
        container.add(this.entry);

        this.add(container);

        this.entry.show();
        container.show();

        this.set_size_request(WIDTH, ENTRY_HEIGHT);
        this.set_position(CENTER_ALWAYS);
        this.set_keep_above(true);
        this.set_decorated(false);

        this.key_press_event.connect((event) => {
            if (event.keyval == Gdk.Key.Escape) {
                this.close();
            }
            return false;
        });
        this.destroy.connect(main_quit);
    }

    void style_entry() {
        var css = new CssProvider();
        try {
            css.load_from_data("entry { border: none; font-size: 30px; padding: 0 10px; }");
        } catch (GLib.Error e) {
            assert(false);
        }

        var display = Gdk.Display.get_default();
        var screen = display.get_default_screen();
        StyleContext.add_provider_for_screen(screen, css, 600);

        this.entry.set_has_frame(false);
    }
}
