const std = @import("std");
const s = @import("http/server.zig");

const PORT = 1234;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var server = try s.init(PORT);
    defer server.deinit();

    try server.start(allocator);
}
