const std = @import("std");
const lexer = @import("flare_lexer");

pub fn main() !void {
    const src =
        \\kernel simple_kernel() {
        \\ let i = 1;
        \\}
    ;

    var lex = lexer.Lexer{ .inner = lexer.Tokenizer{
        .value = src,
        .current = 0,
        .len = src.len,
    } };
    try lex.lex();

    std.debug.print("{s}\n", .{src});
}
