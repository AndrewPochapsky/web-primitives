const std = @import("std");
const net = std.net;
const print = std.debug.print;

const http_request = @import("http/request.zig");
const HttpRequest = http_request.Request;
const Method = http_request.Method;
const handler = @import("http/handler.zig");
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
