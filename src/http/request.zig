const std = @import("std");

pub const Error = error{ UnknownMethod, UnexpectedEof, UnsupportedVersion };

pub const MAX_MESSAGE_SIZE = 1024 * 8 + 1024 * 100;

pub const Method = enum {
    Get,
    Head,
    Post,
};

pub const Request = struct {
    method: Method,
    path: []const u8,
    headers: std.StringHashMap([]const u8),
    body: []const u8,

    pub fn deinit(self: *@This()) void {
        self.headers.deinit();
    }
};

const RequestParser = struct {
    index: usize,
    message: [MAX_MESSAGE_SIZE]u8,
    message_len: usize,

    fn parse(self: *@This(), allocator: std.mem.Allocator) !Request {
        const method = try self.parseMethod();
        const path = try self.parsePath();
        const version = try self.parseVersion();
        if (!bytesEql(version, "HTTP/1.1\r")) {
            return Error.UnsupportedVersion;
        }
        const headers = try self.parseHeaders(allocator);
        const body = self.message[self.index..self.message_len];
        return Request{
            .method = method,
            .path = path,
            .headers = headers,
            .body = body,
        };
    }

    fn parseMethod(self: *@This()) Error!Method {
        const bytes = try self.readBytesUntilDelim(' ');
        if (bytesEql(bytes, "GET")) {
            return Method.Get;
        } else if (bytesEql(bytes, "POST")) {
            return Method.Post;
        } else if (bytesEql(bytes, "HEAD")) {
            return Method.Head;
        }
        return Error.UnknownMethod;
    }

    fn parsePath(self: *@This()) Error![]const u8 {
        return try self.readBytesUntilDelim(' ');
    }

    fn parseVersion(self: *@This()) Error![]const u8 {
        return try self.readBytesUntilDelim('\n');
    }

    fn readByte(self: *@This()) u8 {
        self.index += 1;
        return self.message[self.index - 1];
    }

    fn parseHeaders(self: *@This(), allocator: std.mem.Allocator) !std.StringHashMap([]const u8) {
        var headers = std.StringHashMap([]const u8).init(allocator);
        while (self.message[self.index] != '\r') {
            const key = try self.readBytesUntilDelim(':');
            if (self.message[self.index] == ' ') {
                self.index += 1;
            }
            const value = try self.readBytesUntilDelim('\n');
            try headers.put(key, value);
        }
        return headers;
    }

    fn readBytes(self: *@This(), num: usize) []const u8 {
        const slice = self.message[self.index .. self.index + num];
        self.index += num;
        return slice;
    }

    fn readBytesUntilDelim(self: *@This(), delim: u8) Error![]const u8 {
        const start = self.index;
        while (self.message[self.index] != delim) {
            self.index += 1;
            if (self.index == self.message_len) {
                return Error.UnexpectedEof;
            }
        }
        const slice = self.message[start..self.index];
        // Skip the delim
        self.index += 1;
        return slice;
    }
};

fn bytesEql(bytes: []const u8, other: []const u8) bool {
    return std.mem.eql(u8, bytes, other);
}

pub fn parseMessage(allocator: std.mem.Allocator, message: [MAX_MESSAGE_SIZE]u8, message_len: usize) !Request {
    var parser: RequestParser = .{ .index = 0, .message = message, .message_len = message_len };
    return try parser.parse(allocator);
}
