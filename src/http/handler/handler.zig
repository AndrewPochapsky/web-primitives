const std = @import("std");
const request = @import("../request.zig");
const Request = request.Request;
const Response = @import("../response.zig").Response;

pub const Handler = struct {
    ptr: *anyopaque,
    handleFn: *const fn (ptr: *anyopaque, allocator: std.mem.Allocator, req: Request) anyerror!Response,

    pub fn init(ptr: anytype) Handler {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        const gen = struct {
            pub fn handle(pointer: *anyopaque, allocator: std.mem.Allocator, req: Request) anyerror!Response {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.pointer.child.handle(self, allocator, req);
            }
        };

        return .{
            .ptr = ptr,
            .handleFn = gen.handle,
        };
    }

    pub fn handle(self: Handler, allocator: std.mem.Allocator, req: Request) !Response {
        return self.handleFn(self.ptr, allocator, req);
    }
};
