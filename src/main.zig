const std = @import("std");
const net = std.net;
const print = std.debug.print;

const http_request = @import("http/request.zig");
const HttpRequest = http_request.Request;
const Method = http_request.Method;

const PORT = 1234;

const Error = error{UnknownMethod};

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

    var client: net.Server.Connection = try server.accept();
    defer client.stream.close();

    print("Connection received! {} is sending data.\n", .{client.address});

    try parseRequest(client);
    const message: []const u8 = try client.stream.reader().readAllAlloc(allocator, 1024);
    defer allocator.free(message);

    print("{} says {s}\n", .{ client.address, message });
}

fn parseRequest(connection: net.Server.Connection) !void {
    const method = try parseMethod(connection);
    print("method: {}\n", .{method});
}

fn parseMethod(connection: net.Server.Connection) !Method {
    const reader = connection.stream.reader();
    const firstBytes = try reader.readBytesNoEof(3);
    if (std.mem.eql(u8, &firstBytes, "GET")) {
        return Method.Get;
    } else if (std.mem.eql(u8, &firstBytes, "POS")) {
        const nextByte = try reader.readByte();
        if (nextByte == 'T') {
            return Method.Post;
        }
    } else if (std.mem.eql(u8, &firstBytes, "HEA")) {
        const nextByte = try reader.readByte();
        if (nextByte == 'D') {
            return Method.Head;
        }
    }
    return Error.UnknownMethod;
}
