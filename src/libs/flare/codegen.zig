const std = @import("std");
const Stmt = @import("parser.zig").Stmt;
const Expr = @import("parser.zig").Expr;

pub const CodeGen = struct {
    allocator: std.mem.Allocator,
    output: std.ArrayList(u8),
    indent_level: usize,

    pub fn init(allocator: std.mem.Allocator) CodeGen {
        return CodeGen{
            .allocator = allocator,
            .output = .{},
            .indent_level = 0,
        };
    }

    pub fn generate(self: *CodeGen, stmts: []Stmt) ![]u8 {
        for (stmts) |stmt| {
            try self.genStmt(stmt);
        }
        return self.output.toOwnedSlice(self.allocator);
    }

    fn genStmt(self: *CodeGen, stmt: Stmt) !void {
        switch (stmt) {
            .KernelDecl => |k| {
                try self.writeIndent();
                try self.output.appendSlice(self.allocator, "void ");
                try self.output.appendSlice(self.allocator, k.name);
                try self.output.appendSlice(self.allocator, "() {\n");
                self.indent_level += 1;
                for (k.body) |s| {
                    try self.genStmt(s);
                }
                self.indent_level -= 1;
                try self.writeIndent();
                try self.output.appendSlice(self.allocator, "}\n");
            },
            .VarDecl => |v| {
                try self.writeIndent();
                try self.output.appendSlice(self.allocator, "auto ");
                try self.output.appendSlice(self.allocator, v.name);
                try self.output.appendSlice(self.allocator, " = ");
                try self.genExpr(v.value);
                try self.output.appendSlice(self.allocator, ";\n");
            },
        }
    }

    fn genExpr(self: *CodeGen, expr: Expr) !void {
        switch (expr) {
            .Number => |n| {
                const str = try std.fmt.allocPrint(self.allocator, "{d}", .{n});
                defer self.allocator.free(str);
                try self.output.appendSlice(self.allocator, str);
            },
            .Identifier => |id| {
                try self.output.appendSlice(self.allocator, id);
            },
            .Binary => |b| {
                try self.output.appendSlice(self.allocator, "(");
                try self.genExpr(b.left);
                try self.output.appendSlice(self.allocator, " ");
                const op_str = switch (b.op) {
                    .Plus => "+",
                    .Minus => "-",
                    .Star => "*",
                    .Slash => "/",
                    else => "?",
                };
                try self.output.appendSlice(self.allocator, op_str);
                try self.output.appendSlice(self.allocator, " ");
                try self.genExpr(b.right);
                try self.output.appendSlice(self.allocator, ")");
            },
        }
    }

    fn writeIndent(self: *CodeGen) !void {
        var i: usize = 0;
        while (i < self.indent_level) : (i += 1) {
            try self.output.appendSlice(self.allocator, "    ");
        }
    }

    pub fn deinit(self: *CodeGen) void {
        self.output.deinit(self.allocator);
    }
};
