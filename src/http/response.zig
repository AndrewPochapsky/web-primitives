const std = @import("std");

const RESPONSE_TEMPLATE = "HTTP/1.1 {s}\r\nContent-Type: {s}\r\nConnection: close\r\nContent-Length: {d}\r\n\r\n{s}";

pub const Response = struct {
    status_code: StatusCode,
    content_type: ContentType,
    body: ResponseBody,

    pub fn write(self: @This(), allocator: std.mem.Allocator, writer: anytype) !void {
        const body = self.body.getData();
        const response = try std.fmt.allocPrint(allocator, RESPONSE_TEMPLATE, .{
            self.status_code.toText(),
            self.content_type.toText(),
            body.len,
            body,
        });
        defer allocator.free(response);
        _ = try writer.writeAll(response);
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.body.deinit(allocator);
    }
};

pub const StatusCode = enum {
    ok,
    not_found,
    bad_request,
    internal_server_error,

    fn toText(self: @This()) []const u8 {
        return switch (self) {
            .ok => "200 OK",
            .not_found => "404 Not Found",
            .bad_request => "400 Bad Request",
            .internal_server_error => "500 Internal Server Error",
        };
    }
};

pub const ContentType = enum {
    html,
    json,

    fn toText(self: @This()) []const u8 {
        return switch (self) {
            .html => "text/html",
            .json => "application/json",
        };
    }
};

pub const ResponseBody = union(enum) {
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
