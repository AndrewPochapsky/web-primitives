const std = @import("std");

pub const Method = enum {
    Get,
    Head,
    Post,
};

pub const Request = struct {
    method: Method,
    path: []const u8,
};
