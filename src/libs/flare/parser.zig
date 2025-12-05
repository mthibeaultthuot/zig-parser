const std = @import("std");
const Token = @import("token.zig").Token;

pub const Expr = union(enum) {
    Number: f64,
    Identifier: []const u8,
    Binary: *BinaryExpr,

    pub fn deinit(self: Expr, allocator: std.mem.Allocator) void {
        switch (self) {
            .Binary => |b| {
                b.left.deinit(allocator);
                b.right.deinit(allocator);
                allocator.destroy(b);
            },
            else => {},
        }
    }
};

pub const BinaryExpr = struct {
    left: Expr,
    op: Token,
    right: Expr,
};

pub const Stmt = union(enum) {
    VarDecl: VarDeclStmt,
    KernelDecl: KernelDeclStmt,

    pub fn deinit(self: Stmt, allocator: std.mem.Allocator) void {
        switch (self) {
            .VarDecl => |v| v.value.deinit(allocator),
            .KernelDecl => |k| {
                for (k.body) |stmt| {
                    stmt.deinit(allocator);
                }
                allocator.free(k.body);
            },
        }
    }
};

pub const VarDeclStmt = struct {
    name: []const u8,
    value: Expr,
};

pub const KernelDeclStmt = struct {
    name: []const u8,
    body: []Stmt,
};

pub const Parser = struct {
    tokens: []Token,
    current: usize,
    allocator: std.mem.Allocator,

    pub fn init(tokens: []Token, allocator: std.mem.Allocator) Parser {
        return Parser{
            .tokens = tokens,
            .current = 0,
            .allocator = allocator,
        };
    }

    pub fn parse(self: *Parser) ![]Stmt {
        var stmts: std.ArrayList(Stmt) = .{};
        while (!self.isAtEnd()) {
            const stmt = try self.declaration();
            try stmts.append(self.allocator, stmt);
        }
        return stmts.toOwnedSlice(self.allocator);
    }

    fn declaration(self: *Parser) (error{ UnexpectedToken, ExpectedIdentifier, OutOfMemory } || std.fmt.ParseFloatError)!Stmt {
        if (self.match(&[_]Token{ .Kernel })) {
            return try self.kernelDecl();
        }
        if (self.match(&[_]Token{ .Let })) {
            return try self.varDecl();
        }
        return error.UnexpectedToken;
    }

    fn kernelDecl(self: *Parser) (error{ UnexpectedToken, ExpectedIdentifier, OutOfMemory } || std.fmt.ParseFloatError)!Stmt {
        const name = switch (self.advance()) {
            .Identifier => |n| n,
            else => return error.ExpectedIdentifier,
        };
        _ = try self.consume(.LeftParen);
        _ = try self.consume(.RightParen);
        _ = try self.consume(.LeftBrace);

        var body: std.ArrayList(Stmt) = .{};
        while (!self.check(.RightBrace) and !self.isAtEnd()) {
            const stmt = try self.declaration();
            try body.append(self.allocator, stmt);
        }
        _ = try self.consume(.RightBrace);

        return Stmt{
            .KernelDecl = KernelDeclStmt{
                .name = name,
                .body = try body.toOwnedSlice(self.allocator),
            },
        };
    }

    fn varDecl(self: *Parser) (error{ UnexpectedToken, ExpectedIdentifier, OutOfMemory } || std.fmt.ParseFloatError)!Stmt {
        const name = switch (self.advance()) {
            .Identifier => |n| n,
            else => return error.ExpectedIdentifier,
        };
        _ = try self.consume(.Equal);
        const value = try self.expression();
        _ = try self.consume(.Semicolon);

        return Stmt{
            .VarDecl = VarDeclStmt{
                .name = name,
                .value = value,
            },
        };
    }

    fn expression(self: *Parser) (error{ UnexpectedToken, OutOfMemory } || std.fmt.ParseFloatError)!Expr {
        return try self.addition();
    }

    fn addition(self: *Parser) (error{ UnexpectedToken, OutOfMemory } || std.fmt.ParseFloatError)!Expr {
        var expr = try self.multiplication();

        while (self.match(&[_]Token{ .Plus, .Minus })) {
            const op = self.previous();
            const right = try self.multiplication();
            const binary = try self.allocator.create(BinaryExpr);
            binary.* = BinaryExpr{
                .left = expr,
                .op = op,
                .right = right,
            };
            expr = Expr{ .Binary = binary };
        }

        return expr;
    }

    fn multiplication(self: *Parser) (error{ UnexpectedToken, OutOfMemory } || std.fmt.ParseFloatError)!Expr {
        var expr = try self.primary();

        while (self.match(&[_]Token{ .Star, .Slash })) {
            const op = self.previous();
            const right = try self.primary();
            const binary = try self.allocator.create(BinaryExpr);
            binary.* = BinaryExpr{
                .left = expr,
                .op = op,
                .right = right,
            };
            expr = Expr{ .Binary = binary };
        }

        return expr;
    }

    fn primary(self: *Parser) (error{ UnexpectedToken, OutOfMemory } || std.fmt.ParseFloatError)!Expr {
        const token = self.advance();
        return switch (token) {
            .Number => |n| Expr{ .Number = n },
            .Identifier => |id| Expr{ .Identifier = id },
            .LeftParen => {
                const expr = try self.expression();
                _ = try self.consume(.RightParen);
                return expr;
            },
            else => error.UnexpectedToken,
        };
    }

    fn match(self: *Parser, types: []const Token) bool {
        for (types) |t| {
            if (self.check(t)) {
                _ = self.advance();
                return true;
            }
        }
        return false;
    }

    fn check(self: *Parser, token_type: Token) bool {
        if (self.isAtEnd()) return false;
        return std.meta.activeTag(self.peek()) == std.meta.activeTag(token_type);
    }

    fn advance(self: *Parser) Token {
        if (!self.isAtEnd()) self.current += 1;
        return self.previous();
    }

    fn consume(self: *Parser, token_type: Token) error{UnexpectedToken}!Token {
        if (self.check(token_type)) return self.advance();
        return error.UnexpectedToken;
    }

    fn isAtEnd(self: *Parser) bool {
        return self.peek() == .Eof;
    }

    fn peek(self: *Parser) Token {
        return self.tokens[self.current];
    }

    fn previous(self: *Parser) Token {
        return self.tokens[self.current - 1];
    }
};
