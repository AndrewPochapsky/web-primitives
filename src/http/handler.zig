const std = @import("std");
const request = @import("request.zig");
const Request = request.Request;
const Method = request.Method;

const RESPONSE_TEMPLATE = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\nContent-Length: {d}\r\n\r\n{s}";
const NOT_FOUND_RESPONSE = "HTTP/1.1 404 Not Found\r\nContent-Type: text/html\r\nContent-Length: 48\r\nConnection: close\r\n\r\n<!DOCTYPE html> <html><body>404 Not Found</body></html>";
const ArrayList = std.ArrayListUnmanaged;

pub const Response = union(enum) {
    allocated: []u8,
    static: []const u8,

    pub fn deinit(self: @This(), allocator: std.mem.Allocator) void {
        switch (self) {
            .allocated => |data| {
                allocator.free(data);
            },
            .static => {},
        }
    }

    pub fn getData(self: @This()) []const u8 {
        switch (self) {
            .allocated => |data| {
                return data;
            },
            .static => |data| {
                return data;
            },
        }
    }
};

pub fn handleRequest(allocator: std.mem.Allocator, req: Request) !Response {
    switch (req.method) {
        Method.Get => {
            const file_path = try std.fmt.allocPrint(allocator, "src/app{s}", .{req.path});
            defer allocator.free(file_path);
            var file_contents = readFile(allocator, file_path) catch |err| {
                std.debug.print("Error getting file: {s}, {}\n", .{ file_path, err });
                return .{ .static = NOT_FOUND_RESPONSE };
            };
            defer file_contents.deinit(allocator);
            const content_length = file_contents.items.len;
            const return_message = try std.fmt.allocPrint(allocator, RESPONSE_TEMPLATE, .{ content_length, file_contents.items });
            return .{ .allocated = return_message };
        },
        Method.Post => {},
        Method.Head => {},
    }
    return undefined;
}

fn readFile(allocator: std.mem.Allocator, file_path: []const u8) !ArrayList(u8) {
    var file = try std.fs.cwd().openFile(file_path, .{});
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var output: ArrayList(u8) = .empty;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var i: u32 = 0;
        while (i < line.len) {
            try output.append(allocator, line[i]);
            i += 1;
        }
        try output.append(allocator, '\n');
    }

    return output;
}
