const std = @import("std");
const net = std.net;
const print = std.debug.print;

const http_request = @import("http/request.zig");
const HttpRequest = http_request.Request;
const Method = http_request.Method;
const handler = @import("http/handler.zig");

const PORT = 1234;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const loopback = try net.Ip4Address.parse("127.0.0.1", PORT);
    const localhost = net.Address{ .in = loopback };
    var server = try localhost.listen(.{
        .reuse_address = true,
    });
    defer server.deinit();

    const addr = server.listen_address;
    print("Listening on {}, access this port to end the program\n", .{addr.getPort()});
    while (true) {
        var client: net.Server.Connection = try server.accept();
        defer client.stream.close();

        print("Connection received! {} is sending data.\n", .{client.address});
        var buffer = std.mem.zeroes([http_request.MAX_MESSAGE_SIZE]u8);
        const message_len: usize = try client.stream.reader().read(&buffer);
        var request_result = http_request.parseMessage(allocator, buffer, message_len);
        if (request_result) |*request| {
            defer request.deinit();

            const return_message = try handler.handleRequest(allocator, request.*);
            defer allocator.free(return_message);

            _ = try client.stream.writer().writeAll(return_message);
        } else |err| {
            print("Error parsing request {}\n", .{err});
        }
    }
}
