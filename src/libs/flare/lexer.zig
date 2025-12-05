const std = @import("std");
const Token = @import("token.zig").Token;
const Tokenizer = @import("tokenizer.zig").Tokenizer;

pub const Parser = @import("parser.zig").Parser;
pub const Stmt = @import("parser.zig").Stmt;
pub const Expr = @import("parser.zig").Expr;
pub const CodeGen = @import("codegen.zig").CodeGen;

pub const Lexer = struct {
    inner: Tokenizer,

    pub fn init(input: []const u8, allocator: std.mem.Allocator) Lexer {
        return Lexer{
            .inner = Tokenizer.init(input, allocator),
        };
    }

    pub fn lex(self: *Lexer) !std.ArrayList(Token) {
        return try self.inner.tokenize();
    }

    pub fn deinit(self: *Lexer) void {
        self.inner.deinit();
    }
};
