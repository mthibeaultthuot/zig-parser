const std = @import("std");
const TokenKind = @import("token.zig").TokenKind;
const Token = @import("token.zig").Token;

pub const Tokenizer = struct {
    value: []const u8,
    current: usize,
    len: usize,
    allocator: std.mem.Allocator,
    tokens: std.ArrayList(Token),

    pub fn init(input: []const u8, allocator: std.mem.Allocator) Tokenizer {
        return Tokenizer{
            .value = input,
            .current = 0,
            .len = input.len,
            .allocator = allocator,
            .tokens = .{},
        };
    }

    pub fn tokenize(self: *Tokenizer) !std.ArrayList(Token) {
        while (!self.isEOF()) {
            const token = try self.next();
            if (token != .Space) {
                try self.tokens.append(self.allocator, token);
            }
        }
        try self.tokens.append(self.allocator, try Token.init(self.allocator, .Eof, null, null));
        return self.tokens;
    }

    pub fn next(self: *Tokenizer) !Token {
        const c = self.value[self.current];
        self.current += 1;

        return switch (c) {
            '(' => Token.init(self.allocator, .LeftParen, null, null),
            ')' => Token.init(self.allocator, .RightParen, null, null),
            '{' => Token.init(self.allocator, .LeftBrace, null, null),
            '}' => Token.init(self.allocator, .RightBrace, null, null),
            ',' => Token.init(self.allocator, .Comma, null, null),
            '.' => Token.init(self.allocator, .Dot, null, null),
            '-' => Token.init(self.allocator, .Minus, null, null),
            '+' => Token.init(self.allocator, .Plus, null, null),
            ';' => Token.init(self.allocator, .Semicolon, null, null),
            '*' => Token.init(self.allocator, .Star, null, null),
            '/' => Token.init(self.allocator, .Slash, null, null),
            ' ', '\r', '\t', '\n' => Token.init(self.allocator, .Space, null, null),
            '!' => if (self.match('=')) Token.init(self.allocator, .BangEqual, null, null) else Token.init(self.allocator, .Bang, null, null),
            '=' => if (self.match('=')) Token.init(self.allocator, .EqualEqual, null, null) else Token.init(self.allocator, .Equal, null, null),
            '<' => if (self.match('=')) Token.init(self.allocator, .LessEqual, null, null) else Token.init(self.allocator, .Less, null, null),
            '>' => if (self.match('=')) Token.init(self.allocator, .GreaterEqual, null, null) else Token.init(self.allocator, .Greater, null, null),
            '"' => self.string(),
            '0'...'9' => self.number(),
            'a'...'z', 'A'...'Z', '_' => self.identifier(),
            else => Token.init(self.allocator, .Error, null, null),
        };
    }

    fn match(self: *Tokenizer, expected: u8) bool {
        if (self.isEOF()) return false;
        if (self.value[self.current] != expected) return false;
        self.current += 1;
        return true;
    }

    fn string(self: *Tokenizer) !Token {
        const start = self.current;
        while (!self.isEOF() and self.value[self.current] != '"') {
            self.current += 1;
        }
        if (self.isEOF()) return Token.init(self.allocator, .Error, null, null);
        const str = self.value[start..self.current];
        self.current += 1;
        return Token.init(self.allocator, .String, str, null);
    }

    fn number(self: *Tokenizer) !Token {
        const start = self.current - 1;
        while (!self.isEOF() and isDigit(self.value[self.current])) {
            self.current += 1;
        }
        if (!self.isEOF() and self.value[self.current] == '.' and !self.isEOF() and self.current + 1 < self.len and isDigit(self.value[self.current + 1])) {
            self.current += 1;
            while (!self.isEOF() and isDigit(self.value[self.current])) {
                self.current += 1;
            }
        }
        const num = try std.fmt.parseFloat(f64, self.value[start..self.current]);
        return Token.init(self.allocator, .Number, null, num);
    }

    fn identifier(self: *Tokenizer) !Token {
        const start = self.current - 1;
        while (!self.isEOF() and isAlphaNumeric(self.value[self.current])) {
            self.current += 1;
        }
        const text = self.value[start..self.current];
        const kind = getKeyword(text);
        if (kind == .Identifier) {
            return Token.init(self.allocator, .Identifier, text, null);
        }
        return Token.init(self.allocator, kind, null, null);
    }

    fn getKeyword(text: []const u8) TokenKind {
        const map = std.StaticStringMap(TokenKind).initComptime(.{
            .{ "and", .And },
            .{ "class", .Class },
            .{ "else", .Else },
            .{ "false", .False },
            .{ "for", .For },
            .{ "fun", .Fun },
            .{ "if", .If },
            .{ "nil", .Nil },
            .{ "or", .Or },
            .{ "print", .Print },
            .{ "return", .Return },
            .{ "super", .Super },
            .{ "this", .This },
            .{ "true", .True },
            .{ "var", .Var },
            .{ "while", .While },
            .{ "kernel", .Kernel },
            .{ "let", .Let },
        });
        return map.get(text) orelse .Identifier;
    }

    fn isDigit(c: u8) bool {
        return c >= '0' and c <= '9';
    }

    fn isAlphaNumeric(c: u8) bool {
        return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_' or isDigit(c);
    }

    pub fn isEOF(self: Tokenizer) bool {
        return self.current >= self.len;
    }

    pub fn deinit(self: *Tokenizer) void {
        for (self.tokens.items) |token| {
            token.deinit(self.allocator);
        }
        self.tokens.deinit(self.allocator);
    }
};
