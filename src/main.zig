const std = @import("std");
const Server = @import("http/server.zig").Server;
const Request = @import("http/request.zig").Request;
const Response = @import("http/response.zig").Response;
const HtmlHandler = @import("http/handler/html_handler.zig").HtmlHandler;
const RestHandler = @import("http/handler/rest_handler.zig").RestHandler;

const PORT = 1234;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    //var html_handler = HtmlHandler{};
    var rest_handler = RestHandler.init();

    try rest_handler.put_get_route(allocator, "/user", struct {
        fn func(alloc: std.mem.Allocator, req: Request) anyerror!Response {
            _ = req;
            _ = alloc;
            return .{
                .status_code = .ok,
                .content_type = .json,
                .body = .{ .static = "Hey there" },
            };
        }
    }.func);

    var server = try Server.init(allocator, PORT, rest_handler.handler());
    defer server.deinit(allocator);

    try server.start(allocator);
}
