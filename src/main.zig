const std = @import("std");
const Server = @import("http/server.zig").Server;

const PORT = 1234;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var server = try Server.init(PORT);
    defer server.deinit();

    try server.start(allocator);
}
