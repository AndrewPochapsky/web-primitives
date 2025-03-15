const std = @import("std");
const request = @import("request.zig");
const Request = request.Request;
const Method = request.Method;

const RESPONSE_TEMPLATE = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\nContent-Length: {d}\r\n\r\n{s}";

pub fn handleRequest(allocator: std.mem.Allocator, req: Request) ![]u8 {
    switch (req.method) {
        Method.Get => {
            const file_path = try std.fmt.allocPrint(allocator, "src/app{s}", .{req.path});
            defer allocator.free(file_path);
            const file_contents = readFile(file_path) catch |err| {
                std.debug.print("Error getting file: {s}, {}\n", .{ file_path, err });
                return "";
            };
            defer file_contents.deinit();
            const content_length = file_contents.items.len;
            const return_message = try std.fmt.allocPrint(allocator, RESPONSE_TEMPLATE, .{ content_length, file_contents.items });
            return return_message;
        },
        Method.Post => {},
        Method.Head => {},
    }
    return undefined;
}

fn readFile(file_path: []const u8) !std.ArrayList(u8) {
    var file = try std.fs.cwd().openFile(file_path, .{});
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var output: std.ArrayList(u8) = std.ArrayList(u8).init(std.heap.page_allocator);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var i: u32 = 0;
        while (i < line.len) {
            try output.append(line[i]);
            i += 1;
        }
        try output.append('\n');
    }

    return output;
}
