const std = @import("std");
const Io = std.Io;

const board = @import("board.zig");

var game: board.Board = undefined;

const Uci_command = enum {default, uci, isready, setoption, position, go, ucinewgame};

const command_map = std.StaticStringMap(Uci_command).initComptime(.{
    .{ "uci", .uci },
    .{ "isready", .isready },
    .{ "setoption", .setoption },
    .{ "position", .position },
    .{ "go", .go },
    .{ "ucinewgame", .ucinewgame },

});

fn diemsg(msg: []const u8) noreturn {
    std.debug.print("{s}\n", .{msg});
    std.process.exit(1);
}

inline fn die() noreturn {
    diemsg("expected something which we haven't got");
}

fn newgame() void {
    game = comptime try board.parse_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
}

fn load_position(pos: []const u8) !void {
    var remainder = pos;
    if (std.mem.startsWith(u8, remainder, "fen ")) {
        remainder = remainder["fen ".len..];

        if (std.mem.startsWith(u8, remainder, "startpos")) {
            newgame();
        }
        else {
            const fen_part = if (std.mem.indexOf(u8, remainder, " moves")) |index|
                remainder[0..index]
            else
                remainder;
            game = try board.parse_fen(fen_part);
        }
    }

    const moves = pos[(std.mem.indexOf(u8, pos, "moves") orelse return error.invalid_uci_command_format)+("moves ".len)..];

    var it = std.mem.tokenizeScalar(u8, moves, ' ');
    while (it.next()) |move| {
        try game.make_move(move);
    }
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer = Io.File.Writer.init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    var stdin_buffer: [1024]u8 = undefined;
    var stdin_file_reader = Io.File.Reader.init(.stdin(), io, &stdin_buffer);
    const stdin = &stdin_file_reader.interface;

    newgame();

    while (true) {
        const command = try stdin.takeDelimiter('\n') orelse {return;};
        var it = std.mem.tokenizeScalar(u8, command, ' ');

        const cmd = command_map.get(it.next() orelse {die();}) orelse .default;

        switch (cmd) {
            .uci => try stdout.writeAll(uci_info),
            .isready => {newgame(); try stdout.writeAll("readyok\n");},
            .go => try stdout.writeAll("info score cp 670 pv e2e3\nbestmove e2e4\n"),
            .setoption => {},
            .position => try load_position(it.rest()),
            .ucinewgame => newgame(),
            .default => diemsg("unknown command")
        }

        try stdout.flush();
    }
}

const uci_info =
    \\id name Zig chess engine
    \\id author dgc08
    \\option name test_option type spin default 0 min -10 max 10
    \\
    \\uciok
    \\
;
