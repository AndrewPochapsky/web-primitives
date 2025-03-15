const std = @import("std");
const net = std.net;
const print = std.debug.print;
const Pool = std.Thread.Pool;

const http_request = @import("request.zig");
const handler = @import("handler.zig");
const Response = handler.Response;

pub const Server = struct {
    server: net.Server,
    pool: *Pool,

    pub fn init(allocator: std.mem.Allocator, port: u16) !@This() {
        const loopback = try net.Ip4Address.parse("127.0.0.1", port);
        const localhost = net.Address{ .in = loopback };
        const server = try localhost.listen(.{
            .reuse_address = true,
        });
        const pool: *Pool = try allocator.create(Pool);
        try Pool.init(pool, .{ .n_jobs = 16, .allocator = allocator });
        return .{ .server = server, .pool = pool };
    }

    pub fn start(self: *@This(), allocator: std.mem.Allocator) !void {
        print("Listening on {}, access this port to end the program\n", .{self.server.listen_address.getPort()});
        while (true) {
            try self.pool.spawn(handleRequest, .{ self, allocator });
        }
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.server.deinit();
        self.pool.deinit();
        allocator.destroy(self.pool);
    }

    fn handleRequest(self: *@This(), allocator: std.mem.Allocator) void {
        var client: net.Server.Connection = self.server.accept() catch |err| {
            print("Error accepting request: {}\n", .{err});
            return;
        };
        defer client.stream.close();

        print("Connection received! {} is sending data.\n", .{client.address});
        var buffer = std.mem.zeroes([http_request.MAX_MESSAGE_SIZE]u8);
        const message_len: usize = client.stream.reader().read(&buffer) catch |err| {
            print("Error reading request data: {}\n", .{err});
            return;
        };
        var request_result = http_request.parseMessage(allocator, buffer, message_len);
        if (request_result) |*request| {
            defer request.deinit();
            print("Parsed request: {} {s}\n", .{ request.method, request.path });
            const return_response: Response = handler.handleRequest(allocator, request.*) catch |err| {
                print("Error handling request: {}\n", .{err});
                return;
            };
            defer return_response.deinit(allocator);

            _ = client.stream.writer().writeAll(return_response.getData()) catch |err| {
                print("Error writingr response: {}\n", .{err});
            };
        } else |err| {
            print("Error parsing request {}\n", .{err});
        }
    }
};
