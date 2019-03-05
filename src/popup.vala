using Gtk;

class Popup : Window {
    private static int WIDTH = 400;
    private static int ENTRY_HEIGHT = 70;
    private static int ANSWER_HEIGHT = 30;

    private Entry entry;
    private Label answer;

    public Popup() {
        var container = new Box(VERTICAL, 10);

        this.entry = new Entry();
        this.entry.set_size_request(WIDTH, ENTRY_HEIGHT);
        this.style_entry();
        container.add(this.entry);

        this.answer = new Label("");
        this.answer.set_xalign(0);
        container.add(this.answer);

        this.add(container);

        this.entry.show();
        this.answer.show();
        container.show();

        this.set_size_request(WIDTH, ENTRY_HEIGHT + ANSWER_HEIGHT);
        this.set_position(CENTER_ALWAYS);
        this.set_keep_above(true);
        this.set_decorated(false);

        this.key_press_event.connect((event) => {
            var mask = accelerator_get_default_mod_mask();
            if (event.keyval == Gdk.Key.Escape) {
                this.close();
            } else if (event.keyval == Gdk.Key.c && (event.state & mask) == Gdk.CONTROL_MASK) {
                this.copy_to_clipboard();
            }
            return false;
        });
        this.destroy.connect(main_quit);
        this.entry.changed.connect(() => {
            this.answer.set_text(evaluate_expression(this.entry.get_text()));
        });
    }

    void style_entry() {
        var css = new CssProvider();
        try {
            css.load_from_data("entry { border: none; font-size: 30px; padding: 0 10px; }\n" +
                "label { padding: 0px 10px; }");
        } catch (GLib.Error e) {
            assert(false);
        }

        var display = Gdk.Display.get_default();
        var screen = display.get_default_screen();
        StyleContext.add_provider_for_screen(screen, css, 600);

        this.entry.set_has_frame(false);
    }

    void copy_to_clipboard() {
        var clip = Clipboard.get(Gdk.SELECTION_CLIPBOARD);
        var text = this.answer.get_text();
        clip.set_text(text, text.length);
    }
}
