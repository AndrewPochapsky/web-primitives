const std = @import("std");
const handler = @import("handler.zig");
const Handler = handler.Handler;
const response = @import("../response.zig");
const Response = response.Response;
const request = @import("../request.zig");
const Request = request.Request;
const Method = request.Method;

const NOT_FOUND_BODY = "<!DOCTYPE html> <html><body>404 Not Found</body></html>";

pub const HtmlHandler = struct {
    pub fn handle(_: *HtmlHandler, allocator: std.mem.Allocator, req: Request) anyerror!Response {
        switch (req.method) {
            Method.Get => {
                const file_path = try std.fmt.allocPrint(allocator, "src/app{s}", .{req.path});
                defer allocator.free(file_path);
                const file_contents = readFile(allocator, file_path) catch |err| {
                    std.debug.print("Error getting file: {s}, {}\n", .{ file_path, err });
                    return .{
                        .status_code = .not_found,
                        .content_type = .html,
                        .body = .{ .static = NOT_FOUND_BODY },
                    };
                };
                return .{
                    .status_code = .ok,
                    .content_type = .html,
                    .body = .{ .allocated = file_contents },
                };
            },
            Method.Post => {},
            Method.Head => {},
        }
        return undefined;
    }

    pub fn handler(self: *HtmlHandler) Handler {
        return Handler.init(self);
    }
};

fn readFile(allocator: std.mem.Allocator, file_path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(file_path, .{});
    return try file.reader().readAllAlloc(allocator, 1024);
}
