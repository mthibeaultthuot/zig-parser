const std = @import("std");
const lexer = @import("flare_lexer");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const src =
        \\kernel simple_kernel() {
        \\ let i = 1;
        \\ let j = 2 + 3;
        \\}
    ;

    var lex = lexer.Lexer.init(src, allocator);
    defer lex.deinit();

    const tokens = try lex.lex();

    var parser = lexer.Parser.init(tokens.items, allocator);
    const ast = try parser.parse();
    defer {
        for (ast) |stmt| {
            stmt.deinit(allocator);
        }
        allocator.free(ast);
    }

    var codegen = lexer.CodeGen.init(allocator);
    defer codegen.deinit();

    const cpp_code = try codegen.generate(ast);
    defer allocator.free(cpp_code);

    std.debug.print("{s}\n", .{cpp_code});
}

fn printStmt(stmt: lexer.Stmt, indent: usize) void {
    printIndent(indent);
    switch (stmt) {
        .KernelDecl => |k| {
            std.debug.print("Kernel: {s}\n", .{k.name});
            for (k.body) |s| {
                printStmt(s, indent + 1);
            }
        },
        .VarDecl => |v| {
            std.debug.print("Let {s} = ", .{v.name});
            printExpr(v.value);
            std.debug.print("\n", .{});
        },
    }
}

fn printExpr(expr: lexer.Expr) void {
    switch (expr) {
        .Number => |n| std.debug.print("{d}", .{n}),
        .Identifier => |id| std.debug.print("{s}", .{id}),
        .Binary => |b| {
            std.debug.print("(", .{});
            printExpr(b.left);
            const op_str = switch (b.op) {
                .Plus => "+",
                .Minus => "-",
                .Star => "*",
                .Slash => "/",
                else => "?",
            };
            std.debug.print(" {s} ", .{op_str});
            printExpr(b.right);
            std.debug.print(")", .{});
        },
    }
}

fn printIndent(indent: usize) void {
    var i: usize = 0;
    while (i < indent) : (i += 1) {
        std.debug.print("  ", .{});
    }
}
