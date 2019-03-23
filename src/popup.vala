using Gtk;

class Popup : Window {
    private static int WIDTH = 400;
    private static int ENTRY_HEIGHT = 70;

    private Entry entry;
    private Label answer;

    private AsyncDict dict;

    public Popup() {
        var container = new Box(Orientation.VERTICAL, 0);

        this.entry = new Entry();
        this.entry.set_size_request(WIDTH, ENTRY_HEIGHT);
        this.style_entry();
        container.add(this.entry);

        this.answer = new Label("");
        this.answer.xalign = 0;
        container.add(this.answer);

        this.add(container);

        this.set_position(WindowPosition.CENTER_ALWAYS);
        this.set_keep_above(true);
        this.decorated = false;

        this.key_press_event.connect((event) => {
            var mask = accelerator_get_default_mod_mask();
            if (event.keyval == Gdk.Key.Escape) {
                this.close();
            } else if (event.keyval == Gdk.Key.c && (event.state & mask) == Gdk.ModifierType.CONTROL_MASK) {
                this.copy_to_clipboard();
            }
            return false;
        });
        this.destroy.connect(main_quit);
        this.entry.changed.connect(() => {
            if (this.entry.text == "") {
                this.resize(10, 10);
            }
            var eval_result = evaluate_expression(this.entry.text);
            if (Regex.match_simple("^[a-z ]+$", this.entry.text) && eval_result == "0") {
                this.answer.set_text("searching definition...");
                this.dict.lookup_term(this.entry.text);
            } else {
                this.answer.set_text(eval_result);
            }
        });

        this.dict = new AsyncDict();
        this.dict.defined.connect((term, definition) => {
            if (term == this.entry.text) {
                this.answer.set_text(definition);
            }
        });
        this.dict.failed.connect((term, message) => {
            if (term == this.entry.text) {
                this.answer.set_text(message);
            }
        });
    }

    void style_entry() {
        var css = new CssProvider();
        try {
            var data = "GtkEntry, entry { border: none; font-size: 30px; padding: 0 10px; }\n" +
                "GtkLabel, label { padding: 5px 10px 7px 10px; font-size: 20px; }";
            css.load_from_data(data, data.length);
        } catch (Error e) {
            assert(false);
        }

        var display = Gdk.Display.get_default();
        var screen = display.get_default_screen();
        StyleContext.add_provider_for_screen(screen, css, 600);

        this.entry.has_frame = false;
    }

    void copy_to_clipboard() {
        var clip = Clipboard.get(Gdk.SELECTION_CLIPBOARD);
        var text = this.answer.get_text();
        clip.set_text(text, text.length);
    }
}
