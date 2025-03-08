const std = @import("std");
const net = std.net;
const print = std.debug.print;

const http_request = @import("http/request.zig");
const HttpRequest = http_request.Request;
const Method = http_request.Method;

const PORT = 1234;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    //const allocator = gpa.allocator();

    const loopback = try net.Ip4Address.parse("127.0.0.1", PORT);
    const localhost = net.Address{ .in = loopback };
    var server = try localhost.listen(.{
        .reuse_address = true,
    });
    defer server.deinit();

    const addr = server.listen_address;
    print("Listening on {}, access this port to end the program\n", .{addr.getPort()});

    var client: net.Server.Connection = try server.accept();
    defer client.stream.close();

    print("Connection received! {} is sending data.\n", .{client.address});

    var buffer = std.mem.zeroes([http_request.MAX_MESSAGE_SIZE]u8);
    const message_len: usize = try client.stream.reader().readAll(&buffer);
    const request: HttpRequest = try http_request.parseMessage(buffer, message_len);

    print("Request: {}", .{request});
}
