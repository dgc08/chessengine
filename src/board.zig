const std = @import("std");

pub fn location_to_int(loc: []const u8) !u8 {
    if (loc.len != 2) return error.invalid_square_name;
    return (loc[0] - 'a') + 8*('8'-loc[1]);
}

pub const Pieces = enum {
    empty,

    wpawn,
    wrook,
    wknight,
    wbishop,
    wqueen,
    wking,

    bpawn,
    brook,
    bknight,
    bbishop,
    bqueen,
    bking
};

pub const Board = struct {
    squares: [64]Pieces,

    white_move: bool,

    wKcastle: bool,
    wQcastle: bool,

    bKcastle: bool,
    bQcastle: bool,

    en_passant_square: ?u8,

    plys_to_draw: u8,
    movenr: u32,

    pub fn make_move(self: *Board, move: []const u8) !void {
        if (!(move.len == 4 or move.len == 5)) return error.invalid_lan_move_notation;
        const from = try location_to_int(move[0..2]);
        const to = try location_to_int(move[2..4]);

        self.squares[to] = self.squares[from];
        self.squares[from] = Pieces.empty;

        // promotion
        if (move.len == 5) {
            if (self.squares[to] == Pieces.bpawn) {
                self.squares[to] = switch (move[4]) {
                    'p' => Pieces.bpawn,
                    'r' => Pieces.brook,
                    'b' => Pieces.bbishop,
                    'n' => Pieces.bknight,
                    'q' => Pieces.bqueen,
                    'k' => Pieces.bking,
                    else => return error.invalid_lan_move_notation,
                };
            }
            else {
                self.squares[to] = switch (move[4]) {
                    'p' => Pieces.wpawn,
                    'r' => Pieces.wrook,
                    'b' => Pieces.wbishop,
                    'n' => Pieces.wknight,
                    'q' => Pieces.wqueen,
                    'k' => Pieces.wking,
                    else => return error.invalid_lan_move_notation,
                };
            }
        }
    }
};

pub fn parse_fen (fen: []const u8) !Board {
    var it1 = std.mem.tokenizeScalar(u8, fen, ' ');
    var board: Board = undefined;

    // board block
    const pieces = it1.next() orelse return error.invalid_fen;
    var it2 = std.mem.tokenizeScalar(u8, pieces, '/');
    var i = 0;
    while (it2.next()) |rank| {
        for (rank) |char| {
            if (i > 63) return error.invalid_fen;
            if (std.ascii.isDigit(char)) {
                for (0..(char-'0')) |_| {
                    board.squares[i] = Pieces.empty;
                    i+=1;
                }
            }
            else {
                board.squares[i] = switch (char) {
                    'P' => Pieces.wpawn,
                    'R' => Pieces.wrook,
                    'B' => Pieces.wbishop,
                    'N' => Pieces.wknight,
                    'Q' => Pieces.wqueen,
                    'K' => Pieces.wking,

                    'p' => Pieces.bpawn,
                    'r' => Pieces.brook,
                    'b' => Pieces.bbishop,
                    'n' => Pieces.bknight,
                    'q' => Pieces.bqueen,
                    'k' => Pieces.bking,
                    else => return error.unkown_piece
                };

                i+=1;
            }
        }
    }
    // whether the FEN gave info on every square
    if (i != 64) return error.invalid_fen;

    // move
    board.white_move = (it1.next() orelse return error.invalid_fen)[0] == 'w';

    // castling rights
    for (it1.next() orelse return error.invalid_fen) |right| {
        switch (right) {
            'K' => board.wKcastle = true,
            'Q' => board.wQcastle = true,
            'k' => board.bKcastle = true,
            'q' => board.bQcastle = true,
            else => return error.unkown_castling_right
        }
    }

    // enpassant square
    board.en_passant_square = location_to_int(it1.next() orelse return error.invalid_fen) catch null;

    board.plys_to_draw = try std.fmt.parseInt(u8, it1.next() orelse return error.invalid_fen, 10);

    board.movenr = try std.fmt.parseInt(u32, it1.next() orelse return error.invalid_fen, 10);

    return board;
}
