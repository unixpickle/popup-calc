class AsyncDict : Object {
    private Mutex mutex;
    private Cond cond;
    private string? term;

    public signal void defined(string term, string definition);
    public signal void failed(string term, string error);

    public AsyncDict() {
        this.mutex = Mutex();
        this.cond = Cond();
        new Thread<bool>("dict", this.loop);
    }

    public void lookup_term(string term) {
        this.mutex.lock();
        this.term = term;
        this.cond.broadcast();
        this.mutex.unlock();
    }

    private bool loop() {
        while (true) {
            this.mutex.lock();
            if (this.term != null) {
                var term = this.term;
                this.term = null;
                this.mutex.unlock();
                try {
                    var definition = this.define(term);
                    this.emit_async(term, definition, null);
                } catch (Error e) {
                    this.emit_async(term, null, e.message);
                }
            } else {
                this.cond.wait(this.mutex);
                this.mutex.unlock();
            }
        }
    }

    private string? define(string term) throws Error {
        var client = new DictClient("dict.org", 2628);
        var definition = client.define(term);
        if (definition == null) {
            var matches = client.match(term);
            if (matches.length > 0) {
                definition = client.define(matches[0]);
            }
        }
        return definition;
    }

    private void emit_async(string term, string? definition, string? error) {
        var ev = new IdleSource();
        ev.set_callback(() => {
            if (error == null) {
                if (definition == null) {
                    this.failed(term, "no definition found");
                } else {
                    this.defined(term, definition);
                }
            } else {
                this.failed(term, error);
            }
            return Source.REMOVE;
        });
        ev.attach(MainContext.default());
    }
}

class DictClient : Object {
    public static int ERROR_HOSTNAME = 0;
    public static int ERROR_FIRST_LINE = 1;
    public static int ERROR_LINE_OVERFLOW = 2;
    public static int ERROR_BAD_RESPONSE = 3;

    private Socket socket;

    public DictClient(string host, uint16 port) throws Error {
        unowned Posix.HostEnt? ent = Posix.gethostbyname(host);
        if (ent == null) {
            throw new Error(Quark.from_string("DictClient"), ERROR_HOSTNAME, "no hostname found");
        }
        InetAddress addr = new InetAddress.from_bytes(ent.h_addr_list[0].data, IPV4);
        InetSocketAddress sockaddr = new InetSocketAddress(addr, port);

        this.socket = new Socket(IPV4, STREAM, TCP);
        this.socket.connect(sockaddr);

        string line = this.read_line();
        if (line.split(" ")[0] != "220") {
            throw new Error(Quark.from_string("DictClient"), ERROR_FIRST_LINE,
                "invalid first line: " + line);
        }
    }

    public string[] match(string query) throws Error {
        this.write_line(@"MATCH wn lev \"$(query)\"");
        var result = new string[0];
        var response = this.read_status();
        if (response != "152") {
            return result;
        }
        while (true) {
            var line = this.read_line();
            if (line == ".") {
                break;
            }
            if (line.length > 5) {
                result += line[4:-1];
            }
        }
        response = this.read_status();
        if (response != "250") {
            throw new Error(Quark.from_string("DictClient"), ERROR_BAD_RESPONSE,
                "expected code 250 but got: " + response);
        }
        return result;
    }

    public string? define(string query) throws Error {
        this.write_line(@"DEFINE wn \"$(query)\"");
        var response = this.read_status();
        if (response == "552") {
            return null;
        } else if (response != "150") {
            throw new Error(Quark.from_string("DictClient"), ERROR_BAD_RESPONSE,
                "expected code 150 but got: " + response);
        }
        response = this.read_status();
        if (response != "151") {
            throw new Error(Quark.from_string("DictClient"), ERROR_BAD_RESPONSE,
                "expected code 151 but got: " + response);
        }
        var definition = "";
        while (true) {
            var line = this.read_line();
            if (line == ".") {
                break;
            }
            if (definition.length > 0) {
                definition += "\n";
            }
            definition += line;
        }
        response = this.read_status();
        if (response != "250") {
            throw new Error(Quark.from_string("DictClient"), ERROR_BAD_RESPONSE,
                "expected code 250 but got: " + response);
        }
        return definition;
    }

    private void write_line(string line) throws Error {
        var data = (line + "\r\n").data;
        while (data.length > 0) {
            var sent = this.socket.send(data);
            data = data[sent:data.length];
        }
    }

    private string read_status() throws Error {
        return this.read_line().split(" ")[0];
    }

    private string read_line() throws Error {
        var result = new uint8[1026];
        ssize_t size = 0;
        while (true) {
            var buffer = new uint8[1];
            var received = this.socket.receive(buffer);
            if (received == 1) {
                result[size++] = buffer[0];
            }
            if (size == result.length) {
                throw new Error(Quark.from_string("DictClient"), ERROR_LINE_OVERFLOW,
                    "line overflow");
            }
            if (size >= 2 && result[size - 1] == '\n' && result[size - 2] == '\r') {
                result[size - 2] = 0;
                return (string)result[0:size - 2];
            }
        }
    }

    ~DictClient() {
        try {
            this.socket.close();
        } catch (Error e) {
        }
    }
}