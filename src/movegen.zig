const board = @import("board.zig");
const std = @import("std");

fn pregenerate_knight_moves() [64]std.BoundedArray(board.Move, 8) {
    const move_pairs: [8][2]i8 = .{
        .{ -2, -1 }, .{ -2,  1 },
        .{ -1, -2 }, .{ -1,  2 },
        .{  1, -2 }, .{  1,  2 },
        .{  2, -1 }, .{  2,  1 },
    };
    var ret = [64]std.BoundedArray(board.Move, 8).init(0);
    for (0..64) |i| {
        const rank = i / 8;
        const file = i % 8;
        for (move_pairs) |pair| {
            rank += pair[0];
            file += pair[1];
            if ((rank < 8 and rank >= 0) and (file < 8 and file >= 0)) {
                try ret.append(.{.from = i, .to=rank*8+file});
            }
        }
    }

    return ret;
}

pub const knight_move_map = pregenerate_knight_moves();

pub fn get_moves(position: board.Board) std.BoundedArray(board.Move, 218) {
    
} 
