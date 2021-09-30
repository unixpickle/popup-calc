using Gtk;

class Popup : Window {
    private static int WIDTH = 400;

    private Entry entry;
    private Label answer;

    private AsyncDict dict;
    private bool gnome_center;

    public Popup(bool gnome_center) {
        this.gnome_center = gnome_center;

        var container = new Box(Orientation.VERTICAL, 0);

        this.entry = new Entry();
        this.entry.set_size_request(WIDTH, 0);
        this.style_entry();
        container.add(this.entry);

        this.answer = new Label("");
        this.answer.xalign = 0;
        container.add(this.answer);

        this.add(container);

        this.set_position(WindowPosition.CENTER);
        this.set_keep_above(true);
        this.decorated = false;

        this.show.connect((event) => {
            if (this.gnome_center) {
                this.center_with_gnome();
            }
        });
        this.key_press_event.connect((event) => {
            var mask = accelerator_get_default_mod_mask();
            if (event.keyval == Gdk.Key.Escape) {
                if (this.entry.text != "") {
                    this.answer.set_text("");
                    this.entry.set_text("");
                    this.auto_shrink();
                } else {
                    this.close();
                }
            } else if (event.keyval == Gdk.Key.c && (event.state & mask) == Gdk.ModifierType.CONTROL_MASK) {
                this.copy_to_clipboard();
            }
            return false;
        });
        this.destroy.connect(main_quit);
        this.entry.changed.connect(() => {
            if (this.entry.text == "") {
                this.auto_shrink();
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
            var data = """
                GtkEntry, entry {
                    border: none; font-size: 30px; padding: 15px 10px; box-shadow: none;
                }
                GtkLabel, label {
                    padding: 10px 10px 10px 10px; font-size: 20px; background: #f0f0f0;
                }
            """;
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

    void auto_shrink() {
        this.resize(10, 10);
    }

    void center_with_gnome() {
        Timeout.add(250, () => {
            DBusProxy proxy;
            try {
                proxy = new DBusProxy.for_bus_sync(
                    BusType.SESSION,
                    DBusProxyFlags.NONE,
                    null,
                    "org.gnome.Shell",
                    "/org/gnome/Shell",
                    "org.gnome.Shell"
                );
            } catch (Error e) {
                print(@"failed to connect to GNOME shell: $(e.message)");
                return false;
            }
            var code = """
            (function(pid) {
                let num_moved = 0;
                const actors = global.get_window_actors();
                for (let i = 0; i < actors.length; i++) {
                    const window = actors[i].get_meta_window();
                    if (window.get_pid() == pid) {
                        const display = window.get_display();
                        const [dw, dh] = display.get_size();
                        const frame = window.get_frame_rect();
                        const x = (dw - frame.width) / 2;
                        const y = (dh - frame.height) / 2;
                        window.move_frame(0, x, y);
                        num_moved += 1;
                    }
                }
                return num_moved;
            })""" + @"($((int)Posix.getpid()))";
            var dbus_args = new Variant.tuple({new Variant.string(code)});
            Variant ret_val;
            try {
                ret_val = proxy.call_sync("Eval", dbus_args, DBusCallFlags.NO_AUTO_START, 1000);
            } catch (Error e) {
                print(@"failed to connect to GNOME shell: $(e.message)");
                return false;
            }
            bool status = false;
            string json_out = "";
            ret_val.get("(bs)", ref status, ref json_out);

            if (status && json_out == "0") {
                // The window isn't registered yet.
                return true;
            }

            return false;
        });
    }
}
