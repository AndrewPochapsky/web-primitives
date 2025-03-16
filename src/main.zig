const std = @import("std");
const Server = @import("http/server.zig").Server;
const HtmlHandler = @import("http/handler/html_handler.zig").HtmlHandler;

const PORT = 1234;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var html_handler = HtmlHandler{};
    var server = try Server.init(allocator, PORT, html_handler.handler());
    defer server.deinit(allocator);

    try server.start(allocator);
}
