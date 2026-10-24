const std = @import("std");
const rl = @cImport({@cInclude("raylib.h");});

const board = @import("board.zig");

const color1: rl.Color = rl.Color{.r = 184+18, .g = 135+18, .b = 98+18, .a = 255};
const color2: rl.Color = rl.Color{.r = 237+18, .g = 214+18, .b = 176+18, .a = 255};

pub fn run_gui(game: *board.Board) !void {
    const square_size: c_int = 96;

    const screenWidth = 8*square_size;
    const screenHeight = 8*square_size;

    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE | rl.FLAG_WINDOW_HIGHDPI);
    rl.InitWindow(screenWidth, screenHeight, "Chess");
    defer rl.CloseWindow();
    rl.SetTargetFPS(60);

    const textures: [@typeInfo(board.Piece).@"enum".fields.len]?rl.Texture = .{
        null,
        rl.LoadTextureFromImage(rl.LoadImage("img/white-pawn.png")),
        rl.LoadTextureFromImage(rl.LoadImage("img/white-rook.png")),
        rl.LoadTextureFromImage(rl.LoadImage("img/white-knight.png")),
        rl.LoadTextureFromImage(rl.LoadImage("img/white-bishop.png")),
        rl.LoadTextureFromImage(rl.LoadImage("img/white-queen.png")),
        rl.LoadTextureFromImage(rl.LoadImage("img/white-king.png")),

        rl.LoadTextureFromImage(rl.LoadImage("img/black-pawn.png")),
        rl.LoadTextureFromImage(rl.LoadImage("img/black-rook.png")),
        rl.LoadTextureFromImage(rl.LoadImage("img/black-knight.png")),
        rl.LoadTextureFromImage(rl.LoadImage("img/black-bishop.png")),
        rl.LoadTextureFromImage(rl.LoadImage("img/black-queen.png")),
        rl.LoadTextureFromImage(rl.LoadImage("img/black-king.png")),
    };

    var last_click: ?u8 = null;
    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        {
            if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
                const pos = rl.GetMousePosition();
                const x:u8 = @intFromFloat(pos.x / square_size);
                const y:u8 = @intFromFloat(pos.y / square_size);
                std.debug.print("x: {}, y: {}, {}, {?}\n", .{x, y, game.white_move, game.en_passant_square});

                const sq = y*8 + x;

                if (last_click == null) {
                    last_click = sq;
                }
                else if (last_click) |from| {
                    last_click = null;
                    const prom: ?board.Piece =
                        if (game.white_move and y==0) board.Piece.wqueen
                        else if (!game.white_move and y==7) board.Piece.bqueen
                        else null;

                    try game.make_move(.{.from=from, .to=sq}, prom);
                }
            }

            rl.ClearBackground(rl.RAYWHITE);

            for (0..64) |i| {
                var color = color1;
                if (((i%8)+(i/8))%2 == 1)
                    color = color2;

                const x: c_int = @intCast((i%8)*square_size);
                const y: c_int = @intCast((i/8)*square_size);
                rl.DrawRectangle(x,y,square_size, square_size, color);

                const piece = @intFromEnum(game.squares[i]);
                const scale = @as(f32,@floatFromInt(square_size))/128.0;
                if (textures[piece]) |tex| {
                    rl.DrawTextureEx(tex, rl.Vector2{.x=@floatFromInt(x), .y=@floatFromInt(y)}, 0.0, scale, rl.WHITE);
                }
            }

        }
        rl.EndDrawing();
    }
}
