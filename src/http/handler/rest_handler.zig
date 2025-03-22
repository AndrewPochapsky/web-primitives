const std = @import("std");
const handler = @import("handler.zig");
const Handler = handler.Handler;
const response = @import("../response.zig");
const Response = response.Response;
const request = @import("../request.zig");
const Request = request.Request;
const Method = request.Method;

const RouteFn = fn (std.mem.Allocator, Request) anyerror!Response;

pub const RestHandler = struct {
    get_routes: std.StringHashMapUnmanaged(*const RouteFn),
    post_routes: std.StringHashMapUnmanaged(*const RouteFn),

    pub fn init() @This() {
        return .{ .get_routes = .empty, .post_routes = .empty };
    }

    pub fn put_get_route(
        self: *@This(),
        allocator: std.mem.Allocator,
        path: []const u8,
        route_fn: *const RouteFn,
    ) !void {
        try self.get_routes.put(allocator, path, route_fn);
    }

    pub fn handle(self: *@This(), allocator: std.mem.Allocator, req: Request) anyerror!Response {
        switch (req.method) {
            Method.Get => {
                if (self.get_routes.get(req.path)) |route_fn| {
                    return route_fn(allocator, req);
                } else {
                    std.debug.print("No route matches", .{});
                }
            },
            Method.Post => {},
            Method.Head => {},
        }
        return undefined;
    }

    pub fn handler(self: *RestHandler) Handler {
        return Handler.init(self);
    }
};
