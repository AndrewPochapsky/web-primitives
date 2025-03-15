const std = @import("std");
const net = std.net;
const print = std.debug.print;

const http_request = @import("request.zig");
const handler = @import("handler.zig");
const Response = handler.Response;

pub const Server = struct {
    server: net.Server,

    pub fn init(port: u16) !@This() {
        const loopback = try net.Ip4Address.parse("127.0.0.1", port);
        const localhost = net.Address{ .in = loopback };
        const server = try localhost.listen(.{
            .reuse_address = true,
        });
        return .{ .server = server };
    }

    pub fn start(self: *@This(), allocator: std.mem.Allocator) !void {
        print("Listening on {}, access this port to end the program\n", .{self.server.listen_address.getPort()});
        while (true) {
            try self.handleRequest(allocator);
        }
    }

    pub fn deinit(self: *@This()) void {
        self.server.deinit();
    }

    fn handleRequest(self: *@This(), allocator: std.mem.Allocator) !void {
        var client: net.Server.Connection = try self.server.accept();
        defer client.stream.close();

        print("Connection received! {} is sending data.\n", .{client.address});
        var buffer = std.mem.zeroes([http_request.MAX_MESSAGE_SIZE]u8);
        const message_len: usize = try client.stream.reader().read(&buffer);
        var request_result = http_request.parseMessage(allocator, buffer, message_len);
        if (request_result) |*request| {
            defer request.deinit();
            print("Parsed request: {} {s}\n", .{ request.method, request.path });
            const return_response: Response = try handler.handleRequest(allocator, request.*);
            defer return_response.deinit(allocator);

            _ = try client.stream.writer().writeAll(return_response.getData());
        } else |err| {
            print("Error parsing request {}\n", .{err});
        }
    }
};
