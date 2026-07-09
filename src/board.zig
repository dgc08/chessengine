const std = @import("std");

pub fn location_to_int(loc: []const u8) !u8 {
    if (loc.len != 2) return error.invalid_square_name;
    //std.debug.print("{s}\n", .{loc});
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
    plynr: u32,

    pub fn make_move(self: *Board, move: []const u8) !void {
        if (!(move.len == 4 or move.len == 5)) return error.invalid_lan_move_notation;
        const from = try location_to_int(move[0..2]);
        const to = try location_to_int(move[2..4]);

        const moved_pawn = self.squares[from] == Pieces.bpawn or self.squares[from] == Pieces.wpawn;

        if (moved_pawn or self.squares[to] != Pieces.empty)
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


        //set en passant square
        self.en_passant_square = null;
        if (moved_pawn) {
            if (@abs(@as(i16, from) - @as(i16, to)) == 16) {
                self.en_passant_square = (from+to)/2;
            }
        }


        // do move
        self.squares[to] = self.squares[from];
        self.squares[from] = Pieces.empty;

        //en passant
        if (self.en_passant_square) |ep_sq| {
            if (to == ep_sq) {
                if (self.white_move) {
                    self.squares[ep_sq + 8] = Pieces.empty;
                } else {
                    self.squares[ep_sq - 8] = Pieces.empty;
                }
            }
        }

        // castling
        if (self.white_move and from == comptime try location_to_int("e1")) {
            switch (to) {
                comptime try location_to_int("g1") => {
                    const rook = comptime try location_to_int("h1");
                    const rook_to = comptime try location_to_int("f1");
                    self.squares[rook] = Pieces.empty;
                    self.squares[rook_to] = Pieces.wrook;
                },
                comptime try location_to_int("c1") => {
                    const rook = comptime try location_to_int("a1");
                    const rook_to = comptime try location_to_int("d1");
                    self.squares[rook] = Pieces.empty;
                    self.squares[rook_to] = Pieces.wrook;
                },
                else => {}
            }
        }
        if (!self.white_move and from == comptime try location_to_int("e8")) {
            switch (to) {
                comptime try location_to_int("g8") => {
                    const rook = comptime try location_to_int("h8");
                    const rook_to = comptime try location_to_int("f8");
                    self.squares[rook] = Pieces.empty;
                    self.squares[rook_to] = Pieces.wrook;
                },
                comptime try location_to_int("c8") => {
                    const rook = comptime try location_to_int("a8");
                    const rook_to = comptime try location_to_int("d8");
                    self.squares[rook] = Pieces.empty;
                    self.squares[rook_to] = Pieces.wrook;
                },
                else => {}
            }
        }
        
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
