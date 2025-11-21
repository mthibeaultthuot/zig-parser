const std = @import("std");

pub const TokenType = enum {
    LeftParen,
    RightParen,
    LeftBrace,
    RightBrace,
    Comma,
    Dot,
    Minus,
    Plus,
    Semicolon,
    Slash,
    Star,
    Space,

    Bang,
    BangEqual,
    Equal,
    EqualEqual,
    Greater,
    GreaterEqual,
    Less,
    LessEqual,

    Identifier,
    String,
    Number,

    And,
    Class,
    Else,
    False,
    For,
    Fun,
    If,
    Nil,
    Or,
    Print,
    Return,
    Super,
    This,
    True,
    Var,
    While,
    Error,
    Eof,
    NotImplemented,
};

pub const Lexer = struct {
    inner: Tokenizer,

    pub fn lex(self: *Lexer) !void {
        std.debug.print("{s}", .{@typeName(@TypeOf(self))});

        _ = try self.inner.tokenize();
    }
};

pub const Token = struct {
    value: []u8,

    pub fn init(allocator: std.mem.Allocator, value: []u8) !Token {
        return Token{
            .value = try allocator.alloc(u8, value.len),
        };
    }

    pub fn deinit(self: Token, allocator: std.mem.Allocator) void {
        allocator.free(self.value);
    }
};

pub const Tokenizer = struct {
    value: []const u8,
    current: usize,
    len: usize,

    pub fn tokenize(self: *Tokenizer) !void {
        std.debug.print("{s}", .{@typeName(@TypeOf(self))});

        while (!self.isEOF()) {
            self.peek();
        }
    }

    pub fn peek(self: *Tokenizer) void {
        const token = try self.next();
        std.debug.print("Token find : {}\n", .{token});
        self.current += 1;
    }

    pub fn next(self: Tokenizer) !TokenType {
        const tokenStr = self.value[self.current];

        const Started = enum {
            Ident,
            Number,
            Let,
            Fn,
            If,
        };

        const token = switch (tokenStr) {
            '{' => TokenType.LeftBrace,
            '}' => TokenType.RightBrace,
            '(' => TokenType.LeftParen,
            ')' => TokenType.RightParen,
            ' ' => TokenType.Space,
            else => {
                std.debug.print("Token not implemented yet: '{c}'\n", .{tokenStr});
                return Started.Ident;
            },
        };

        return token;
    }

    pub fn lexToken(self: Tokenizer) !Token {
        std.debug.print("{s}", .{@typeName(@TypeOf(self))});
        return null;
    }

    pub fn isEOF(self: Tokenizer) bool {
        return self.current >= self.len;
    }
};
