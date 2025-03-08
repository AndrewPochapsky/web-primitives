const std = @import("std");

pub const Error = error{UnknownMethod};

pub const MAX_MESSAGE_SIZE = 1024 * 8 + 1024 * 1000;

pub const Method = enum {
    Get,
    Head,
    Post,
};

pub const Request = struct {
    method: Method,
    path: []const u8,
};

const RequestParser = struct {
    index: usize,
    message: [MAX_MESSAGE_SIZE]u8,
    message_len: usize,

    fn parse(self: *@This()) Error!Request {
        const method = try self.parseMethod();
        return Request{ .method = method, .path = "" };
    }

    fn parseMethod(self: *@This()) Error!Method {
        const firstBytes = self.readBytes(3);
        if (bytesEql(firstBytes, "GET")) {
            return Method.Get;
        } else if (bytesEql(firstBytes, "POS")) {
            const nextByte = self.readByte();
            if (nextByte == 'T') {
                return Method.Post;
            }
        } else if (bytesEql(firstBytes, "HEA")) {
            const nextByte = self.readByte();
            if (nextByte == 'D') {
                return Method.Head;
            }
        }
        return Error.UnknownMethod;
    }

    fn readByte(self: *@This()) u8 {
        self.index += 1;
        return self.message[self.index - 1];
    }

    fn readBytes(self: *@This(), num: usize) []const u8 {
        const slice = self.message[self.index .. self.index + num];
        self.index += num;
        return slice;
    }
};

fn bytesEql(bytes: []const u8, other: []const u8) bool {
    return std.mem.eql(u8, bytes, other);
}

pub fn parseMessage(message: [MAX_MESSAGE_SIZE]u8, message_len: usize) Error!Request {
    var parser: RequestParser = .{ .index = 0, .message = message, .message_len = message_len };
    return try parser.parse();
}
