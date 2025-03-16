const std = @import("std");
const net = std.net;
const print = std.debug.print;
const Pool = std.Thread.Pool;

const http_request = @import("request.zig");
const handler = @import("handler/handler.zig");
const Response = @import("response.zig").Response;

pub const Server = struct {
    server: net.Server,
    pool: *Pool,
    handler: handler.Handler,

    pub fn init(allocator: std.mem.Allocator, port: u16, handler_impl: handler.Handler) !@This() {
        const loopback = try net.Ip4Address.parse("127.0.0.1", port);
        const localhost = net.Address{ .in = loopback };
        const server = try localhost.listen(.{
            .reuse_address = true,
        });
        const pool: *Pool = try allocator.create(Pool);
        try Pool.init(pool, .{ .n_jobs = 64, .allocator = allocator });
        return .{ .server = server, .pool = pool, .handler = handler_impl };
    }

    pub fn start(self: *@This(), allocator: std.mem.Allocator) !void {
        print("Listening on {}, access this port to end the program\n", .{self.server.listen_address.getPort()});
        while (true) {
            const connection: net.Server.Connection = try self.server.accept();
            print("{d}: Spawning thread\n", .{std.time.timestamp()});
            try self.pool.spawn(handleRequest, .{ self, allocator, connection });
        }
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.server.deinit();
        self.pool.deinit();
        allocator.destroy(self.pool);
    }

    fn handleRequest(self: *@This(), allocator: std.mem.Allocator, connection: net.Server.Connection) void {
        defer connection.stream.close();

        print("Connection received! {} is sending data.\n", .{connection.address});
        var buffer = std.mem.zeroes([http_request.MAX_MESSAGE_SIZE]u8);
        const message_len: usize = connection.stream.reader().read(&buffer) catch |err| {
            print("Error reading request data: {}\n", .{err});
            return;
        };
        var request_result = http_request.parseMessage(allocator, buffer, message_len);
        if (request_result) |*request| {
            defer request.deinit();
            print("Parsed request: {} {s}\n", .{ request.method, request.path });
            var return_response: Response = self.handler.handle(allocator, request.*) catch |err| {
                print("Error handling request: {}\n", .{err});
                return;
            };
            defer return_response.deinit(allocator);

            return_response.write(allocator, connection.stream.writer()) catch |err| {
                print("Error writingr response: {}\n", .{err});
            };
        } else |err| {
            print("Error parsing request {}\n", .{err});
        }
    }
};
