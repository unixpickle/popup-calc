using Gtk;

class Popup : Window {
    public Popup() {
        this.set_size_request(400, 70);
        this.set_position(WindowPosition.CENTER_ALWAYS);
        this.set_keep_above(true);
        this.set_decorated(false);
    }
}
