const std = @import("std");

pub fn location_to_int(loc: []const u8) !u8 {
    if (loc.len != 2) return error.invalid_square_name;
    //std.debug.print("{s}\n", .{loc});
    return (loc[0] - 'a') + 8*('8'-loc[1]);
}

pub const Piece = enum {
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
    squares: [64]Piece,

    white_move: bool,

    wKcastle: bool,
    wQcastle: bool,

    bKcastle: bool,
    bQcastle: bool,

    en_passant_square: ?u8,

    plys_to_draw: u8,
    plynr: u32,

    pub fn make_move_lan(self: *Board, move: []const u8) !void {
        if (!(move.len == 4 or move.len == 5)) return error.invalid_lan_move_notation;
        const from = try location_to_int(move[0..2]);
        const to = try location_to_int(move[2..4]);

        // promotion
        var prom: ?Piece = null;
        if (move.len == 5) {
            if (self.squares[to] == Piece.bpawn) {
                prom = switch (move[4]) {
                    'p' => Piece.bpawn,
                    'r' => Piece.brook,
                    'b' => Piece.bbishop,
                    'n' => Piece.bknight,
                    'q' => Piece.bqueen,
                    'k' => Piece.bking,
                    else => return error.invalid_lan_move_notation,
                };
            }
            else if (self.squares[to] == Piece.wpawn) {
                prom = switch (move[4]) {
                    'p' => Piece.wpawn,
                    'r' => Piece.wrook,
                    'b' => Piece.wbishop,
                    'n' => Piece.wknight,
                    'q' => Piece.wqueen,
                    'k' => Piece.wking,
                    else => return error.invalid_lan_move_notation,
                };
            }
        }

        return self.make_move(from, to, prom);
    }

    pub fn make_move(self: *Board, from: u8, to: u8, promotion: ?Piece) !void {
        const moved_pawn = self.squares[from] == Piece.bpawn or self.squares[from] == Piece.wpawn;

        if (moved_pawn or self.squares[to] != Piece.empty)
            self.plys_to_draw = 0;

        //remove castling rights
        switch (from) {
            comptime try location_to_int("a1") => self.wQcastle = false,
            comptime try location_to_int("h1") => self.wKcastle = false,
            comptime try location_to_int("a8") => self.bQcastle = false,
            comptime try location_to_int("h8") => self.bQcastle = false,

            comptime try location_to_int("e1") => {self.wQcastle = false; self.wKcastle = false;},
            comptime try location_to_int("e8") => {self.wQcastle = false; self.wKcastle = false;},

            else => {}
        } 

        // do move
        self.squares[to] = self.squares[from];
        self.squares[from] = Piece.empty;

        //en passant
        if (self.en_passant_square) |ep_sq| {
            if (to == ep_sq) {
                std.debug.print("en passant\n", .{});
                if (self.white_move) {
                    self.squares[ep_sq + 8] = Piece.empty;
                } else {
                    self.squares[ep_sq - 8] = Piece.empty;
                }
            }
        }

        // castling
        if (self.white_move and from == comptime try location_to_int("e1")) {
            switch (to) {
                comptime try location_to_int("g1") => {
                    const rook = comptime try location_to_int("h1");
                    const rook_to = comptime try location_to_int("f1");
                    self.squares[rook] = Piece.empty;
                    self.squares[rook_to] = Piece.wrook;
                },
                comptime try location_to_int("c1") => {
                    const rook = comptime try location_to_int("a1");
                    const rook_to = comptime try location_to_int("d1");
                    self.squares[rook] = Piece.empty;
                    self.squares[rook_to] = Piece.wrook;
                },
                else => {}
            }
        }
        if (!self.white_move and from == comptime try location_to_int("e8")) {
            switch (to) {
                comptime try location_to_int("g8") => {
                    const rook = comptime try location_to_int("h8");
                    const rook_to = comptime try location_to_int("f8");
                    self.squares[rook] = Piece.empty;
                    self.squares[rook_to] = Piece.brook;
                },
                comptime try location_to_int("c8") => {
                    const rook = comptime try location_to_int("a8");
                    const rook_to = comptime try location_to_int("d8");
                    self.squares[rook] = Piece.empty;
                    self.squares[rook_to] = Piece.brook;
                },
                else => {}
            }
        }

        if (promotion) |prom| {
            self.squares[to] = prom;
        }

        //set en passant square
        self.en_passant_square = null;
        if (moved_pawn) {
            if (@abs(@as(i16, from) - @as(i16, to)) == 16) {
                self.en_passant_square = (from+to)/2;
            }
        }

        self.plys_to_draw+=1;
        self.plynr+=1;
        self.white_move = !self.white_move;

        //std.debug.print("{}\n\n", .{self});
    }
};

pub fn parse_fen (fen: []const u8) !Board {
    var it1 = std.mem.tokenizeScalar(u8, fen, ' ');
    var board: Board = undefined;

    // board block
    const pieces = it1.next() orelse return error.invalid_fen;
    var it2 = std.mem.tokenizeScalar(u8, pieces, '/');
    var i:usize = 0;
    while (it2.next()) |rank| {
        for (rank) |char| {
            if (i > 63) return error.invalid_fen;
            if (std.ascii.isDigit(char)) {
                for (0..(char-'0')) |_| {
                    board.squares[i] = Piece.empty;
                    i+=1;
                }
            }
            else {
                board.squares[i] = switch (char) {
                    'P' => Piece.wpawn,
                    'R' => Piece.wrook,
                    'B' => Piece.wbishop,
                    'N' => Piece.wknight,
                    'Q' => Piece.wqueen,
                    'K' => Piece.wking,

                    'p' => Piece.bpawn,
                    'r' => Piece.brook,
                    'b' => Piece.bbishop,
                    'n' => Piece.bknight,
                    'q' => Piece.bqueen,
                    'k' => Piece.bking,
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
            '-' => {},
            else => return error.unkown_castling_right
        }
    }

    // enpassant square
    board.en_passant_square = location_to_int(it1.next() orelse return error.invalid_fen) catch null;

    board.plys_to_draw = try std.fmt.parseInt(u8, it1.next() orelse return error.invalid_fen, 10);

    board.plynr = try std.fmt.parseInt(u32, it1.next() orelse return error.invalid_fen, 10);

    return board;
}
