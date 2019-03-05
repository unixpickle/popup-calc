using Gtk;

class Popup : Window {
    private static int WIDTH = 400;
    private static int ENTRY_HEIGHT = 70;
    private static int ANSWER_HEIGHT = 30;

    private Entry entry;
    private Label answer;

    public Popup() {
        var container = new Box(VERTICAL, 5);

        this.entry = new Entry();
        this.entry.set_size_request(WIDTH, ENTRY_HEIGHT);
        this.style_entry();
        container.add(this.entry);

        this.answer = new Label("invalid expression");
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
            if (event.keyval == Gdk.Key.Escape) {
                this.close();
            }
            return false;
        });
        this.destroy.connect(main_quit);
        this.entry.changed.connect(() => {
            double solution = 0;
            if (evaluate_expression(this.entry.get_text(), out solution)) {
                this.answer.set_text(@"$(solution)");
            } else {
                this.answer.set_text("invalid expression");
            }
        });
    }

    void style_entry() {
        var css = new CssProvider();
        try {
            css.load_from_data("entry { border: none; font-size: 30px; padding: 0 10px; }\n" +
                "label { padding: 0 10px; }");
        } catch (GLib.Error e) {
            assert(false);
        }

        var display = Gdk.Display.get_default();
        var screen = display.get_default_screen();
        StyleContext.add_provider_for_screen(screen, css, 600);

        this.entry.set_has_frame(false);
    }
}
