import std::io;

fn void uci_info() {
    io::printn(`
id name C3 Chess engine
id author dgc08

option name test_option type spin default 0 min -10 max 10

uciok`);
}

fn int main() {
    while (true) {
        String? io_s = io::treadline();
        if (catch io_s) return 1;
        string::Splitter s = {.string = io_s, .split = " "};

        String command;
        if (try unw = s.next()) {
            command = unw;
        }
        else {
            return 0;
        }
        String rest;
        //io::printn(command);
        if (!s.at_end()) {
            rest = s.string[s.current..];
            //io::printn(rest);
        }

        switch (command) {
            case "uci":
                uci_info();
            case "isready":
                io::printn("readyok");
            case "option":
                break;
            case "go":
                io::printn("info score cp 670 pv e2e4\nbestmove e2e4");
        }
    }
}
