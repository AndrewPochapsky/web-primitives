const std = @import("std");
const request = @import("request.zig");
const Request = request.Request;
const Method = request.Method;

const RESPONSE_TEMPLATE = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\nContent-Length: {d}\r\n\r\n{s}";

const ArrayList = std.ArrayListUnmanaged;

pub fn handleRequest(allocator: std.mem.Allocator, req: Request) ![]u8 {
    switch (req.method) {
        Method.Get => {
            const file_path = try std.fmt.allocPrint(allocator, "src/app{s}", .{req.path});
            defer allocator.free(file_path);
            var file_contents = readFile(allocator, file_path) catch |err| {
                std.debug.print("Error getting file: {s}, {}\n", .{ file_path, err });
                return "";
            };
            defer file_contents.deinit(allocator);
            const content_length = file_contents.items.len;
            const return_message = try std.fmt.allocPrint(allocator, RESPONSE_TEMPLATE, .{ content_length, file_contents.items });
            return return_message;
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
