const std = @import("std");
const WaylandRuntime = @import("../WaylandRuntime.zig");
const types = @import("../types.zig");

/// # wl_display
/// 
/// ## Summary
/// 
///     core global object
/// 
/// ## Description
/// 
///       The core global object.  This is a special singleton object.  It
///       is used for internal Wayland protocol features.
///     
pub const wl_display = struct {
    pub const interface = "wl_display";
    pub const version = 1;

    pub const enums = struct{
        /// # error
        /// 
        /// ## Summary
        /// 
        ///     global error values
        /// 
        /// ## Description
        /// 
        ///     These errors are global and can be emitted in response to any
        ///     server request.
        ///       
        pub const @"error" = enum(u32) {
            invalid_object = 0,
            invalid_method = 1,
            no_memory = 2,
            implementation = 3,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # sync
    /// 
    /// ## Summary
    /// 
    ///     asynchronous roundtrip
    /// 
    /// ## Description
    /// 
    ///     The sync request asks the server to emit the 'done' event
    ///     on the returned wl_callback object.  Since requests are
    ///     handled in-order and events are delivered in-order, this can
    ///     be used as a barrier to ensure all previous requests and the
    ///     resulting events have been handled.
    /// 
    ///     The object returned by this request will be destroyed by the
    ///     compositor after the callback is fired and as such the client must not
    ///     attempt to use it after that point.
    /// 
    ///     The callback_data passed in the callback is undefined and should be ignored.
    ///       
    /// ## Args 
    /// 
    /// ### callback
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Summary
    /// 
    ///     callback object for the sync request
    /// 
    /// #### Interface
    /// 
    ///     wl_callback
    /// 
    /// 
    pub fn sync(self: *const wl_display) !struct { callback: wl_callback, } {
        const callback_id = self.runtime.getId();
        try self.runtime.sendRequest(self.object_id, 0, .{callback_id, });
        return .{.callback = wl_callback{.object_id = callback_id, .runtime = self.runtime}, };
    }

    /// # get_registry
    /// 
    /// ## Summary
    /// 
    ///     get global registry object
    /// 
    /// ## Description
    /// 
    ///     This request creates a registry object that allows the client
    ///     to list and bind the global objects available from the
    ///     compositor.
    /// 
    ///     It should be noted that the server side resources consumed in
    ///     response to a get_registry request can only be released when the
    ///     client disconnects, not when the client side proxy is destroyed.
    ///     Therefore, clients should invoke get_registry as infrequently as
    ///     possible to avoid wasting memory.
    ///       
    /// ## Args 
    /// 
    /// ### registry
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Summary
    /// 
    ///     global registry object
    /// 
    /// #### Interface
    /// 
    ///     wl_registry
    /// 
    /// 
    pub fn get_registry(self: *const wl_display) !struct { registry: wl_registry, } {
        const registry_id = self.runtime.getId();
        try self.runtime.sendRequest(self.object_id, 1, .{registry_id, });
        return .{.registry = wl_registry{.object_id = registry_id, .runtime = self.runtime}, };
    }

    /// # error
    /// 
    /// ## Summary
    /// 
    ///     fatal error event
    /// 
    /// ## Description
    /// 
    ///     The error event is sent out when a fatal (non-recoverable)
    ///     error has occurred.  The object_id argument is the object
    ///     where the error occurred, most often in response to a request
    ///     to that object.  The code identifies the error and is defined
    ///     by the object interface.  As such, each interface defines its
    ///     own set of error codes.  The message is a brief description
    ///     of the error, for (debugging) convenience.
    ///       
    /// ## Args 
    /// 
    /// ### object_id
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     object where the error occurred
    /// 
    /// ### code
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     error code
    /// 
    /// ### message
    /// 
    /// #### Type
    /// 
    ///     string
    /// 
    /// #### Summary
    /// 
    ///     error description
    /// 
    /// 
    pub fn next_error(self: *const wl_display) !?struct {object_id: types.ObjectId, code: u32, message: types.String, } {
        return try self.runtime.next(self.object_id, 0, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_error)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # delete_id
    /// 
    /// ## Summary
    /// 
    ///     acknowledge object ID deletion
    /// 
    /// ## Description
    /// 
    ///     This event is used internally by the object ID management
    ///     logic. When a client deletes an object that it had created,
    ///     the server will send this event to acknowledge that it has
    ///     seen the delete request. When the client receives this event,
    ///     it will know that it can safely reuse the object ID.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     deleted object ID
    /// 
    /// 
    pub fn next_delete_id(self: *const wl_display) !?struct {id: u32, } {
        return try self.runtime.next(self.object_id, 1, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_delete_id)).@"fn".return_type.?).error_union.payload).optional.child);
}
};

/// # wl_registry
/// 
/// ## Summary
/// 
///     global registry object
/// 
/// ## Description
/// 
///       The singleton global registry object.  The server has a number of
///       global objects that are available to all clients.  These objects
///       typically represent an actual object in the server (for example,
///       an input device) or they are singleton objects that provide
///       extension functionality.
/// 
///       When a client creates a registry object, the registry object
///       will emit a global event for each global currently in the
///       registry.  Globals come and go as a result of device or
///       monitor hotplugs, reconfiguration or other events, and the
///       registry will send out global and global_remove events to
///       keep the client up to date with the changes.  To mark the end
///       of the initial burst of events, the client can use the
///       wl_display.sync request immediately after calling
///       wl_display.get_registry.
/// 
///       A client can bind to a global object by using the bind
///       request.  This creates a client-side handle that lets the object
///       emit events to the client and lets the client invoke requests on
///       the object.
///     
pub const wl_registry = struct {
    pub const interface = "wl_registry";
    pub const version = 1;

    pub const enums = struct{    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # bind
    /// 
    /// ## Summary
    /// 
    ///     bind an object to the display
    /// 
    /// ## Description
    /// 
    ///     Binds a new, client-created object to the server using the
    ///     specified name as the identifier.
    ///       
    /// ## Args 
    /// 
    /// ### name
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     unique numeric name of the object
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Summary
    /// 
    ///     bounded object
    /// 
    /// 
    pub fn bind(self: *const wl_registry, name: u32, id: type, id_version: ?u32) !struct { id: id, } {
        const id_id = self.runtime.getId();
        try self.runtime.sendRequest(self.object_id, 0, .{name, types.NewId{.interface = types.String{.static = id.interface}, .version = id_version orelse id.version, .id = id_id, }, });
        return .{.id = id{.object_id = id_id, .runtime = self.runtime}, };
    }

    /// # global
    /// 
    /// ## Summary
    /// 
    ///     announce global object
    /// 
    /// ## Description
    /// 
    ///     Notify the client of global objects.
    /// 
    ///     The event notifies the client that a global object with
    ///     the given name is now available, and it implements the
    ///     given version of the given interface.
    ///       
    /// ## Args 
    /// 
    /// ### name
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     numeric name of the global object
    /// 
    /// ### interface
    /// 
    /// #### Type
    /// 
    ///     string
    /// 
    /// #### Summary
    /// 
    ///     interface implemented by the object
    /// 
    /// ### version
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     interface version
    /// 
    /// 
    pub fn next_global(self: *const wl_registry) !?struct {name: u32, interface: types.String, version: u32, } {
        return try self.runtime.next(self.object_id, 0, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_global)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # global_remove
    /// 
    /// ## Summary
    /// 
    ///     announce removal of global object
    /// 
    /// ## Description
    /// 
    ///     Notify the client of removed global objects.
    /// 
    ///     This event notifies the client that the global identified
    ///     by name is no longer available.  If the client bound to
    ///     the global using the bind request, the client should now
    ///     destroy that object.
    /// 
    ///     The object remains valid and requests to the object will be
    ///     ignored until the client destroys it, to avoid races between
    ///     the global going away and a client sending a request to it.
    ///       
    /// ## Args 
    /// 
    /// ### name
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     numeric name of the global object
    /// 
    /// 
    pub fn next_global_remove(self: *const wl_registry) !?struct {name: u32, } {
        return try self.runtime.next(self.object_id, 1, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_global_remove)).@"fn".return_type.?).error_union.payload).optional.child);
}
};

/// # wl_callback
/// 
/// ## Summary
/// 
///     callback object
/// 
/// ## Description
/// 
///       Clients can handle the 'done' event to get notified when
///       the related request is done.
/// 
///       Note, because wl_callback objects are created from multiple independent
///       factory interfaces, the wl_callback interface is frozen at version 1.
///     
pub const wl_callback = struct {
    pub const interface = "wl_callback";
    pub const version = 1;

    pub const enums = struct{    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # done
    /// 
    /// ## Summary
    /// 
    ///     done event
    /// 
    /// ## Description
    /// 
    ///     Notify the client when the related request is done.
    ///       
    /// ## Args 
    /// 
    /// ### callback_data
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     request-specific data for the callback
    /// 
    /// 
    pub fn next_done(self: *const wl_callback) !?struct {callback_data: u32, } {
        return try self.runtime.next(self.object_id, 0, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_done)).@"fn".return_type.?).error_union.payload).optional.child);
}
};

/// # wl_compositor
/// 
/// ## Summary
/// 
///     the compositor singleton
/// 
/// ## Description
/// 
///       A compositor.  This object is a singleton global.  The
///       compositor is in charge of combining the contents of multiple
///       surfaces into one displayable output.
///     
pub const wl_compositor = struct {
    pub const interface = "wl_compositor";
    pub const version = 6;

    pub const enums = struct{    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # create_surface
    /// 
    /// ## Summary
    /// 
    ///     create new surface
    /// 
    /// ## Description
    /// 
    ///     Ask the compositor to create a new surface.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Summary
    /// 
    ///     the new surface
    /// 
    /// #### Interface
    /// 
    ///     wl_surface
    /// 
    /// 
    pub fn create_surface(self: *const wl_compositor) !struct { id: wl_surface, } {
        const id_id = self.runtime.getId();
        try self.runtime.sendRequest(self.object_id, 0, .{id_id, });
        return .{.id = wl_surface{.object_id = id_id, .runtime = self.runtime}, };
    }

    /// # create_region
    /// 
    /// ## Summary
    /// 
    ///     create new region
    /// 
    /// ## Description
    /// 
    ///     Ask the compositor to create a new region.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Summary
    /// 
    ///     the new region
    /// 
    /// #### Interface
    /// 
    ///     wl_region
    /// 
    /// 
    pub fn create_region(self: *const wl_compositor) !struct { id: wl_region, } {
        const id_id = self.runtime.getId();
        try self.runtime.sendRequest(self.object_id, 1, .{id_id, });
        return .{.id = wl_region{.object_id = id_id, .runtime = self.runtime}, };
    }
};

/// # wl_shm_pool
/// 
/// ## Summary
/// 
///     a shared memory pool
/// 
/// ## Description
/// 
///       The wl_shm_pool object encapsulates a piece of memory shared
///       between the compositor and client.  Through the wl_shm_pool
///       object, the client can allocate shared memory wl_buffer objects.
///       All objects created through the same pool share the same
///       underlying mapped memory. Reusing the mapped memory avoids the
///       setup/teardown overhead and is useful when interactively resizing
///       a surface or for many small buffers.
///     
pub const wl_shm_pool = struct {
    pub const interface = "wl_shm_pool";
    pub const version = 2;

    pub const enums = struct{    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # create_buffer
    /// 
    /// ## Summary
    /// 
    ///     create a buffer from the pool
    /// 
    /// ## Description
    /// 
    ///     Create a wl_buffer object from the pool.
    /// 
    ///     The buffer is created offset bytes into the pool and has
    ///     width and height as specified.  The stride argument specifies
    ///     the number of bytes from the beginning of one row to the beginning
    ///     of the next.  The format is the pixel format of the buffer and
    ///     must be one of those advertised through the wl_shm.format event.
    /// 
    ///     A buffer will keep a reference to the pool it was created from
    ///     so it is valid to destroy the pool immediately after creating
    ///     a buffer from it.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Summary
    /// 
    ///     buffer to create
    /// 
    /// #### Interface
    /// 
    ///     wl_buffer
    /// 
    /// ### offset
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     buffer byte offset within the pool
    /// 
    /// ### width
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     buffer width, in pixels
    /// 
    /// ### height
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     buffer height, in pixels
    /// 
    /// ### stride
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     number of bytes from the beginning of one row to the beginning of the next row
    /// 
    /// ### format
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     buffer pixel format
    /// 
    /// #### Enum
    /// 
    ///     wl_shm.format
    /// 
    /// 
    pub fn create_buffer(self: *const wl_shm_pool, offset: i32, width: i32, height: i32, stride: i32, format: u32) !struct { id: wl_buffer, } {
        const id_id = self.runtime.getId();
        try self.runtime.sendRequest(self.object_id, 0, .{id_id, offset, width, height, stride, format, });
        return .{.id = wl_buffer{.object_id = id_id, .runtime = self.runtime}, };
    }

    /// # destroy
    /// 
    /// ## Summary
    /// 
    ///     destroy the pool
    /// 
    /// ## Description
    /// 
    ///     Destroy the shared memory pool.
    /// 
    ///     The mmapped memory will be released when all
    ///     buffers that have been created from this pool
    ///     are gone.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn destroy(self: *const wl_shm_pool) !void {
        try self.runtime.sendRequest(self.object_id, 1, .{});
    }

    /// # resize
    /// 
    /// ## Summary
    /// 
    ///     change the size of the pool mapping
    /// 
    /// ## Description
    /// 
    ///     This request will cause the server to remap the backing memory
    ///     for the pool from the file descriptor passed when the pool was
    ///     created, but using the new size.  This request can only be
    ///     used to make the pool bigger.
    /// 
    ///     This request only changes the amount of bytes that are mmapped
    ///     by the server and does not touch the file corresponding to the
    ///     file descriptor passed at creation time. It is the client's
    ///     responsibility to ensure that the file is at least as big as
    ///     the new pool size.
    ///       
    /// ## Args 
    /// 
    /// ### size
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     new size of the pool, in bytes
    /// 
    /// 
    pub fn resize(self: *const wl_shm_pool, size: i32) !void {
        try self.runtime.sendRequest(self.object_id, 2, .{size, });
    }
};

/// # wl_shm
/// 
/// ## Summary
/// 
///     shared memory support
/// 
/// ## Description
/// 
///       A singleton global object that provides support for shared
///       memory.
/// 
///       Clients can create wl_shm_pool objects using the create_pool
///       request.
/// 
///       On binding the wl_shm object one or more format events
///       are emitted to inform clients about the valid pixel formats
///       that can be used for buffers.
///     
pub const wl_shm = struct {
    pub const interface = "wl_shm";
    pub const version = 2;

    pub const enums = struct{
        /// # error
        /// 
        /// ## Summary
        /// 
        ///     wl_shm error values
        /// 
        /// ## Description
        /// 
        ///     These errors can be emitted in response to wl_shm requests.
        ///       
        pub const @"error" = enum(u32) {
            invalid_format = 0,
            invalid_stride = 1,
            invalid_fd = 2,
        };

        /// # format
        /// 
        /// ## Summary
        /// 
        ///     pixel formats
        /// 
        /// ## Description
        /// 
        ///     This describes the memory layout of an individual pixel.
        /// 
        ///     All renderers should support argb8888 and xrgb8888 but any other
        ///     formats are optional and may not be supported by the particular
        ///     renderer in use.
        /// 
        ///     The drm format codes match the macros defined in drm_fourcc.h, except
        ///     argb8888 and xrgb8888. The formats actually supported by the compositor
        ///     will be reported by the format event.
        /// 
        ///     For all wl_shm formats and unless specified in another protocol
        ///     extension, pre-multiplied alpha is used for pixel values.
        ///       
        pub const format = enum(u32) {
            argb8888 = 0,
            xrgb8888 = 1,
            c8 = 0x20203843,
            rgb332 = 0x38424752,
            bgr233 = 0x38524742,
            xrgb4444 = 0x32315258,
            xbgr4444 = 0x32314258,
            rgbx4444 = 0x32315852,
            bgrx4444 = 0x32315842,
            argb4444 = 0x32315241,
            abgr4444 = 0x32314241,
            rgba4444 = 0x32314152,
            bgra4444 = 0x32314142,
            xrgb1555 = 0x35315258,
            xbgr1555 = 0x35314258,
            rgbx5551 = 0x35315852,
            bgrx5551 = 0x35315842,
            argb1555 = 0x35315241,
            abgr1555 = 0x35314241,
            rgba5551 = 0x35314152,
            bgra5551 = 0x35314142,
            rgb565 = 0x36314752,
            bgr565 = 0x36314742,
            rgb888 = 0x34324752,
            bgr888 = 0x34324742,
            xbgr8888 = 0x34324258,
            rgbx8888 = 0x34325852,
            bgrx8888 = 0x34325842,
            abgr8888 = 0x34324241,
            rgba8888 = 0x34324152,
            bgra8888 = 0x34324142,
            xrgb2101010 = 0x30335258,
            xbgr2101010 = 0x30334258,
            rgbx1010102 = 0x30335852,
            bgrx1010102 = 0x30335842,
            argb2101010 = 0x30335241,
            abgr2101010 = 0x30334241,
            rgba1010102 = 0x30334152,
            bgra1010102 = 0x30334142,
            yuyv = 0x56595559,
            yvyu = 0x55595659,
            uyvy = 0x59565955,
            vyuy = 0x59555956,
            ayuv = 0x56555941,
            nv12 = 0x3231564e,
            nv21 = 0x3132564e,
            nv16 = 0x3631564e,
            nv61 = 0x3136564e,
            yuv410 = 0x39565559,
            yvu410 = 0x39555659,
            yuv411 = 0x31315559,
            yvu411 = 0x31315659,
            yuv420 = 0x32315559,
            yvu420 = 0x32315659,
            yuv422 = 0x36315559,
            yvu422 = 0x36315659,
            yuv444 = 0x34325559,
            yvu444 = 0x34325659,
            r8 = 0x20203852,
            r16 = 0x20363152,
            rg88 = 0x38384752,
            gr88 = 0x38385247,
            rg1616 = 0x32334752,
            gr1616 = 0x32335247,
            xrgb16161616f = 0x48345258,
            xbgr16161616f = 0x48344258,
            argb16161616f = 0x48345241,
            abgr16161616f = 0x48344241,
            xyuv8888 = 0x56555958,
            vuy888 = 0x34325556,
            vuy101010 = 0x30335556,
            y210 = 0x30313259,
            y212 = 0x32313259,
            y216 = 0x36313259,
            y410 = 0x30313459,
            y412 = 0x32313459,
            y416 = 0x36313459,
            xvyu2101010 = 0x30335658,
            xvyu12_16161616 = 0x36335658,
            xvyu16161616 = 0x38345658,
            y0l0 = 0x304c3059,
            x0l0 = 0x304c3058,
            y0l2 = 0x324c3059,
            x0l2 = 0x324c3058,
            yuv420_8bit = 0x38305559,
            yuv420_10bit = 0x30315559,
            xrgb8888_a8 = 0x38415258,
            xbgr8888_a8 = 0x38414258,
            rgbx8888_a8 = 0x38415852,
            bgrx8888_a8 = 0x38415842,
            rgb888_a8 = 0x38413852,
            bgr888_a8 = 0x38413842,
            rgb565_a8 = 0x38413552,
            bgr565_a8 = 0x38413542,
            nv24 = 0x3432564e,
            nv42 = 0x3234564e,
            p210 = 0x30313250,
            p010 = 0x30313050,
            p012 = 0x32313050,
            p016 = 0x36313050,
            axbxgxrx106106106106 = 0x30314241,
            nv15 = 0x3531564e,
            q410 = 0x30313451,
            q401 = 0x31303451,
            xrgb16161616 = 0x38345258,
            xbgr16161616 = 0x38344258,
            argb16161616 = 0x38345241,
            abgr16161616 = 0x38344241,
            c1 = 0x20203143,
            c2 = 0x20203243,
            c4 = 0x20203443,
            d1 = 0x20203144,
            d2 = 0x20203244,
            d4 = 0x20203444,
            d8 = 0x20203844,
            r1 = 0x20203152,
            r2 = 0x20203252,
            r4 = 0x20203452,
            r10 = 0x20303152,
            r12 = 0x20323152,
            avuy8888 = 0x59555641,
            xvuy8888 = 0x59555658,
            p030 = 0x30333050,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # create_pool
    /// 
    /// ## Summary
    /// 
    ///     create a shm pool
    /// 
    /// ## Description
    /// 
    ///     Create a new wl_shm_pool object.
    /// 
    ///     The pool can be used to create shared memory based buffer
    ///     objects.  The server will mmap size bytes of the passed file
    ///     descriptor, to use as backing memory for the pool.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Summary
    /// 
    ///     pool to create
    /// 
    /// #### Interface
    /// 
    ///     wl_shm_pool
    /// 
    /// ### fd
    /// 
    /// #### Type
    /// 
    ///     fd
    /// 
    /// #### Summary
    /// 
    ///     file descriptor for the pool
    /// 
    /// ### size
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     pool size, in bytes
    /// 
    /// 
    pub fn create_pool(self: *const wl_shm, fd: types.Fd, size: i32) !struct { id: wl_shm_pool, } {
        const id_id = self.runtime.getId();
        try self.runtime.sendRequest(self.object_id, 0, .{id_id, fd, size, });
        return .{.id = wl_shm_pool{.object_id = id_id, .runtime = self.runtime}, };
    }

    /// # release
    /// 
    /// ## Summary
    /// 
    ///     release the shm object
    /// 
    /// ## Description
    /// 
    ///     Using this request a client can tell the server that it is not going to
    ///     use the shm object anymore.
    /// 
    ///     Objects created via this interface remain unaffected.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn release(self: *const wl_shm) !void {
        try self.runtime.sendRequest(self.object_id, 1, .{});
    }

    /// # format
    /// 
    /// ## Summary
    /// 
    ///     pixel format description
    /// 
    /// ## Description
    /// 
    ///     Informs the client about a valid pixel format that
    ///     can be used for buffers. Known formats include
    ///     argb8888 and xrgb8888.
    ///       
    /// ## Args 
    /// 
    /// ### format
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     buffer pixel format
    /// 
    /// #### Enum
    /// 
    ///     format
    /// 
    /// 
    pub fn next_format(self: *const wl_shm) !?struct {format: u32, } {
        return try self.runtime.next(self.object_id, 0, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_format)).@"fn".return_type.?).error_union.payload).optional.child);
}
};

/// # wl_buffer
/// 
/// ## Summary
/// 
///     content for a wl_surface
/// 
/// ## Description
/// 
///       A buffer provides the content for a wl_surface. Buffers are
///       created through factory interfaces such as wl_shm, wp_linux_buffer_params
///       (from the linux-dmabuf protocol extension) or similar. It has a width and
///       a height and can be attached to a wl_surface, but the mechanism by which a
///       client provides and updates the contents is defined by the buffer factory
///       interface.
/// 
///       Color channels are assumed to be electrical rather than optical (in other
///       words, encoded with a transfer function) unless otherwise specified. If
///       the buffer uses a format that has an alpha channel, the alpha channel is
///       assumed to be premultiplied into the electrical color channel values
///       (after transfer function encoding) unless otherwise specified.
/// 
///       Note, because wl_buffer objects are created from multiple independent
///       factory interfaces, the wl_buffer interface is frozen at version 1.
///     
pub const wl_buffer = struct {
    pub const interface = "wl_buffer";
    pub const version = 1;

    pub const enums = struct{    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # destroy
    /// 
    /// ## Summary
    /// 
    ///     destroy a buffer
    /// 
    /// ## Description
    /// 
    ///     Destroy a buffer. If and how you need to release the backing
    ///     storage is defined by the buffer factory interface.
    /// 
    ///     For possible side-effects to a surface, see wl_surface.attach.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn destroy(self: *const wl_buffer) !void {
        try self.runtime.sendRequest(self.object_id, 0, .{});
    }

    /// # release
    /// 
    /// ## Summary
    /// 
    ///     compositor releases buffer
    /// 
    /// ## Description
    /// 
    ///     Sent when this wl_buffer is no longer used by the compositor.
    ///     The client is now free to reuse or destroy this buffer and its
    ///     backing storage.
    /// 
    ///     If a client receives a release event before the frame callback
    ///     requested in the same wl_surface.commit that attaches this
    ///     wl_buffer to a surface, then the client is immediately free to
    ///     reuse the buffer and its backing storage, and does not need a
    ///     second buffer for the next surface content update. Typically
    ///     this is possible, when the compositor maintains a copy of the
    ///     wl_surface contents, e.g. as a GL texture. This is an important
    ///     optimization for GL(ES) compositors with wl_shm clients.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn next_release(self: *const wl_buffer) !?struct {} {
        return try self.runtime.next(self.object_id, 0, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_release)).@"fn".return_type.?).error_union.payload).optional.child);
}
};

/// # wl_data_offer
/// 
/// ## Summary
/// 
///     offer to transfer data
/// 
/// ## Description
/// 
///       A wl_data_offer represents a piece of data offered for transfer
///       by another client (the source client).  It is used by the
///       copy-and-paste and drag-and-drop mechanisms.  The offer
///       describes the different mime types that the data can be
///       converted to and provides the mechanism for transferring the
///       data directly from the source client.
///     
pub const wl_data_offer = struct {
    pub const interface = "wl_data_offer";
    pub const version = 3;

    pub const enums = struct{
        pub const @"error" = enum(u32) {
            invalid_finish = 0,
            invalid_action_mask = 1,
            invalid_action = 2,
            invalid_offer = 3,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # accept
    /// 
    /// ## Summary
    /// 
    ///     accept one of the offered mime types
    /// 
    /// ## Description
    /// 
    ///     Indicate that the client can accept the given mime type, or
    ///     NULL for not accepted.
    /// 
    ///     For objects of version 2 or older, this request is used by the
    ///     client to give feedback whether the client can receive the given
    ///     mime type, or NULL if none is accepted; the feedback does not
    ///     determine whether the drag-and-drop operation succeeds or not.
    /// 
    ///     For objects of version 3 or newer, this request determines the
    ///     final result of the drag-and-drop operation. If the end result
    ///     is that no mime types were accepted, the drag-and-drop operation
    ///     will be cancelled and the corresponding drag source will receive
    ///     wl_data_source.cancelled. Clients may still use this event in
    ///     conjunction with wl_data_source.action for feedback.
    ///       
    /// ## Args 
    /// 
    /// ### serial
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     serial number of the accept request
    /// 
    /// ### mime_type
    /// 
    /// #### Type
    /// 
    ///     string
    /// 
    /// #### Summary
    /// 
    ///     mime type accepted by the client
    /// 
    /// #### Allow Null
    /// 
    ///     true
    /// 
    /// 
    pub fn accept(self: *const wl_data_offer, serial: u32, mime_type: []const u8) !void {
        try self.runtime.sendRequest(self.object_id, 0, .{serial, types.String{.static = mime_type}, });
    }

    /// # receive
    /// 
    /// ## Summary
    /// 
    ///     request that the data is transferred
    /// 
    /// ## Description
    /// 
    ///     To transfer the offered data, the client issues this request
    ///     and indicates the mime type it wants to receive.  The transfer
    ///     happens through the passed file descriptor (typically created
    ///     with the pipe system call).  The source client writes the data
    ///     in the mime type representation requested and then closes the
    ///     file descriptor.
    /// 
    ///     The receiving client reads from the read end of the pipe until
    ///     EOF and then closes its end, at which point the transfer is
    ///     complete.
    /// 
    ///     This request may happen multiple times for different mime types,
    ///     both before and after wl_data_device.drop. Drag-and-drop destination
    ///     clients may preemptively fetch data or examine it more closely to
    ///     determine acceptance.
    ///       
    /// ## Args 
    /// 
    /// ### mime_type
    /// 
    /// #### Type
    /// 
    ///     string
    /// 
    /// #### Summary
    /// 
    ///     mime type desired by receiver
    /// 
    /// ### fd
    /// 
    /// #### Type
    /// 
    ///     fd
    /// 
    /// #### Summary
    /// 
    ///     file descriptor for data transfer
    /// 
    /// 
    pub fn receive(self: *const wl_data_offer, mime_type: []const u8, fd: types.Fd) !void {
        try self.runtime.sendRequest(self.object_id, 1, .{types.String{.static = mime_type}, fd, });
    }

    /// # destroy
    /// 
    /// ## Summary
    /// 
    ///     destroy data offer
    /// 
    /// ## Description
    /// 
    ///     Destroy the data offer.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn destroy(self: *const wl_data_offer) !void {
        try self.runtime.sendRequest(self.object_id, 2, .{});
    }

    /// # finish
    /// 
    /// ## Summary
    /// 
    ///     the offer will no longer be used
    /// 
    /// ## Description
    /// 
    ///     Notifies the compositor that the drag destination successfully
    ///     finished the drag-and-drop operation.
    /// 
    ///     Upon receiving this request, the compositor will emit
    ///     wl_data_source.dnd_finished on the drag source client.
    /// 
    ///     It is a client error to perform other requests than
    ///     wl_data_offer.destroy after this one. It is also an error to perform
    ///     this request after a NULL mime type has been set in
    ///     wl_data_offer.accept or no action was received through
    ///     wl_data_offer.action.
    /// 
    ///     If wl_data_offer.finish request is received for a non drag and drop
    ///     operation, the invalid_finish protocol error is raised.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn finish(self: *const wl_data_offer) !void {
        try self.runtime.sendRequest(self.object_id, 3, .{});
    }

    /// # set_actions
    /// 
    /// ## Summary
    /// 
    ///     set the available/preferred drag-and-drop actions
    /// 
    /// ## Description
    /// 
    ///     Sets the actions that the destination side client supports for
    ///     this operation. This request may trigger the emission of
    ///     wl_data_source.action and wl_data_offer.action events if the compositor
    ///     needs to change the selected action.
    /// 
    ///     This request can be called multiple times throughout the
    ///     drag-and-drop operation, typically in response to wl_data_device.enter
    ///     or wl_data_device.motion events.
    /// 
    ///     This request determines the final result of the drag-and-drop
    ///     operation. If the end result is that no action is accepted,
    ///     the drag source will receive wl_data_source.cancelled.
    /// 
    ///     The dnd_actions argument must contain only values expressed in the
    ///     wl_data_device_manager.dnd_actions enum, and the preferred_action
    ///     argument must only contain one of those values set, otherwise it
    ///     will result in a protocol error.
    /// 
    ///     While managing an "ask" action, the destination drag-and-drop client
    ///     may perform further wl_data_offer.receive requests, and is expected
    ///     to perform one last wl_data_offer.set_actions request with a preferred
    ///     action other than "ask" (and optionally wl_data_offer.accept) before
    ///     requesting wl_data_offer.finish, in order to convey the action selected
    ///     by the user. If the preferred action is not in the
    ///     wl_data_offer.source_actions mask, an error will be raised.
    /// 
    ///     If the "ask" action is dismissed (e.g. user cancellation), the client
    ///     is expected to perform wl_data_offer.destroy right away.
    /// 
    ///     This request can only be made on drag-and-drop offers, a protocol error
    ///     will be raised otherwise.
    ///       
    /// ## Args 
    /// 
    /// ### dnd_actions
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     actions supported by the destination client
    /// 
    /// #### Enum
    /// 
    ///     wl_data_device_manager.dnd_action
    /// 
    /// ### preferred_action
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     action preferred by the destination client
    /// 
    /// #### Enum
    /// 
    ///     wl_data_device_manager.dnd_action
    /// 
    /// 
    pub fn set_actions(self: *const wl_data_offer, dnd_actions: u32, preferred_action: u32) !void {
        try self.runtime.sendRequest(self.object_id, 4, .{dnd_actions, preferred_action, });
    }

    /// # offer
    /// 
    /// ## Summary
    /// 
    ///     advertise offered mime type
    /// 
    /// ## Description
    /// 
    ///     Sent immediately after creating the wl_data_offer object.  One
    ///     event per offered mime type.
    ///       
    /// ## Args 
    /// 
    /// ### mime_type
    /// 
    /// #### Type
    /// 
    ///     string
    /// 
    /// #### Summary
    /// 
    ///     offered mime type
    /// 
    /// 
    pub fn next_offer(self: *const wl_data_offer) !?struct {mime_type: types.String, } {
        return try self.runtime.next(self.object_id, 0, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_offer)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # source_actions
    /// 
    /// ## Summary
    /// 
    ///     notify the source-side available actions
    /// 
    /// ## Description
    /// 
    ///     This event indicates the actions offered by the data source. It
    ///     will be sent immediately after creating the wl_data_offer object,
    ///     or anytime the source side changes its offered actions through
    ///     wl_data_source.set_actions.
    ///       
    /// ## Args 
    /// 
    /// ### source_actions
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     actions offered by the data source
    /// 
    /// #### Enum
    /// 
    ///     wl_data_device_manager.dnd_action
    /// 
    /// 
    pub fn next_source_actions(self: *const wl_data_offer) !?struct {source_actions: u32, } {
        return try self.runtime.next(self.object_id, 1, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_source_actions)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # action
    /// 
    /// ## Summary
    /// 
    ///     notify the selected action
    /// 
    /// ## Description
    /// 
    ///     This event indicates the action selected by the compositor after
    ///     matching the source/destination side actions. Only one action (or
    ///     none) will be offered here.
    /// 
    ///     This event can be emitted multiple times during the drag-and-drop
    ///     operation in response to destination side action changes through
    ///     wl_data_offer.set_actions.
    /// 
    ///     This event will no longer be emitted after wl_data_device.drop
    ///     happened on the drag-and-drop destination, the client must
    ///     honor the last action received, or the last preferred one set
    ///     through wl_data_offer.set_actions when handling an "ask" action.
    /// 
    ///     Compositors may also change the selected action on the fly, mainly
    ///     in response to keyboard modifier changes during the drag-and-drop
    ///     operation.
    /// 
    ///     The most recent action received is always the valid one. Prior to
    ///     receiving wl_data_device.drop, the chosen action may change (e.g.
    ///     due to keyboard modifiers being pressed). At the time of receiving
    ///     wl_data_device.drop the drag-and-drop destination must honor the
    ///     last action received.
    /// 
    ///     Action changes may still happen after wl_data_device.drop,
    ///     especially on "ask" actions, where the drag-and-drop destination
    ///     may choose another action afterwards. Action changes happening
    ///     at this stage are always the result of inter-client negotiation, the
    ///     compositor shall no longer be able to induce a different action.
    /// 
    ///     Upon "ask" actions, it is expected that the drag-and-drop destination
    ///     may potentially choose a different action and/or mime type,
    ///     based on wl_data_offer.source_actions and finally chosen by the
    ///     user (e.g. popping up a menu with the available options). The
    ///     final wl_data_offer.set_actions and wl_data_offer.accept requests
    ///     must happen before the call to wl_data_offer.finish.
    ///       
    /// ## Args 
    /// 
    /// ### dnd_action
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     action selected by the compositor
    /// 
    /// #### Enum
    /// 
    ///     wl_data_device_manager.dnd_action
    /// 
    /// 
    pub fn next_action(self: *const wl_data_offer) !?struct {dnd_action: u32, } {
        return try self.runtime.next(self.object_id, 2, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_action)).@"fn".return_type.?).error_union.payload).optional.child);
}
};

/// # wl_data_source
/// 
/// ## Summary
/// 
///     offer to transfer data
/// 
/// ## Description
/// 
///       The wl_data_source object is the source side of a wl_data_offer.
///       It is created by the source client in a data transfer and
///       provides a way to describe the offered data and a way to respond
///       to requests to transfer the data.
///     
pub const wl_data_source = struct {
    pub const interface = "wl_data_source";
    pub const version = 3;

    pub const enums = struct{
        pub const @"error" = enum(u32) {
            invalid_action_mask = 0,
            invalid_source = 1,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # offer
    /// 
    /// ## Summary
    /// 
    ///     add an offered mime type
    /// 
    /// ## Description
    /// 
    ///     This request adds a mime type to the set of mime types
    ///     advertised to targets.  Can be called several times to offer
    ///     multiple types.
    ///       
    /// ## Args 
    /// 
    /// ### mime_type
    /// 
    /// #### Type
    /// 
    ///     string
    /// 
    /// #### Summary
    /// 
    ///     mime type offered by the data source
    /// 
    /// 
    pub fn offer(self: *const wl_data_source, mime_type: []const u8) !void {
        try self.runtime.sendRequest(self.object_id, 0, .{types.String{.static = mime_type}, });
    }

    /// # destroy
    /// 
    /// ## Summary
    /// 
    ///     destroy the data source
    /// 
    /// ## Description
    /// 
    ///     Destroy the data source.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn destroy(self: *const wl_data_source) !void {
        try self.runtime.sendRequest(self.object_id, 1, .{});
    }

    /// # set_actions
    /// 
    /// ## Summary
    /// 
    ///     set the available drag-and-drop actions
    /// 
    /// ## Description
    /// 
    ///     Sets the actions that the source side client supports for this
    ///     operation. This request may trigger wl_data_source.action and
    ///     wl_data_offer.action events if the compositor needs to change the
    ///     selected action.
    /// 
    ///     The dnd_actions argument must contain only values expressed in the
    ///     wl_data_device_manager.dnd_actions enum, otherwise it will result
    ///     in a protocol error.
    /// 
    ///     This request must be made once only, and can only be made on sources
    ///     used in drag-and-drop, so it must be performed before
    ///     wl_data_device.start_drag. Attempting to use the source other than
    ///     for drag-and-drop will raise a protocol error.
    ///       
    /// ## Args 
    /// 
    /// ### dnd_actions
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     actions supported by the data source
    /// 
    /// #### Enum
    /// 
    ///     wl_data_device_manager.dnd_action
    /// 
    /// 
    pub fn set_actions(self: *const wl_data_source, dnd_actions: u32) !void {
        try self.runtime.sendRequest(self.object_id, 2, .{dnd_actions, });
    }

    /// # target
    /// 
    /// ## Summary
    /// 
    ///     a target accepts an offered mime type
    /// 
    /// ## Description
    /// 
    ///     Sent when a target accepts pointer_focus or motion events.  If
    ///     a target does not accept any of the offered types, type is NULL.
    /// 
    ///     Used for feedback during drag-and-drop.
    ///       
    /// ## Args 
    /// 
    /// ### mime_type
    /// 
    /// #### Type
    /// 
    ///     string
    /// 
    /// #### Summary
    /// 
    ///     mime type accepted by the target
    /// 
    /// #### Allow Null
    /// 
    ///     true
    /// 
    /// 
    pub fn next_target(self: *const wl_data_source) !?struct {mime_type: types.String, } {
        return try self.runtime.next(self.object_id, 0, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_target)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # send
    /// 
    /// ## Summary
    /// 
    ///     send the data
    /// 
    /// ## Description
    /// 
    ///     Request for data from the client.  Send the data as the
    ///     specified mime type over the passed file descriptor, then
    ///     close it.
    ///       
    /// ## Args 
    /// 
    /// ### mime_type
    /// 
    /// #### Type
    /// 
    ///     string
    /// 
    /// #### Summary
    /// 
    ///     mime type for the data
    /// 
    /// ### fd
    /// 
    /// #### Type
    /// 
    ///     fd
    /// 
    /// #### Summary
    /// 
    ///     file descriptor for the data
    /// 
    /// 
    pub fn next_send(self: *const wl_data_source) !?struct {mime_type: types.String, fd: types.Fd, } {
        return try self.runtime.next(self.object_id, 1, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_send)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # cancelled
    /// 
    /// ## Summary
    /// 
    ///     selection was cancelled
    /// 
    /// ## Description
    /// 
    ///     This data source is no longer valid. There are several reasons why
    ///     this could happen:
    /// 
    ///     - The data source has been replaced by another data source.
    ///     - The drag-and-drop operation was performed, but the drop destination
    ///       did not accept any of the mime types offered through
    ///       wl_data_source.target.
    ///     - The drag-and-drop operation was performed, but the drop destination
    ///       did not select any of the actions present in the mask offered through
    ///       wl_data_source.action.
    ///     - The drag-and-drop operation was performed but didn't happen over a
    ///       surface.
    ///     - The compositor cancelled the drag-and-drop operation (e.g. compositor
    ///       dependent timeouts to avoid stale drag-and-drop transfers).
    /// 
    ///     The client should clean up and destroy this data source.
    /// 
    ///     For objects of version 2 or older, wl_data_source.cancelled will
    ///     only be emitted if the data source was replaced by another data
    ///     source.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn next_cancelled(self: *const wl_data_source) !?struct {} {
        return try self.runtime.next(self.object_id, 2, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_cancelled)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # dnd_drop_performed
    /// 
    /// ## Summary
    /// 
    ///     the drag-and-drop operation physically finished
    /// 
    /// ## Description
    /// 
    ///     The user performed the drop action. This event does not indicate
    ///     acceptance, wl_data_source.cancelled may still be emitted afterwards
    ///     if the drop destination does not accept any mime type.
    /// 
    ///     However, this event might however not be received if the compositor
    ///     cancelled the drag-and-drop operation before this event could happen.
    /// 
    ///     Note that the data_source may still be used in the future and should
    ///     not be destroyed here.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn next_dnd_drop_performed(self: *const wl_data_source) !?struct {} {
        return try self.runtime.next(self.object_id, 3, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_dnd_drop_performed)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # dnd_finished
    /// 
    /// ## Summary
    /// 
    ///     the drag-and-drop operation concluded
    /// 
    /// ## Description
    /// 
    ///     The drop destination finished interoperating with this data
    ///     source, so the client is now free to destroy this data source and
    ///     free all associated data.
    /// 
    ///     If the action used to perform the operation was "move", the
    ///     source can now delete the transferred data.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn next_dnd_finished(self: *const wl_data_source) !?struct {} {
        return try self.runtime.next(self.object_id, 4, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_dnd_finished)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # action
    /// 
    /// ## Summary
    /// 
    ///     notify the selected action
    /// 
    /// ## Description
    /// 
    ///     This event indicates the action selected by the compositor after
    ///     matching the source/destination side actions. Only one action (or
    ///     none) will be offered here.
    /// 
    ///     This event can be emitted multiple times during the drag-and-drop
    ///     operation, mainly in response to destination side changes through
    ///     wl_data_offer.set_actions, and as the data device enters/leaves
    ///     surfaces.
    /// 
    ///     It is only possible to receive this event after
    ///     wl_data_source.dnd_drop_performed if the drag-and-drop operation
    ///     ended in an "ask" action, in which case the final wl_data_source.action
    ///     event will happen immediately before wl_data_source.dnd_finished.
    /// 
    ///     Compositors may also change the selected action on the fly, mainly
    ///     in response to keyboard modifier changes during the drag-and-drop
    ///     operation.
    /// 
    ///     The most recent action received is always the valid one. The chosen
    ///     action may change alongside negotiation (e.g. an "ask" action can turn
    ///     into a "move" operation), so the effects of the final action must
    ///     always be applied in wl_data_offer.dnd_finished.
    /// 
    ///     Clients can trigger cursor surface changes from this point, so
    ///     they reflect the current action.
    ///       
    /// ## Args 
    /// 
    /// ### dnd_action
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     action selected by the compositor
    /// 
    /// #### Enum
    /// 
    ///     wl_data_device_manager.dnd_action
    /// 
    /// 
    pub fn next_action(self: *const wl_data_source) !?struct {dnd_action: u32, } {
        return try self.runtime.next(self.object_id, 5, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_action)).@"fn".return_type.?).error_union.payload).optional.child);
}
};

/// # wl_data_device
/// 
/// ## Summary
/// 
///     data transfer device
/// 
/// ## Description
/// 
///       There is one wl_data_device per seat which can be obtained
///       from the global wl_data_device_manager singleton.
/// 
///       A wl_data_device provides access to inter-client data transfer
///       mechanisms such as copy-and-paste and drag-and-drop.
///     
pub const wl_data_device = struct {
    pub const interface = "wl_data_device";
    pub const version = 3;

    pub const enums = struct{
        pub const @"error" = enum(u32) {
            role = 0,
            used_source = 1,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # start_drag
    /// 
    /// ## Summary
    /// 
    ///     start drag-and-drop operation
    /// 
    /// ## Description
    /// 
    ///     This request asks the compositor to start a drag-and-drop
    ///     operation on behalf of the client.
    /// 
    ///     The source argument is the data source that provides the data
    ///     for the eventual data transfer. If source is NULL, enter, leave
    ///     and motion events are sent only to the client that initiated the
    ///     drag and the client is expected to handle the data passing
    ///     internally. If source is destroyed, the drag-and-drop session will be
    ///     cancelled.
    /// 
    ///     The origin surface is the surface where the drag originates and
    ///     the client must have an active implicit grab that matches the
    ///     serial.
    /// 
    ///     The icon surface is an optional (can be NULL) surface that
    ///     provides an icon to be moved around with the cursor.  Initially,
    ///     the top-left corner of the icon surface is placed at the cursor
    ///     hotspot, but subsequent wl_surface.offset requests can move the
    ///     relative position. Attach requests must be confirmed with
    ///     wl_surface.commit as usual. The icon surface is given the role of
    ///     a drag-and-drop icon. If the icon surface already has another role,
    ///     it raises a protocol error.
    /// 
    ///     The input region is ignored for wl_surfaces with the role of a
    ///     drag-and-drop icon.
    /// 
    ///     The given source may not be used in any further set_selection or
    ///     start_drag requests. Attempting to reuse a previously-used source
    ///     may send a used_source error.
    ///       
    /// ## Args 
    /// 
    /// ### source
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     data source for the eventual transfer
    /// 
    /// #### Interface
    /// 
    ///     wl_data_source
    /// 
    /// #### Allow Null
    /// 
    ///     true
    /// 
    /// ### origin
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     surface where the drag originates
    /// 
    /// #### Interface
    /// 
    ///     wl_surface
    /// 
    /// ### icon
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     drag-and-drop icon surface
    /// 
    /// #### Interface
    /// 
    ///     wl_surface
    /// 
    /// #### Allow Null
    /// 
    ///     true
    /// 
    /// ### serial
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     serial number of the implicit grab on the origin
    /// 
    /// 
    pub fn start_drag(self: *const wl_data_device, source: types.ObjectId, origin: types.ObjectId, icon: types.ObjectId, serial: u32) !void {
        try self.runtime.sendRequest(self.object_id, 0, .{source, origin, icon, serial, });
    }

    /// # set_selection
    /// 
    /// ## Summary
    /// 
    ///     copy data to the selection
    /// 
    /// ## Description
    /// 
    ///     This request asks the compositor to set the selection
    ///     to the data from the source on behalf of the client.
    /// 
    ///     To unset the selection, set the source to NULL.
    /// 
    ///     The given source may not be used in any further set_selection or
    ///     start_drag requests. Attempting to reuse a previously-used source
    ///     may send a used_source error.
    ///       
    /// ## Args 
    /// 
    /// ### source
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     data source for the selection
    /// 
    /// #### Interface
    /// 
    ///     wl_data_source
    /// 
    /// #### Allow Null
    /// 
    ///     true
    /// 
    /// ### serial
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     serial number of the event that triggered this request
    /// 
    /// 
    pub fn set_selection(self: *const wl_data_device, source: types.ObjectId, serial: u32) !void {
        try self.runtime.sendRequest(self.object_id, 1, .{source, serial, });
    }

    /// # release
    /// 
    /// ## Summary
    /// 
    ///     destroy data device
    /// 
    /// ## Description
    /// 
    ///     This request destroys the data device.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn release(self: *const wl_data_device) !void {
        try self.runtime.sendRequest(self.object_id, 2, .{});
    }

    /// # data_offer
    /// 
    /// ## Summary
    /// 
    ///     introduce a new wl_data_offer
    /// 
    /// ## Description
    /// 
    ///     The data_offer event introduces a new wl_data_offer object,
    ///     which will subsequently be used in either the
    ///     data_device.enter event (for drag-and-drop) or the
    ///     data_device.selection event (for selections).  Immediately
    ///     following the data_device.data_offer event, the new data_offer
    ///     object will send out data_offer.offer events to describe the
    ///     mime types it offers.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Summary
    /// 
    ///     the new data_offer object
    /// 
    /// #### Interface
    /// 
    ///     wl_data_offer
    /// 
    /// 
    pub fn next_data_offer(self: *const wl_data_device) !?struct {id: types.ObjectId, } {
        return try self.runtime.next(self.object_id, 0, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_data_offer)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # enter
    /// 
    /// ## Summary
    /// 
    ///     initiate drag-and-drop session
    /// 
    /// ## Description
    /// 
    ///     This event is sent when an active drag-and-drop pointer enters
    ///     a surface owned by the client.  The position of the pointer at
    ///     enter time is provided by the x and y arguments, in surface-local
    ///     coordinates.
    ///       
    /// ## Args 
    /// 
    /// ### serial
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     serial number of the enter event
    /// 
    /// ### surface
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     client surface entered
    /// 
    /// #### Interface
    /// 
    ///     wl_surface
    /// 
    /// ### x
    /// 
    /// #### Type
    /// 
    ///     fixed
    /// 
    /// #### Summary
    /// 
    ///     surface-local x coordinate
    /// 
    /// ### y
    /// 
    /// #### Type
    /// 
    ///     fixed
    /// 
    /// #### Summary
    /// 
    ///     surface-local y coordinate
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     source data_offer object
    /// 
    /// #### Interface
    /// 
    ///     wl_data_offer
    /// 
    /// #### Allow Null
    /// 
    ///     true
    /// 
    /// 
    pub fn next_enter(self: *const wl_data_device) !?struct {serial: u32, surface: types.ObjectId, x: types.Fixed, y: types.Fixed, id: types.ObjectId, } {
        return try self.runtime.next(self.object_id, 1, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_enter)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # leave
    /// 
    /// ## Summary
    /// 
    ///     end drag-and-drop session
    /// 
    /// ## Description
    /// 
    ///     This event is sent when the drag-and-drop pointer leaves the
    ///     surface and the session ends.  The client must destroy the
    ///     wl_data_offer introduced at enter time at this point.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn next_leave(self: *const wl_data_device) !?struct {} {
        return try self.runtime.next(self.object_id, 2, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_leave)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # motion
    /// 
    /// ## Summary
    /// 
    ///     drag-and-drop session motion
    /// 
    /// ## Description
    /// 
    ///     This event is sent when the drag-and-drop pointer moves within
    ///     the currently focused surface. The new position of the pointer
    ///     is provided by the x and y arguments, in surface-local
    ///     coordinates.
    ///       
    /// ## Args 
    /// 
    /// ### time
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     timestamp with millisecond granularity
    /// 
    /// ### x
    /// 
    /// #### Type
    /// 
    ///     fixed
    /// 
    /// #### Summary
    /// 
    ///     surface-local x coordinate
    /// 
    /// ### y
    /// 
    /// #### Type
    /// 
    ///     fixed
    /// 
    /// #### Summary
    /// 
    ///     surface-local y coordinate
    /// 
    /// 
    pub fn next_motion(self: *const wl_data_device) !?struct {time: u32, x: types.Fixed, y: types.Fixed, } {
        return try self.runtime.next(self.object_id, 3, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_motion)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # drop
    /// 
    /// ## Summary
    /// 
    ///     end drag-and-drop session successfully
    /// 
    /// ## Description
    /// 
    ///     The event is sent when a drag-and-drop operation is ended
    ///     because the implicit grab is removed.
    /// 
    ///     The drag-and-drop destination is expected to honor the last action
    ///     received through wl_data_offer.action, if the resulting action is
    ///     "copy" or "move", the destination can still perform
    ///     wl_data_offer.receive requests, and is expected to end all
    ///     transfers with a wl_data_offer.finish request.
    /// 
    ///     If the resulting action is "ask", the action will not be considered
    ///     final. The drag-and-drop destination is expected to perform one last
    ///     wl_data_offer.set_actions request, or wl_data_offer.destroy in order
    ///     to cancel the operation.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn next_drop(self: *const wl_data_device) !?struct {} {
        return try self.runtime.next(self.object_id, 4, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_drop)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # selection
    /// 
    /// ## Summary
    /// 
    ///     advertise new selection
    /// 
    /// ## Description
    /// 
    ///     The selection event is sent out to notify the client of a new
    ///     wl_data_offer for the selection for this device.  The
    ///     data_device.data_offer and the data_offer.offer events are
    ///     sent out immediately before this event to introduce the data
    ///     offer object.  The selection event is sent to a client
    ///     immediately before receiving keyboard focus and when a new
    ///     selection is set while the client has keyboard focus.  The
    ///     data_offer is valid until a new data_offer or NULL is received
    ///     or until the client loses keyboard focus.  Switching surface with
    ///     keyboard focus within the same client doesn't mean a new selection
    ///     will be sent.  The client must destroy the previous selection
    ///     data_offer, if any, upon receiving this event.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     selection data_offer object
    /// 
    /// #### Interface
    /// 
    ///     wl_data_offer
    /// 
    /// #### Allow Null
    /// 
    ///     true
    /// 
    /// 
    pub fn next_selection(self: *const wl_data_device) !?struct {id: types.ObjectId, } {
        return try self.runtime.next(self.object_id, 5, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_selection)).@"fn".return_type.?).error_union.payload).optional.child);
}
};

/// # wl_data_device_manager
/// 
/// ## Summary
/// 
///     data transfer interface
/// 
/// ## Description
/// 
///       The wl_data_device_manager is a singleton global object that
///       provides access to inter-client data transfer mechanisms such as
///       copy-and-paste and drag-and-drop.  These mechanisms are tied to
///       a wl_seat and this interface lets a client get a wl_data_device
///       corresponding to a wl_seat.
/// 
///       Depending on the version bound, the objects created from the bound
///       wl_data_device_manager object will have different requirements for
///       functioning properly. See wl_data_source.set_actions,
///       wl_data_offer.accept and wl_data_offer.finish for details.
///     
pub const wl_data_device_manager = struct {
    pub const interface = "wl_data_device_manager";
    pub const version = 3;

    pub const enums = struct{
        /// # dnd_action
        /// 
        /// ## Summary
        /// 
        ///     drag and drop actions
        /// 
        /// ## Description
        /// 
        ///     This is a bitmask of the available/preferred actions in a
        ///     drag-and-drop operation.
        /// 
        ///     In the compositor, the selected action is a result of matching the
        ///     actions offered by the source and destination sides.  "action" events
        ///     with a "none" action will be sent to both source and destination if
        ///     there is no match. All further checks will effectively happen on
        ///     (source actions ∩ destination actions).
        /// 
        ///     In addition, compositors may also pick different actions in
        ///     reaction to key modifiers being pressed. One common design that
        ///     is used in major toolkits (and the behavior recommended for
        ///     compositors) is:
        /// 
        ///     - If no modifiers are pressed, the first match (in bit order)
        ///       will be used.
        ///     - Pressing Shift selects "move", if enabled in the mask.
        ///     - Pressing Control selects "copy", if enabled in the mask.
        /// 
        ///     Behavior beyond that is considered implementation-dependent.
        ///     Compositors may for example bind other modifiers (like Alt/Meta)
        ///     or drags initiated with other buttons than BTN_LEFT to specific
        ///     actions (e.g. "ask").
        ///       
        pub const dnd_action = enum(u32) {
            none = 0,
            copy = 1,
            move = 2,
            ask = 4,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # create_data_source
    /// 
    /// ## Summary
    /// 
    ///     create a new data source
    /// 
    /// ## Description
    /// 
    ///     Create a new data source.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Summary
    /// 
    ///     data source to create
    /// 
    /// #### Interface
    /// 
    ///     wl_data_source
    /// 
    /// 
    pub fn create_data_source(self: *const wl_data_device_manager) !struct { id: wl_data_source, } {
        const id_id = self.runtime.getId();
        try self.runtime.sendRequest(self.object_id, 0, .{id_id, });
        return .{.id = wl_data_source{.object_id = id_id, .runtime = self.runtime}, };
    }

    /// # get_data_device
    /// 
    /// ## Summary
    /// 
    ///     create a new data device
    /// 
    /// ## Description
    /// 
    ///     Create a new data device for a given seat.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Summary
    /// 
    ///     data device to create
    /// 
    /// #### Interface
    /// 
    ///     wl_data_device
    /// 
    /// ### seat
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     seat associated with the data device
    /// 
    /// #### Interface
    /// 
    ///     wl_seat
    /// 
    /// 
    pub fn get_data_device(self: *const wl_data_device_manager, seat: types.ObjectId) !struct { id: wl_data_device, } {
        const id_id = self.runtime.getId();
        try self.runtime.sendRequest(self.object_id, 1, .{id_id, seat, });
        return .{.id = wl_data_device{.object_id = id_id, .runtime = self.runtime}, };
    }
};

/// # wl_shell
/// 
/// ## Summary
/// 
///     create desktop-style surfaces
/// 
/// ## Description
/// 
///       This interface is implemented by servers that provide
///       desktop-style user interfaces.
/// 
///       It allows clients to associate a wl_shell_surface with
///       a basic surface.
/// 
///       Note! This protocol is deprecated and not intended for production use.
///       For desktop-style user interfaces, use xdg_shell. Compositors and clients
///       should not implement this interface.
///     
pub const wl_shell = struct {
    pub const interface = "wl_shell";
    pub const version = 1;

    pub const enums = struct{
        pub const @"error" = enum(u32) {
            role = 0,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # get_shell_surface
    /// 
    /// ## Summary
    /// 
    ///     create a shell surface from a surface
    /// 
    /// ## Description
    /// 
    ///     Create a shell surface for an existing surface. This gives
    ///     the wl_surface the role of a shell surface. If the wl_surface
    ///     already has another role, it raises a protocol error.
    /// 
    ///     Only one shell surface can be associated with a given surface.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Summary
    /// 
    ///     shell surface to create
    /// 
    /// #### Interface
    /// 
    ///     wl_shell_surface
    /// 
    /// ### surface
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     surface to be given the shell surface role
    /// 
    /// #### Interface
    /// 
    ///     wl_surface
    /// 
    /// 
    pub fn get_shell_surface(self: *const wl_shell, surface: types.ObjectId) !struct { id: wl_shell_surface, } {
        const id_id = self.runtime.getId();
        try self.runtime.sendRequest(self.object_id, 0, .{id_id, surface, });
        return .{.id = wl_shell_surface{.object_id = id_id, .runtime = self.runtime}, };
    }
};

/// # wl_shell_surface
/// 
/// ## Summary
/// 
///     desktop-style metadata interface
/// 
/// ## Description
/// 
///       An interface that may be implemented by a wl_surface, for
///       implementations that provide a desktop-style user interface.
/// 
///       It provides requests to treat surfaces like toplevel, fullscreen
///       or popup windows, move, resize or maximize them, associate
///       metadata like title and class, etc.
/// 
///       On the server side the object is automatically destroyed when
///       the related wl_surface is destroyed. On the client side,
///       wl_shell_surface_destroy() must be called before destroying
///       the wl_surface object.
///     
pub const wl_shell_surface = struct {
    pub const interface = "wl_shell_surface";
    pub const version = 1;

    pub const enums = struct{
        /// # resize
        /// 
        /// ## Summary
        /// 
        ///     edge values for resizing
        /// 
        /// ## Description
        /// 
        ///     These values are used to indicate which edge of a surface
        ///     is being dragged in a resize operation. The server may
        ///     use this information to adapt its behavior, e.g. choose
        ///     an appropriate cursor image.
        ///       
        pub const resize = enum(u32) {
            none = 0,
            top = 1,
            bottom = 2,
            left = 4,
            top_left = 5,
            bottom_left = 6,
            right = 8,
            top_right = 9,
            bottom_right = 10,
        };

        /// # transient
        /// 
        /// ## Summary
        /// 
        ///     details of transient behaviour
        /// 
        /// ## Description
        /// 
        ///     These flags specify details of the expected behaviour
        ///     of transient surfaces. Used in the set_transient request.
        ///       
        pub const transient = enum(u32) {
            inactive = 0x1,
        };

        /// # fullscreen_method
        /// 
        /// ## Summary
        /// 
        ///     different method to set the surface fullscreen
        /// 
        /// ## Description
        /// 
        ///     Hints to indicate to the compositor how to deal with a conflict
        ///     between the dimensions of the surface and the dimensions of the
        ///     output. The compositor is free to ignore this parameter.
        ///       
        pub const fullscreen_method = enum(u32) {
            default = 0,
            scale = 1,
            driver = 2,
            fill = 3,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # pong
    /// 
    /// ## Summary
    /// 
    ///     respond to a ping event
    /// 
    /// ## Description
    /// 
    ///     A client must respond to a ping event with a pong request or
    ///     the client may be deemed unresponsive.
    ///       
    /// ## Args 
    /// 
    /// ### serial
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     serial number of the ping event
    /// 
    /// 
    pub fn pong(self: *const wl_shell_surface, serial: u32) !void {
        try self.runtime.sendRequest(self.object_id, 0, .{serial, });
    }

    /// # move
    /// 
    /// ## Summary
    /// 
    ///     start an interactive move
    /// 
    /// ## Description
    /// 
    ///     Start a pointer-driven move of the surface.
    /// 
    ///     This request must be used in response to a button press event.
    ///     The server may ignore move requests depending on the state of
    ///     the surface (e.g. fullscreen or maximized).
    ///       
    /// ## Args 
    /// 
    /// ### seat
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     seat whose pointer is used
    /// 
    /// #### Interface
    /// 
    ///     wl_seat
    /// 
    /// ### serial
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     serial number of the implicit grab on the pointer
    /// 
    /// 
    pub fn move(self: *const wl_shell_surface, seat: types.ObjectId, serial: u32) !void {
        try self.runtime.sendRequest(self.object_id, 1, .{seat, serial, });
    }

    /// # resize
    /// 
    /// ## Summary
    /// 
    ///     start an interactive resize
    /// 
    /// ## Description
    /// 
    ///     Start a pointer-driven resizing of the surface.
    /// 
    ///     This request must be used in response to a button press event.
    ///     The server may ignore resize requests depending on the state of
    ///     the surface (e.g. fullscreen or maximized).
    ///       
    /// ## Args 
    /// 
    /// ### seat
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     seat whose pointer is used
    /// 
    /// #### Interface
    /// 
    ///     wl_seat
    /// 
    /// ### serial
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     serial number of the implicit grab on the pointer
    /// 
    /// ### edges
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     which edge or corner is being dragged
    /// 
    /// #### Enum
    /// 
    ///     resize
    /// 
    /// 
    pub fn resize(self: *const wl_shell_surface, seat: types.ObjectId, serial: u32, edges: u32) !void {
        try self.runtime.sendRequest(self.object_id, 2, .{seat, serial, edges, });
    }

    /// # set_toplevel
    /// 
    /// ## Summary
    /// 
    ///     make the surface a toplevel surface
    /// 
    /// ## Description
    /// 
    ///     Map the surface as a toplevel surface.
    /// 
    ///     A toplevel surface is not fullscreen, maximized or transient.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn set_toplevel(self: *const wl_shell_surface) !void {
        try self.runtime.sendRequest(self.object_id, 3, .{});
    }

    /// # set_transient
    /// 
    /// ## Summary
    /// 
    ///     make the surface a transient surface
    /// 
    /// ## Description
    /// 
    ///     Map the surface relative to an existing surface.
    /// 
    ///     The x and y arguments specify the location of the upper left
    ///     corner of the surface relative to the upper left corner of the
    ///     parent surface, in surface-local coordinates.
    /// 
    ///     The flags argument controls details of the transient behaviour.
    ///       
    /// ## Args 
    /// 
    /// ### parent
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     parent surface
    /// 
    /// #### Interface
    /// 
    ///     wl_surface
    /// 
    /// ### x
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     surface-local x coordinate
    /// 
    /// ### y
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     surface-local y coordinate
    /// 
    /// ### flags
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     transient surface behavior
    /// 
    /// #### Enum
    /// 
    ///     transient
    /// 
    /// 
    pub fn set_transient(self: *const wl_shell_surface, parent: types.ObjectId, x: i32, y: i32, flags: u32) !void {
        try self.runtime.sendRequest(self.object_id, 4, .{parent, x, y, flags, });
    }

    /// # set_fullscreen
    /// 
    /// ## Summary
    /// 
    ///     make the surface a fullscreen surface
    /// 
    /// ## Description
    /// 
    ///     Map the surface as a fullscreen surface.
    /// 
    ///     If an output parameter is given then the surface will be made
    ///     fullscreen on that output. If the client does not specify the
    ///     output then the compositor will apply its policy - usually
    ///     choosing the output on which the surface has the biggest surface
    ///     area.
    /// 
    ///     The client may specify a method to resolve a size conflict
    ///     between the output size and the surface size - this is provided
    ///     through the method parameter.
    /// 
    ///     The framerate parameter is used only when the method is set
    ///     to "driver", to indicate the preferred framerate. A value of 0
    ///     indicates that the client does not care about framerate.  The
    ///     framerate is specified in mHz, that is framerate of 60000 is 60Hz.
    /// 
    ///     A method of "scale" or "driver" implies a scaling operation of
    ///     the surface, either via a direct scaling operation or a change of
    ///     the output mode. This will override any kind of output scaling, so
    ///     that mapping a surface with a buffer size equal to the mode can
    ///     fill the screen independent of buffer_scale.
    /// 
    ///     A method of "fill" means we don't scale up the buffer, however
    ///     any output scale is applied. This means that you may run into
    ///     an edge case where the application maps a buffer with the same
    ///     size of the output mode but buffer_scale 1 (thus making a
    ///     surface larger than the output). In this case it is allowed to
    ///     downscale the results to fit the screen.
    /// 
    ///     The compositor must reply to this request with a configure event
    ///     with the dimensions for the output on which the surface will
    ///     be made fullscreen.
    ///       
    /// ## Args 
    /// 
    /// ### method
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     method for resolving size conflict
    /// 
    /// #### Enum
    /// 
    ///     fullscreen_method
    /// 
    /// ### framerate
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     framerate in mHz
    /// 
    /// ### output
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     output on which the surface is to be fullscreen
    /// 
    /// #### Interface
    /// 
    ///     wl_output
    /// 
    /// #### Allow Null
    /// 
    ///     true
    /// 
    /// 
    pub fn set_fullscreen(self: *const wl_shell_surface, method: u32, framerate: u32, output: types.ObjectId) !void {
        try self.runtime.sendRequest(self.object_id, 5, .{method, framerate, output, });
    }

    /// # set_popup
    /// 
    /// ## Summary
    /// 
    ///     make the surface a popup surface
    /// 
    /// ## Description
    /// 
    ///     Map the surface as a popup.
    /// 
    ///     A popup surface is a transient surface with an added pointer
    ///     grab.
    /// 
    ///     An existing implicit grab will be changed to owner-events mode,
    ///     and the popup grab will continue after the implicit grab ends
    ///     (i.e. releasing the mouse button does not cause the popup to
    ///     be unmapped).
    /// 
    ///     The popup grab continues until the window is destroyed or a
    ///     mouse button is pressed in any other client's window. A click
    ///     in any of the client's surfaces is reported as normal, however,
    ///     clicks in other clients' surfaces will be discarded and trigger
    ///     the callback.
    /// 
    ///     The x and y arguments specify the location of the upper left
    ///     corner of the surface relative to the upper left corner of the
    ///     parent surface, in surface-local coordinates.
    ///       
    /// ## Args 
    /// 
    /// ### seat
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     seat whose pointer is used
    /// 
    /// #### Interface
    /// 
    ///     wl_seat
    /// 
    /// ### serial
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     serial number of the implicit grab on the pointer
    /// 
    /// ### parent
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     parent surface
    /// 
    /// #### Interface
    /// 
    ///     wl_surface
    /// 
    /// ### x
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     surface-local x coordinate
    /// 
    /// ### y
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     surface-local y coordinate
    /// 
    /// ### flags
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     transient surface behavior
    /// 
    /// #### Enum
    /// 
    ///     transient
    /// 
    /// 
    pub fn set_popup(self: *const wl_shell_surface, seat: types.ObjectId, serial: u32, parent: types.ObjectId, x: i32, y: i32, flags: u32) !void {
        try self.runtime.sendRequest(self.object_id, 6, .{seat, serial, parent, x, y, flags, });
    }

    /// # set_maximized
    /// 
    /// ## Summary
    /// 
    ///     make the surface a maximized surface
    /// 
    /// ## Description
    /// 
    ///     Map the surface as a maximized surface.
    /// 
    ///     If an output parameter is given then the surface will be
    ///     maximized on that output. If the client does not specify the
    ///     output then the compositor will apply its policy - usually
    ///     choosing the output on which the surface has the biggest surface
    ///     area.
    /// 
    ///     The compositor will reply with a configure event telling
    ///     the expected new surface size. The operation is completed
    ///     on the next buffer attach to this surface.
    /// 
    ///     A maximized surface typically fills the entire output it is
    ///     bound to, except for desktop elements such as panels. This is
    ///     the main difference between a maximized shell surface and a
    ///     fullscreen shell surface.
    /// 
    ///     The details depend on the compositor implementation.
    ///       
    /// ## Args 
    /// 
    /// ### output
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     output on which the surface is to be maximized
    /// 
    /// #### Interface
    /// 
    ///     wl_output
    /// 
    /// #### Allow Null
    /// 
    ///     true
    /// 
    /// 
    pub fn set_maximized(self: *const wl_shell_surface, output: types.ObjectId) !void {
        try self.runtime.sendRequest(self.object_id, 7, .{output, });
    }

    /// # set_title
    /// 
    /// ## Summary
    /// 
    ///     set surface title
    /// 
    /// ## Description
    /// 
    ///     Set a short title for the surface.
    /// 
    ///     This string may be used to identify the surface in a task bar,
    ///     window list, or other user interface elements provided by the
    ///     compositor.
    /// 
    ///     The string must be encoded in UTF-8.
    ///       
    /// ## Args 
    /// 
    /// ### title
    /// 
    /// #### Type
    /// 
    ///     string
    /// 
    /// #### Summary
    /// 
    ///     surface title
    /// 
    /// 
    pub fn set_title(self: *const wl_shell_surface, title: []const u8) !void {
        try self.runtime.sendRequest(self.object_id, 8, .{types.String{.static = title}, });
    }

    /// # set_class
    /// 
    /// ## Summary
    /// 
    ///     set surface class
    /// 
    /// ## Description
    /// 
    ///     Set a class for the surface.
    /// 
    ///     The surface class identifies the general class of applications
    ///     to which the surface belongs. A common convention is to use the
    ///     file name (or the full path if it is a non-standard location) of
    ///     the application's .desktop file as the class.
    ///       
    /// ## Args 
    /// 
    /// ### class_
    /// 
    /// #### Type
    /// 
    ///     string
    /// 
    /// #### Summary
    /// 
    ///     surface class
    /// 
    /// 
    pub fn set_class(self: *const wl_shell_surface, class_: []const u8) !void {
        try self.runtime.sendRequest(self.object_id, 9, .{types.String{.static = class_}, });
    }

    /// # ping
    /// 
    /// ## Summary
    /// 
    ///     ping client
    /// 
    /// ## Description
    /// 
    ///     Ping a client to check if it is receiving events and sending
    ///     requests. A client is expected to reply with a pong request.
    ///       
    /// ## Args 
    /// 
    /// ### serial
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     serial number of the ping
    /// 
    /// 
    pub fn next_ping(self: *const wl_shell_surface) !?struct {serial: u32, } {
        return try self.runtime.next(self.object_id, 0, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_ping)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # configure
    /// 
    /// ## Summary
    /// 
    ///     suggest resize
    /// 
    /// ## Description
    /// 
    ///     The configure event asks the client to resize its surface.
    /// 
    ///     The size is a hint, in the sense that the client is free to
    ///     ignore it if it doesn't resize, pick a smaller size (to
    ///     satisfy aspect ratio or resize in steps of NxM pixels).
    /// 
    ///     The edges parameter provides a hint about how the surface
    ///     was resized. The client may use this information to decide
    ///     how to adjust its content to the new size (e.g. a scrolling
    ///     area might adjust its content position to leave the viewable
    ///     content unmoved).
    /// 
    ///     The client is free to dismiss all but the last configure
    ///     event it received.
    /// 
    ///     The width and height arguments specify the size of the window
    ///     in surface-local coordinates.
    ///       
    /// ## Args 
    /// 
    /// ### edges
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     how the surface was resized
    /// 
    /// #### Enum
    /// 
    ///     resize
    /// 
    /// ### width
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     new width of the surface
    /// 
    /// ### height
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     new height of the surface
    /// 
    /// 
    pub fn next_configure(self: *const wl_shell_surface) !?struct {edges: u32, width: i32, height: i32, } {
        return try self.runtime.next(self.object_id, 1, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_configure)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # popup_done
    /// 
    /// ## Summary
    /// 
    ///     popup interaction is done
    /// 
    /// ## Description
    /// 
    ///     The popup_done event is sent out when a popup grab is broken,
    ///     that is, when the user clicks a surface that doesn't belong
    ///     to the client owning the popup surface.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn next_popup_done(self: *const wl_shell_surface) !?struct {} {
        return try self.runtime.next(self.object_id, 2, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_popup_done)).@"fn".return_type.?).error_union.payload).optional.child);
}
};

/// # wl_surface
/// 
/// ## Summary
/// 
///     an onscreen surface
/// 
/// ## Description
/// 
///       A surface is a rectangular area that may be displayed on zero
///       or more outputs, and shown any number of times at the compositor's
///       discretion. They can present wl_buffers, receive user input, and
///       define a local coordinate system.
/// 
///       The size of a surface (and relative positions on it) is described
///       in surface-local coordinates, which may differ from the buffer
///       coordinates of the pixel content, in case a buffer_transform
///       or a buffer_scale is used.
/// 
///       A surface without a "role" is fairly useless: a compositor does
///       not know where, when or how to present it. The role is the
///       purpose of a wl_surface. Examples of roles are a cursor for a
///       pointer (as set by wl_pointer.set_cursor), a drag icon
///       (wl_data_device.start_drag), a sub-surface
///       (wl_subcompositor.get_subsurface), and a window as defined by a
///       shell protocol (e.g. wl_shell.get_shell_surface).
/// 
///       A surface can have only one role at a time. Initially a
///       wl_surface does not have a role. Once a wl_surface is given a
///       role, it is set permanently for the whole lifetime of the
///       wl_surface object. Giving the current role again is allowed,
///       unless explicitly forbidden by the relevant interface
///       specification.
/// 
///       Surface roles are given by requests in other interfaces such as
///       wl_pointer.set_cursor. The request should explicitly mention
///       that this request gives a role to a wl_surface. Often, this
///       request also creates a new protocol object that represents the
///       role and adds additional functionality to wl_surface. When a
///       client wants to destroy a wl_surface, they must destroy this role
///       object before the wl_surface, otherwise a defunct_role_object error is
///       sent.
/// 
///       Destroying the role object does not remove the role from the
///       wl_surface, but it may stop the wl_surface from "playing the role".
///       For instance, if a wl_subsurface object is destroyed, the wl_surface
///       it was created for will be unmapped and forget its position and
///       z-order. It is allowed to create a wl_subsurface for the same
///       wl_surface again, but it is not allowed to use the wl_surface as
///       a cursor (cursor is a different role than sub-surface, and role
///       switching is not allowed).
///     
pub const wl_surface = struct {
    pub const interface = "wl_surface";
    pub const version = 6;

    pub const enums = struct{
        /// # error
        /// 
        /// ## Summary
        /// 
        ///     wl_surface error values
        /// 
        /// ## Description
        /// 
        ///     These errors can be emitted in response to wl_surface requests.
        ///       
        pub const @"error" = enum(u32) {
            invalid_scale = 0,
            invalid_transform = 1,
            invalid_size = 2,
            invalid_offset = 3,
            defunct_role_object = 4,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # destroy
    /// 
    /// ## Summary
    /// 
    ///     delete surface
    /// 
    /// ## Description
    /// 
    ///     Deletes the surface and invalidates its object ID.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn destroy(self: *const wl_surface) !void {
        try self.runtime.sendRequest(self.object_id, 0, .{});
    }

    /// # attach
    /// 
    /// ## Summary
    /// 
    ///     set the surface contents
    /// 
    /// ## Description
    /// 
    ///     Set a buffer as the content of this surface.
    /// 
    ///     The new size of the surface is calculated based on the buffer
    ///     size transformed by the inverse buffer_transform and the
    ///     inverse buffer_scale. This means that at commit time the supplied
    ///     buffer size must be an integer multiple of the buffer_scale. If
    ///     that's not the case, an invalid_size error is sent.
    /// 
    ///     The x and y arguments specify the location of the new pending
    ///     buffer's upper left corner, relative to the current buffer's upper
    ///     left corner, in surface-local coordinates. In other words, the
    ///     x and y, combined with the new surface size define in which
    ///     directions the surface's size changes. Setting anything other than 0
    ///     as x and y arguments is discouraged, and should instead be replaced
    ///     with using the separate wl_surface.offset request.
    /// 
    ///     When the bound wl_surface version is 5 or higher, passing any
    ///     non-zero x or y is a protocol violation, and will result in an
    ///     'invalid_offset' error being raised. The x and y arguments are ignored
    ///     and do not change the pending state. To achieve equivalent semantics,
    ///     use wl_surface.offset.
    /// 
    ///     Surface contents are double-buffered state, see wl_surface.commit.
    /// 
    ///     The initial surface contents are void; there is no content.
    ///     wl_surface.attach assigns the given wl_buffer as the pending
    ///     wl_buffer. wl_surface.commit makes the pending wl_buffer the new
    ///     surface contents, and the size of the surface becomes the size
    ///     calculated from the wl_buffer, as described above. After commit,
    ///     there is no pending buffer until the next attach.
    /// 
    ///     Committing a pending wl_buffer allows the compositor to read the
    ///     pixels in the wl_buffer. The compositor may access the pixels at
    ///     any time after the wl_surface.commit request. When the compositor
    ///     will not access the pixels anymore, it will send the
    ///     wl_buffer.release event. Only after receiving wl_buffer.release,
    ///     the client may reuse the wl_buffer. A wl_buffer that has been
    ///     attached and then replaced by another attach instead of committed
    ///     will not receive a release event, and is not used by the
    ///     compositor.
    /// 
    ///     If a pending wl_buffer has been committed to more than one wl_surface,
    ///     the delivery of wl_buffer.release events becomes undefined. A well
    ///     behaved client should not rely on wl_buffer.release events in this
    ///     case. Alternatively, a client could create multiple wl_buffer objects
    ///     from the same backing storage or use wp_linux_buffer_release.
    /// 
    ///     Destroying the wl_buffer after wl_buffer.release does not change
    ///     the surface contents. Destroying the wl_buffer before wl_buffer.release
    ///     is allowed as long as the underlying buffer storage isn't re-used (this
    ///     can happen e.g. on client process termination). However, if the client
    ///     destroys the wl_buffer before receiving the wl_buffer.release event and
    ///     mutates the underlying buffer storage, the surface contents become
    ///     undefined immediately.
    /// 
    ///     If wl_surface.attach is sent with a NULL wl_buffer, the
    ///     following wl_surface.commit will remove the surface content.
    /// 
    ///     If a pending wl_buffer has been destroyed, the result is not specified.
    ///     Many compositors are known to remove the surface content on the following
    ///     wl_surface.commit, but this behaviour is not universal. Clients seeking to
    ///     maximise compatibility should not destroy pending buffers and should
    ///     ensure that they explicitly remove content from surfaces, even after
    ///     destroying buffers.
    ///       
    /// ## Args 
    /// 
    /// ### buffer
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     buffer of surface contents
    /// 
    /// #### Interface
    /// 
    ///     wl_buffer
    /// 
    /// #### Allow Null
    /// 
    ///     true
    /// 
    /// ### x
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     surface-local x coordinate
    /// 
    /// ### y
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     surface-local y coordinate
    /// 
    /// 
    pub fn attach(self: *const wl_surface, buffer: types.ObjectId, x: i32, y: i32) !void {
        try self.runtime.sendRequest(self.object_id, 1, .{buffer, x, y, });
    }

    /// # damage
    /// 
    /// ## Summary
    /// 
    ///     mark part of the surface damaged
    /// 
    /// ## Description
    /// 
    ///     This request is used to describe the regions where the pending
    ///     buffer is different from the current surface contents, and where
    ///     the surface therefore needs to be repainted. The compositor
    ///     ignores the parts of the damage that fall outside of the surface.
    /// 
    ///     Damage is double-buffered state, see wl_surface.commit.
    /// 
    ///     The damage rectangle is specified in surface-local coordinates,
    ///     where x and y specify the upper left corner of the damage rectangle.
    /// 
    ///     The initial value for pending damage is empty: no damage.
    ///     wl_surface.damage adds pending damage: the new pending damage
    ///     is the union of old pending damage and the given rectangle.
    /// 
    ///     wl_surface.commit assigns pending damage as the current damage,
    ///     and clears pending damage. The server will clear the current
    ///     damage as it repaints the surface.
    /// 
    ///     Note! New clients should not use this request. Instead damage can be
    ///     posted with wl_surface.damage_buffer which uses buffer coordinates
    ///     instead of surface coordinates.
    ///       
    /// ## Args 
    /// 
    /// ### x
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     surface-local x coordinate
    /// 
    /// ### y
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     surface-local y coordinate
    /// 
    /// ### width
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     width of damage rectangle
    /// 
    /// ### height
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     height of damage rectangle
    /// 
    /// 
    pub fn damage(self: *const wl_surface, x: i32, y: i32, width: i32, height: i32) !void {
        try self.runtime.sendRequest(self.object_id, 2, .{x, y, width, height, });
    }

    /// # frame
    /// 
    /// ## Summary
    /// 
    ///     request a frame throttling hint
    /// 
    /// ## Description
    /// 
    ///     Request a notification when it is a good time to start drawing a new
    ///     frame, by creating a frame callback. This is useful for throttling
    ///     redrawing operations, and driving animations.
    /// 
    ///     When a client is animating on a wl_surface, it can use the 'frame'
    ///     request to get notified when it is a good time to draw and commit the
    ///     next frame of animation. If the client commits an update earlier than
    ///     that, it is likely that some updates will not make it to the display,
    ///     and the client is wasting resources by drawing too often.
    /// 
    ///     The frame request will take effect on the next wl_surface.commit.
    ///     The notification will only be posted for one frame unless
    ///     requested again. For a wl_surface, the notifications are posted in
    ///     the order the frame requests were committed.
    /// 
    ///     The server must send the notifications so that a client
    ///     will not send excessive updates, while still allowing
    ///     the highest possible update rate for clients that wait for the reply
    ///     before drawing again. The server should give some time for the client
    ///     to draw and commit after sending the frame callback events to let it
    ///     hit the next output refresh.
    /// 
    ///     A server should avoid signaling the frame callbacks if the
    ///     surface is not visible in any way, e.g. the surface is off-screen,
    ///     or completely obscured by other opaque surfaces.
    /// 
    ///     The object returned by this request will be destroyed by the
    ///     compositor after the callback is fired and as such the client must not
    ///     attempt to use it after that point.
    /// 
    ///     The callback_data passed in the callback is the current time, in
    ///     milliseconds, with an undefined base.
    ///       
    /// ## Args 
    /// 
    /// ### callback
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Summary
    /// 
    ///     callback object for the frame request
    /// 
    /// #### Interface
    /// 
    ///     wl_callback
    /// 
    /// 
    pub fn frame(self: *const wl_surface) !struct { callback: wl_callback, } {
        const callback_id = self.runtime.getId();
        try self.runtime.sendRequest(self.object_id, 3, .{callback_id, });
        return .{.callback = wl_callback{.object_id = callback_id, .runtime = self.runtime}, };
    }

    /// # set_opaque_region
    /// 
    /// ## Summary
    /// 
    ///     set opaque region
    /// 
    /// ## Description
    /// 
    ///     This request sets the region of the surface that contains
    ///     opaque content.
    /// 
    ///     The opaque region is an optimization hint for the compositor
    ///     that lets it optimize the redrawing of content behind opaque
    ///     regions.  Setting an opaque region is not required for correct
    ///     behaviour, but marking transparent content as opaque will result
    ///     in repaint artifacts.
    /// 
    ///     The opaque region is specified in surface-local coordinates.
    /// 
    ///     The compositor ignores the parts of the opaque region that fall
    ///     outside of the surface.
    /// 
    ///     Opaque region is double-buffered state, see wl_surface.commit.
    /// 
    ///     wl_surface.set_opaque_region changes the pending opaque region.
    ///     wl_surface.commit copies the pending region to the current region.
    ///     Otherwise, the pending and current regions are never changed.
    /// 
    ///     The initial value for an opaque region is empty. Setting the pending
    ///     opaque region has copy semantics, and the wl_region object can be
    ///     destroyed immediately. A NULL wl_region causes the pending opaque
    ///     region to be set to empty.
    ///       
    /// ## Args 
    /// 
    /// ### region
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     opaque region of the surface
    /// 
    /// #### Interface
    /// 
    ///     wl_region
    /// 
    /// #### Allow Null
    /// 
    ///     true
    /// 
    /// 
    pub fn set_opaque_region(self: *const wl_surface, region: types.ObjectId) !void {
        try self.runtime.sendRequest(self.object_id, 4, .{region, });
    }

    /// # set_input_region
    /// 
    /// ## Summary
    /// 
    ///     set input region
    /// 
    /// ## Description
    /// 
    ///     This request sets the region of the surface that can receive
    ///     pointer and touch events.
    /// 
    ///     Input events happening outside of this region will try the next
    ///     surface in the server surface stack. The compositor ignores the
    ///     parts of the input region that fall outside of the surface.
    /// 
    ///     The input region is specified in surface-local coordinates.
    /// 
    ///     Input region is double-buffered state, see wl_surface.commit.
    /// 
    ///     wl_surface.set_input_region changes the pending input region.
    ///     wl_surface.commit copies the pending region to the current region.
    ///     Otherwise the pending and current regions are never changed,
    ///     except cursor and icon surfaces are special cases, see
    ///     wl_pointer.set_cursor and wl_data_device.start_drag.
    /// 
    ///     The initial value for an input region is infinite. That means the
    ///     whole surface will accept input. Setting the pending input region
    ///     has copy semantics, and the wl_region object can be destroyed
    ///     immediately. A NULL wl_region causes the input region to be set
    ///     to infinite.
    ///       
    /// ## Args 
    /// 
    /// ### region
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     input region of the surface
    /// 
    /// #### Interface
    /// 
    ///     wl_region
    /// 
    /// #### Allow Null
    /// 
    ///     true
    /// 
    /// 
    pub fn set_input_region(self: *const wl_surface, region: types.ObjectId) !void {
        try self.runtime.sendRequest(self.object_id, 5, .{region, });
    }

    /// # commit
    /// 
    /// ## Summary
    /// 
    ///     commit pending surface state
    /// 
    /// ## Description
    /// 
    ///     Surface state (input, opaque, and damage regions, attached buffers,
    ///     etc.) is double-buffered. Protocol requests modify the pending state,
    ///     as opposed to the active state in use by the compositor.
    /// 
    ///     A commit request atomically creates a content update from the pending
    ///     state, even if the pending state has not been touched. The content
    ///     update is placed in a queue until it becomes active. After commit, the
    ///     new pending state is as documented for each related request.
    /// 
    ///     When the content update is applied, the wl_buffer is applied before all
    ///     other state. This means that all coordinates in double-buffered state
    ///     are relative to the newly attached wl_buffers, except for
    ///     wl_surface.attach itself. If there is no newly attached wl_buffer, the
    ///     coordinates are relative to the previous content update.
    /// 
    ///     All requests that need a commit to become effective are documented
    ///     to affect double-buffered state.
    /// 
    ///     Other interfaces may add further double-buffered surface state.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn commit(self: *const wl_surface) !void {
        try self.runtime.sendRequest(self.object_id, 6, .{});
    }

    /// # set_buffer_transform
    /// 
    /// ## Summary
    /// 
    ///     sets the buffer transformation
    /// 
    /// ## Description
    /// 
    ///     This request sets the transformation that the client has already applied
    ///     to the content of the buffer. The accepted values for the transform
    ///     parameter are the values for wl_output.transform.
    /// 
    ///     The compositor applies the inverse of this transformation whenever it
    ///     uses the buffer contents.
    /// 
    ///     Buffer transform is double-buffered state, see wl_surface.commit.
    /// 
    ///     A newly created surface has its buffer transformation set to normal.
    /// 
    ///     wl_surface.set_buffer_transform changes the pending buffer
    ///     transformation. wl_surface.commit copies the pending buffer
    ///     transformation to the current one. Otherwise, the pending and current
    ///     values are never changed.
    /// 
    ///     The purpose of this request is to allow clients to render content
    ///     according to the output transform, thus permitting the compositor to
    ///     use certain optimizations even if the display is rotated. Using
    ///     hardware overlays and scanning out a client buffer for fullscreen
    ///     surfaces are examples of such optimizations. Those optimizations are
    ///     highly dependent on the compositor implementation, so the use of this
    ///     request should be considered on a case-by-case basis.
    /// 
    ///     Note that if the transform value includes 90 or 270 degree rotation,
    ///     the width of the buffer will become the surface height and the height
    ///     of the buffer will become the surface width.
    /// 
    ///     If transform is not one of the values from the
    ///     wl_output.transform enum the invalid_transform protocol error
    ///     is raised.
    ///       
    /// ## Args 
    /// 
    /// ### transform
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     transform for interpreting buffer contents
    /// 
    /// #### Enum
    /// 
    ///     wl_output.transform
    /// 
    /// 
    pub fn set_buffer_transform(self: *const wl_surface, transform: i32) !void {
        try self.runtime.sendRequest(self.object_id, 7, .{transform, });
    }

    /// # set_buffer_scale
    /// 
    /// ## Summary
    /// 
    ///     sets the buffer scaling factor
    /// 
    /// ## Description
    /// 
    ///     This request sets an optional scaling factor on how the compositor
    ///     interprets the contents of the buffer attached to the window.
    /// 
    ///     Buffer scale is double-buffered state, see wl_surface.commit.
    /// 
    ///     A newly created surface has its buffer scale set to 1.
    /// 
    ///     wl_surface.set_buffer_scale changes the pending buffer scale.
    ///     wl_surface.commit copies the pending buffer scale to the current one.
    ///     Otherwise, the pending and current values are never changed.
    /// 
    ///     The purpose of this request is to allow clients to supply higher
    ///     resolution buffer data for use on high resolution outputs. It is
    ///     intended that you pick the same buffer scale as the scale of the
    ///     output that the surface is displayed on. This means the compositor
    ///     can avoid scaling when rendering the surface on that output.
    /// 
    ///     Note that if the scale is larger than 1, then you have to attach
    ///     a buffer that is larger (by a factor of scale in each dimension)
    ///     than the desired surface size.
    /// 
    ///     If scale is not greater than 0 the invalid_scale protocol error is
    ///     raised.
    ///       
    /// ## Args 
    /// 
    /// ### scale
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     scale for interpreting buffer contents
    /// 
    /// 
    pub fn set_buffer_scale(self: *const wl_surface, scale: i32) !void {
        try self.runtime.sendRequest(self.object_id, 8, .{scale, });
    }

    /// # damage_buffer
    /// 
    /// ## Summary
    /// 
    ///     mark part of the surface damaged using buffer coordinates
    /// 
    /// ## Description
    /// 
    ///     This request is used to describe the regions where the pending
    ///     buffer is different from the current surface contents, and where
    ///     the surface therefore needs to be repainted. The compositor
    ///     ignores the parts of the damage that fall outside of the surface.
    /// 
    ///     Damage is double-buffered state, see wl_surface.commit.
    /// 
    ///     The damage rectangle is specified in buffer coordinates,
    ///     where x and y specify the upper left corner of the damage rectangle.
    /// 
    ///     The initial value for pending damage is empty: no damage.
    ///     wl_surface.damage_buffer adds pending damage: the new pending
    ///     damage is the union of old pending damage and the given rectangle.
    /// 
    ///     wl_surface.commit assigns pending damage as the current damage,
    ///     and clears pending damage. The server will clear the current
    ///     damage as it repaints the surface.
    /// 
    ///     This request differs from wl_surface.damage in only one way - it
    ///     takes damage in buffer coordinates instead of surface-local
    ///     coordinates. While this generally is more intuitive than surface
    ///     coordinates, it is especially desirable when using wp_viewport
    ///     or when a drawing library (like EGL) is unaware of buffer scale
    ///     and buffer transform.
    /// 
    ///     Note: Because buffer transformation changes and damage requests may
    ///     be interleaved in the protocol stream, it is impossible to determine
    ///     the actual mapping between surface and buffer damage until
    ///     wl_surface.commit time. Therefore, compositors wishing to take both
    ///     kinds of damage into account will have to accumulate damage from the
    ///     two requests separately and only transform from one to the other
    ///     after receiving the wl_surface.commit.
    ///       
    /// ## Args 
    /// 
    /// ### x
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     buffer-local x coordinate
    /// 
    /// ### y
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     buffer-local y coordinate
    /// 
    /// ### width
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     width of damage rectangle
    /// 
    /// ### height
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     height of damage rectangle
    /// 
    /// 
    pub fn damage_buffer(self: *const wl_surface, x: i32, y: i32, width: i32, height: i32) !void {
        try self.runtime.sendRequest(self.object_id, 9, .{x, y, width, height, });
    }

    /// # offset
    /// 
    /// ## Summary
    /// 
    ///     set the surface contents offset
    /// 
    /// ## Description
    /// 
    ///     The x and y arguments specify the location of the new pending
    ///     buffer's upper left corner, relative to the current buffer's upper
    ///     left corner, in surface-local coordinates. In other words, the
    ///     x and y, combined with the new surface size define in which
    ///     directions the surface's size changes.
    /// 
    ///     Surface location offset is double-buffered state, see
    ///     wl_surface.commit.
    /// 
    ///     This request is semantically equivalent to and the replaces the x and y
    ///     arguments in the wl_surface.attach request in wl_surface versions prior
    ///     to 5. See wl_surface.attach for details.
    ///       
    /// ## Args 
    /// 
    /// ### x
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     surface-local x coordinate
    /// 
    /// ### y
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     surface-local y coordinate
    /// 
    /// 
    pub fn offset(self: *const wl_surface, x: i32, y: i32) !void {
        try self.runtime.sendRequest(self.object_id, 10, .{x, y, });
    }

    /// # enter
    /// 
    /// ## Summary
    /// 
    ///     surface enters an output
    /// 
    /// ## Description
    /// 
    ///     This is emitted whenever a surface's creation, movement, or resizing
    ///     results in some part of it being within the scanout region of an
    ///     output.
    /// 
    ///     Note that a surface may be overlapping with zero or more outputs.
    ///       
    /// ## Args 
    /// 
    /// ### output
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     output entered by the surface
    /// 
    /// #### Interface
    /// 
    ///     wl_output
    /// 
    /// 
    pub fn next_enter(self: *const wl_surface) !?struct {output: types.ObjectId, } {
        return try self.runtime.next(self.object_id, 0, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_enter)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # leave
    /// 
    /// ## Summary
    /// 
    ///     surface leaves an output
    /// 
    /// ## Description
    /// 
    ///     This is emitted whenever a surface's creation, movement, or resizing
    ///     results in it no longer having any part of it within the scanout region
    ///     of an output.
    /// 
    ///     Clients should not use the number of outputs the surface is on for frame
    ///     throttling purposes. The surface might be hidden even if no leave event
    ///     has been sent, and the compositor might expect new surface content
    ///     updates even if no enter event has been sent. The frame event should be
    ///     used instead.
    ///       
    /// ## Args 
    /// 
    /// ### output
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     output left by the surface
    /// 
    /// #### Interface
    /// 
    ///     wl_output
    /// 
    /// 
    pub fn next_leave(self: *const wl_surface) !?struct {output: types.ObjectId, } {
        return try self.runtime.next(self.object_id, 1, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_leave)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # preferred_buffer_scale
    /// 
    /// ## Summary
    /// 
    ///     preferred buffer scale for the surface
    /// 
    /// ## Description
    /// 
    ///     This event indicates the preferred buffer scale for this surface. It is
    ///     sent whenever the compositor's preference changes.
    /// 
    ///     Before receiving this event the preferred buffer scale for this surface
    ///     is 1.
    /// 
    ///     It is intended that scaling aware clients use this event to scale their
    ///     content and use wl_surface.set_buffer_scale to indicate the scale they
    ///     have rendered with. This allows clients to supply a higher detail
    ///     buffer.
    /// 
    ///     The compositor shall emit a scale value greater than 0.
    ///       
    /// ## Args 
    /// 
    /// ### factor
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     preferred scaling factor
    /// 
    /// 
    pub fn next_preferred_buffer_scale(self: *const wl_surface) !?struct {factor: i32, } {
        return try self.runtime.next(self.object_id, 2, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_preferred_buffer_scale)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # preferred_buffer_transform
    /// 
    /// ## Summary
    /// 
    ///     preferred buffer transform for the surface
    /// 
    /// ## Description
    /// 
    ///     This event indicates the preferred buffer transform for this surface.
    ///     It is sent whenever the compositor's preference changes.
    /// 
    ///     Before receiving this event the preferred buffer transform for this
    ///     surface is normal.
    /// 
    ///     Applying this transformation to the surface buffer contents and using
    ///     wl_surface.set_buffer_transform might allow the compositor to use the
    ///     surface buffer more efficiently.
    ///       
    /// ## Args 
    /// 
    /// ### transform
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     preferred transform
    /// 
    /// #### Enum
    /// 
    ///     wl_output.transform
    /// 
    /// 
    pub fn next_preferred_buffer_transform(self: *const wl_surface) !?struct {transform: u32, } {
        return try self.runtime.next(self.object_id, 3, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_preferred_buffer_transform)).@"fn".return_type.?).error_union.payload).optional.child);
}
};

/// # wl_seat
/// 
/// ## Summary
/// 
///     group of input devices
/// 
/// ## Description
/// 
///       A seat is a group of keyboards, pointer and touch devices. This
///       object is published as a global during start up, or when such a
///       device is hot plugged.  A seat typically has a pointer and
///       maintains a keyboard focus and a pointer focus.
///     
pub const wl_seat = struct {
    pub const interface = "wl_seat";
    pub const version = 9;

    pub const enums = struct{
        /// # capability
        /// 
        /// ## Summary
        /// 
        ///     seat capability bitmask
        /// 
        /// ## Description
        /// 
        ///     This is a bitmask of capabilities this seat has; if a member is
        ///     set, then it is present on the seat.
        ///       
        pub const capability = enum(u32) {
            pointer = 1,
            keyboard = 2,
            touch = 4,
        };

        /// # error
        /// 
        /// ## Summary
        /// 
        ///     wl_seat error values
        /// 
        /// ## Description
        /// 
        ///     These errors can be emitted in response to wl_seat requests.
        ///       
        pub const @"error" = enum(u32) {
            missing_capability = 0,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # get_pointer
    /// 
    /// ## Summary
    /// 
    ///     return pointer object
    /// 
    /// ## Description
    /// 
    ///     The ID provided will be initialized to the wl_pointer interface
    ///     for this seat.
    /// 
    ///     This request only takes effect if the seat has the pointer
    ///     capability, or has had the pointer capability in the past.
    ///     It is a protocol violation to issue this request on a seat that has
    ///     never had the pointer capability. The missing_capability error will
    ///     be sent in this case.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Summary
    /// 
    ///     seat pointer
    /// 
    /// #### Interface
    /// 
    ///     wl_pointer
    /// 
    /// 
    pub fn get_pointer(self: *const wl_seat) !struct { id: wl_pointer, } {
        const id_id = self.runtime.getId();
        try self.runtime.sendRequest(self.object_id, 0, .{id_id, });
        return .{.id = wl_pointer{.object_id = id_id, .runtime = self.runtime}, };
    }

    /// # get_keyboard
    /// 
    /// ## Summary
    /// 
    ///     return keyboard object
    /// 
    /// ## Description
    /// 
    ///     The ID provided will be initialized to the wl_keyboard interface
    ///     for this seat.
    /// 
    ///     This request only takes effect if the seat has the keyboard
    ///     capability, or has had the keyboard capability in the past.
    ///     It is a protocol violation to issue this request on a seat that has
    ///     never had the keyboard capability. The missing_capability error will
    ///     be sent in this case.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Summary
    /// 
    ///     seat keyboard
    /// 
    /// #### Interface
    /// 
    ///     wl_keyboard
    /// 
    /// 
    pub fn get_keyboard(self: *const wl_seat) !struct { id: wl_keyboard, } {
        const id_id = self.runtime.getId();
        try self.runtime.sendRequest(self.object_id, 1, .{id_id, });
        return .{.id = wl_keyboard{.object_id = id_id, .runtime = self.runtime}, };
    }

    /// # get_touch
    /// 
    /// ## Summary
    /// 
    ///     return touch object
    /// 
    /// ## Description
    /// 
    ///     The ID provided will be initialized to the wl_touch interface
    ///     for this seat.
    /// 
    ///     This request only takes effect if the seat has the touch
    ///     capability, or has had the touch capability in the past.
    ///     It is a protocol violation to issue this request on a seat that has
    ///     never had the touch capability. The missing_capability error will
    ///     be sent in this case.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Summary
    /// 
    ///     seat touch interface
    /// 
    /// #### Interface
    /// 
    ///     wl_touch
    /// 
    /// 
    pub fn get_touch(self: *const wl_seat) !struct { id: wl_touch, } {
        const id_id = self.runtime.getId();
        try self.runtime.sendRequest(self.object_id, 2, .{id_id, });
        return .{.id = wl_touch{.object_id = id_id, .runtime = self.runtime}, };
    }

    /// # release
    /// 
    /// ## Summary
    /// 
    ///     release the seat object
    /// 
    /// ## Description
    /// 
    ///     Using this request a client can tell the server that it is not going to
    ///     use the seat object anymore.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn release(self: *const wl_seat) !void {
        try self.runtime.sendRequest(self.object_id, 3, .{});
    }

    /// # capabilities
    /// 
    /// ## Summary
    /// 
    ///     seat capabilities changed
    /// 
    /// ## Description
    /// 
    ///     This is emitted whenever a seat gains or loses the pointer,
    ///     keyboard or touch capabilities.  The argument is a capability
    ///     enum containing the complete set of capabilities this seat has.
    /// 
    ///     When the pointer capability is added, a client may create a
    ///     wl_pointer object using the wl_seat.get_pointer request. This object
    ///     will receive pointer events until the capability is removed in the
    ///     future.
    /// 
    ///     When the pointer capability is removed, a client should destroy the
    ///     wl_pointer objects associated with the seat where the capability was
    ///     removed, using the wl_pointer.release request. No further pointer
    ///     events will be received on these objects.
    /// 
    ///     In some compositors, if a seat regains the pointer capability and a
    ///     client has a previously obtained wl_pointer object of version 4 or
    ///     less, that object may start sending pointer events again. This
    ///     behavior is considered a misinterpretation of the intended behavior
    ///     and must not be relied upon by the client. wl_pointer objects of
    ///     version 5 or later must not send events if created before the most
    ///     recent event notifying the client of an added pointer capability.
    /// 
    ///     The above behavior also applies to wl_keyboard and wl_touch with the
    ///     keyboard and touch capabilities, respectively.
    ///       
    /// ## Args 
    /// 
    /// ### capabilities
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     capabilities of the seat
    /// 
    /// #### Enum
    /// 
    ///     capability
    /// 
    /// 
    pub fn next_capabilities(self: *const wl_seat) !?struct {capabilities: u32, } {
        return try self.runtime.next(self.object_id, 0, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_capabilities)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # name
    /// 
    /// ## Summary
    /// 
    ///     unique identifier for this seat
    /// 
    /// ## Description
    /// 
    ///     In a multi-seat configuration the seat name can be used by clients to
    ///     help identify which physical devices the seat represents.
    /// 
    ///     The seat name is a UTF-8 string with no convention defined for its
    ///     contents. Each name is unique among all wl_seat globals. The name is
    ///     only guaranteed to be unique for the current compositor instance.
    /// 
    ///     The same seat names are used for all clients. Thus, the name can be
    ///     shared across processes to refer to a specific wl_seat global.
    /// 
    ///     The name event is sent after binding to the seat global. This event is
    ///     only sent once per seat object, and the name does not change over the
    ///     lifetime of the wl_seat global.
    /// 
    ///     Compositors may re-use the same seat name if the wl_seat global is
    ///     destroyed and re-created later.
    ///       
    /// ## Args 
    /// 
    /// ### name
    /// 
    /// #### Type
    /// 
    ///     string
    /// 
    /// #### Summary
    /// 
    ///     seat identifier
    /// 
    /// 
    pub fn next_name(self: *const wl_seat) !?struct {name: types.String, } {
        return try self.runtime.next(self.object_id, 1, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_name)).@"fn".return_type.?).error_union.payload).optional.child);
}
};

/// # wl_pointer
/// 
/// ## Summary
/// 
///     pointer input device
/// 
/// ## Description
/// 
///       The wl_pointer interface represents one or more input devices,
///       such as mice, which control the pointer location and pointer_focus
///       of a seat.
/// 
///       The wl_pointer interface generates motion, enter and leave
///       events for the surfaces that the pointer is located over,
///       and button and axis events for button presses, button releases
///       and scrolling.
///     
pub const wl_pointer = struct {
    pub const interface = "wl_pointer";
    pub const version = 9;

    pub const enums = struct{
        pub const @"error" = enum(u32) {
            role = 0,
        };

        /// # button_state
        /// 
        /// ## Summary
        /// 
        ///     physical button state
        /// 
        /// ## Description
        /// 
        ///     Describes the physical state of a button that produced the button
        ///     event.
        ///       
        pub const button_state = enum(u32) {
            released = 0,
            pressed = 1,
        };

        /// # axis
        /// 
        /// ## Summary
        /// 
        ///     axis types
        /// 
        /// ## Description
        /// 
        ///     Describes the axis types of scroll events.
        ///       
        pub const axis = enum(u32) {
            vertical_scroll = 0,
            horizontal_scroll = 1,
        };

        /// # axis_source
        /// 
        /// ## Summary
        /// 
        ///     axis source types
        /// 
        /// ## Description
        /// 
        ///     Describes the source types for axis events. This indicates to the
        ///     client how an axis event was physically generated; a client may
        ///     adjust the user interface accordingly. For example, scroll events
        ///     from a "finger" source may be in a smooth coordinate space with
        ///     kinetic scrolling whereas a "wheel" source may be in discrete steps
        ///     of a number of lines.
        /// 
        ///     The "continuous" axis source is a device generating events in a
        ///     continuous coordinate space, but using something other than a
        ///     finger. One example for this source is button-based scrolling where
        ///     the vertical motion of a device is converted to scroll events while
        ///     a button is held down.
        /// 
        ///     The "wheel tilt" axis source indicates that the actual device is a
        ///     wheel but the scroll event is not caused by a rotation but a
        ///     (usually sideways) tilt of the wheel.
        ///       
        pub const axis_source = enum(u32) {
            wheel = 0,
            finger = 1,
            continuous = 2,
            wheel_tilt = 3,
        };

        /// # axis_relative_direction
        /// 
        /// ## Summary
        /// 
        ///     axis relative direction
        /// 
        /// ## Description
        /// 
        ///     This specifies the direction of the physical motion that caused a
        ///     wl_pointer.axis event, relative to the wl_pointer.axis direction.
        ///       
        pub const axis_relative_direction = enum(u32) {
            identical = 0,
            inverted = 1,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # set_cursor
    /// 
    /// ## Summary
    /// 
    ///     set the pointer surface
    /// 
    /// ## Description
    /// 
    ///     Set the pointer surface, i.e., the surface that contains the
    ///     pointer image (cursor). This request gives the surface the role
    ///     of a cursor. If the surface already has another role, it raises
    ///     a protocol error.
    /// 
    ///     The cursor actually changes only if the pointer
    ///     focus for this device is one of the requesting client's surfaces
    ///     or the surface parameter is the current pointer surface. If
    ///     there was a previous surface set with this request it is
    ///     replaced. If surface is NULL, the pointer image is hidden.
    /// 
    ///     The parameters hotspot_x and hotspot_y define the position of
    ///     the pointer surface relative to the pointer location. Its
    ///     top-left corner is always at (x, y) - (hotspot_x, hotspot_y),
    ///     where (x, y) are the coordinates of the pointer location, in
    ///     surface-local coordinates.
    /// 
    ///     On wl_surface.offset requests to the pointer surface, hotspot_x
    ///     and hotspot_y are decremented by the x and y parameters
    ///     passed to the request. The offset must be applied by
    ///     wl_surface.commit as usual.
    /// 
    ///     The hotspot can also be updated by passing the currently set
    ///     pointer surface to this request with new values for hotspot_x
    ///     and hotspot_y.
    /// 
    ///     The input region is ignored for wl_surfaces with the role of
    ///     a cursor. When the use as a cursor ends, the wl_surface is
    ///     unmapped.
    /// 
    ///     The serial parameter must match the latest wl_pointer.enter
    ///     serial number sent to the client. Otherwise the request will be
    ///     ignored.
    ///       
    /// ## Args 
    /// 
    /// ### serial
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     serial number of the enter event
    /// 
    /// ### surface
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     pointer surface
    /// 
    /// #### Interface
    /// 
    ///     wl_surface
    /// 
    /// #### Allow Null
    /// 
    ///     true
    /// 
    /// ### hotspot_x
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     surface-local x coordinate
    /// 
    /// ### hotspot_y
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     surface-local y coordinate
    /// 
    /// 
    pub fn set_cursor(self: *const wl_pointer, serial: u32, surface: types.ObjectId, hotspot_x: i32, hotspot_y: i32) !void {
        try self.runtime.sendRequest(self.object_id, 0, .{serial, surface, hotspot_x, hotspot_y, });
    }

    /// # release
    /// 
    /// ## Summary
    /// 
    ///     release the pointer object
    /// 
    /// ## Description
    /// 
    ///     Using this request a client can tell the server that it is not going to
    ///     use the pointer object anymore.
    /// 
    ///     This request destroys the pointer proxy object, so clients must not call
    ///     wl_pointer_destroy() after using this request.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn release(self: *const wl_pointer) !void {
        try self.runtime.sendRequest(self.object_id, 1, .{});
    }

    /// # enter
    /// 
    /// ## Summary
    /// 
    ///     enter event
    /// 
    /// ## Description
    /// 
    ///     Notification that this seat's pointer is focused on a certain
    ///     surface.
    /// 
    ///     When a seat's focus enters a surface, the pointer image
    ///     is undefined and a client should respond to this event by setting
    ///     an appropriate pointer image with the set_cursor request.
    ///       
    /// ## Args 
    /// 
    /// ### serial
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     serial number of the enter event
    /// 
    /// ### surface
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     surface entered by the pointer
    /// 
    /// #### Interface
    /// 
    ///     wl_surface
    /// 
    /// ### surface_x
    /// 
    /// #### Type
    /// 
    ///     fixed
    /// 
    /// #### Summary
    /// 
    ///     surface-local x coordinate
    /// 
    /// ### surface_y
    /// 
    /// #### Type
    /// 
    ///     fixed
    /// 
    /// #### Summary
    /// 
    ///     surface-local y coordinate
    /// 
    /// 
    pub fn next_enter(self: *const wl_pointer) !?struct {serial: u32, surface: types.ObjectId, surface_x: types.Fixed, surface_y: types.Fixed, } {
        return try self.runtime.next(self.object_id, 0, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_enter)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # leave
    /// 
    /// ## Summary
    /// 
    ///     leave event
    /// 
    /// ## Description
    /// 
    ///     Notification that this seat's pointer is no longer focused on
    ///     a certain surface.
    /// 
    ///     The leave notification is sent before the enter notification
    ///     for the new focus.
    ///       
    /// ## Args 
    /// 
    /// ### serial
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     serial number of the leave event
    /// 
    /// ### surface
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     surface left by the pointer
    /// 
    /// #### Interface
    /// 
    ///     wl_surface
    /// 
    /// 
    pub fn next_leave(self: *const wl_pointer) !?struct {serial: u32, surface: types.ObjectId, } {
        return try self.runtime.next(self.object_id, 1, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_leave)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # motion
    /// 
    /// ## Summary
    /// 
    ///     pointer motion event
    /// 
    /// ## Description
    /// 
    ///     Notification of pointer location change. The arguments
    ///     surface_x and surface_y are the location relative to the
    ///     focused surface.
    ///       
    /// ## Args 
    /// 
    /// ### time
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     timestamp with millisecond granularity
    /// 
    /// ### surface_x
    /// 
    /// #### Type
    /// 
    ///     fixed
    /// 
    /// #### Summary
    /// 
    ///     surface-local x coordinate
    /// 
    /// ### surface_y
    /// 
    /// #### Type
    /// 
    ///     fixed
    /// 
    /// #### Summary
    /// 
    ///     surface-local y coordinate
    /// 
    /// 
    pub fn next_motion(self: *const wl_pointer) !?struct {time: u32, surface_x: types.Fixed, surface_y: types.Fixed, } {
        return try self.runtime.next(self.object_id, 2, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_motion)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # button
    /// 
    /// ## Summary
    /// 
    ///     pointer button event
    /// 
    /// ## Description
    /// 
    ///     Mouse button click and release notifications.
    /// 
    ///     The location of the click is given by the last motion or
    ///     enter event.
    ///     The time argument is a timestamp with millisecond
    ///     granularity, with an undefined base.
    /// 
    ///     The button is a button code as defined in the Linux kernel's
    ///     linux/input-event-codes.h header file, e.g. BTN_LEFT.
    /// 
    ///     Any 16-bit button code value is reserved for future additions to the
    ///     kernel's event code list. All other button codes above 0xFFFF are
    ///     currently undefined but may be used in future versions of this
    ///     protocol.
    ///       
    /// ## Args 
    /// 
    /// ### serial
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     serial number of the button event
    /// 
    /// ### time
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     timestamp with millisecond granularity
    /// 
    /// ### button
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     button that produced the event
    /// 
    /// ### state
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     physical state of the button
    /// 
    /// #### Enum
    /// 
    ///     button_state
    /// 
    /// 
    pub fn next_button(self: *const wl_pointer) !?struct {serial: u32, time: u32, button: u32, state: u32, } {
        return try self.runtime.next(self.object_id, 3, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_button)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # axis
    /// 
    /// ## Summary
    /// 
    ///     axis event
    /// 
    /// ## Description
    /// 
    ///     Scroll and other axis notifications.
    /// 
    ///     For scroll events (vertical and horizontal scroll axes), the
    ///     value parameter is the length of a vector along the specified
    ///     axis in a coordinate space identical to those of motion events,
    ///     representing a relative movement along the specified axis.
    /// 
    ///     For devices that support movements non-parallel to axes multiple
    ///     axis events will be emitted.
    /// 
    ///     When applicable, for example for touch pads, the server can
    ///     choose to emit scroll events where the motion vector is
    ///     equivalent to a motion event vector.
    /// 
    ///     When applicable, a client can transform its content relative to the
    ///     scroll distance.
    ///       
    /// ## Args 
    /// 
    /// ### time
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     timestamp with millisecond granularity
    /// 
    /// ### axis
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     axis type
    /// 
    /// #### Enum
    /// 
    ///     axis
    /// 
    /// ### value
    /// 
    /// #### Type
    /// 
    ///     fixed
    /// 
    /// #### Summary
    /// 
    ///     length of vector in surface-local coordinate space
    /// 
    /// 
    pub fn next_axis(self: *const wl_pointer) !?struct {time: u32, axis: u32, value: types.Fixed, } {
        return try self.runtime.next(self.object_id, 4, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_axis)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # frame
    /// 
    /// ## Summary
    /// 
    ///     end of a pointer event sequence
    /// 
    /// ## Description
    /// 
    ///     Indicates the end of a set of events that logically belong together.
    ///     A client is expected to accumulate the data in all events within the
    ///     frame before proceeding.
    /// 
    ///     All wl_pointer events before a wl_pointer.frame event belong
    ///     logically together. For example, in a diagonal scroll motion the
    ///     compositor will send an optional wl_pointer.axis_source event, two
    ///     wl_pointer.axis events (horizontal and vertical) and finally a
    ///     wl_pointer.frame event. The client may use this information to
    ///     calculate a diagonal vector for scrolling.
    /// 
    ///     When multiple wl_pointer.axis events occur within the same frame,
    ///     the motion vector is the combined motion of all events.
    ///     When a wl_pointer.axis and a wl_pointer.axis_stop event occur within
    ///     the same frame, this indicates that axis movement in one axis has
    ///     stopped but continues in the other axis.
    ///     When multiple wl_pointer.axis_stop events occur within the same
    ///     frame, this indicates that these axes stopped in the same instance.
    /// 
    ///     A wl_pointer.frame event is sent for every logical event group,
    ///     even if the group only contains a single wl_pointer event.
    ///     Specifically, a client may get a sequence: motion, frame, button,
    ///     frame, axis, frame, axis_stop, frame.
    /// 
    ///     The wl_pointer.enter and wl_pointer.leave events are logical events
    ///     generated by the compositor and not the hardware. These events are
    ///     also grouped by a wl_pointer.frame. When a pointer moves from one
    ///     surface to another, a compositor should group the
    ///     wl_pointer.leave event within the same wl_pointer.frame.
    ///     However, a client must not rely on wl_pointer.leave and
    ///     wl_pointer.enter being in the same wl_pointer.frame.
    ///     Compositor-specific policies may require the wl_pointer.leave and
    ///     wl_pointer.enter event being split across multiple wl_pointer.frame
    ///     groups.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn next_frame(self: *const wl_pointer) !?struct {} {
        return try self.runtime.next(self.object_id, 5, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_frame)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # axis_source
    /// 
    /// ## Summary
    /// 
    ///     axis source event
    /// 
    /// ## Description
    /// 
    ///     Source information for scroll and other axes.
    /// 
    ///     This event does not occur on its own. It is sent before a
    ///     wl_pointer.frame event and carries the source information for
    ///     all events within that frame.
    /// 
    ///     The source specifies how this event was generated. If the source is
    ///     wl_pointer.axis_source.finger, a wl_pointer.axis_stop event will be
    ///     sent when the user lifts the finger off the device.
    /// 
    ///     If the source is wl_pointer.axis_source.wheel,
    ///     wl_pointer.axis_source.wheel_tilt or
    ///     wl_pointer.axis_source.continuous, a wl_pointer.axis_stop event may
    ///     or may not be sent. Whether a compositor sends an axis_stop event
    ///     for these sources is hardware-specific and implementation-dependent;
    ///     clients must not rely on receiving an axis_stop event for these
    ///     scroll sources and should treat scroll sequences from these scroll
    ///     sources as unterminated by default.
    /// 
    ///     This event is optional. If the source is unknown for a particular
    ///     axis event sequence, no event is sent.
    ///     Only one wl_pointer.axis_source event is permitted per frame.
    /// 
    ///     The order of wl_pointer.axis_discrete and wl_pointer.axis_source is
    ///     not guaranteed.
    ///       
    /// ## Args 
    /// 
    /// ### axis_source
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     source of the axis event
    /// 
    /// #### Enum
    /// 
    ///     axis_source
    /// 
    /// 
    pub fn next_axis_source(self: *const wl_pointer) !?struct {axis_source: u32, } {
        return try self.runtime.next(self.object_id, 6, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_axis_source)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # axis_stop
    /// 
    /// ## Summary
    /// 
    ///     axis stop event
    /// 
    /// ## Description
    /// 
    ///     Stop notification for scroll and other axes.
    /// 
    ///     For some wl_pointer.axis_source types, a wl_pointer.axis_stop event
    ///     is sent to notify a client that the axis sequence has terminated.
    ///     This enables the client to implement kinetic scrolling.
    ///     See the wl_pointer.axis_source documentation for information on when
    ///     this event may be generated.
    /// 
    ///     Any wl_pointer.axis events with the same axis_source after this
    ///     event should be considered as the start of a new axis motion.
    /// 
    ///     The timestamp is to be interpreted identical to the timestamp in the
    ///     wl_pointer.axis event. The timestamp value may be the same as a
    ///     preceding wl_pointer.axis event.
    ///       
    /// ## Args 
    /// 
    /// ### time
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     timestamp with millisecond granularity
    /// 
    /// ### axis
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     the axis stopped with this event
    /// 
    /// #### Enum
    /// 
    ///     axis
    /// 
    /// 
    pub fn next_axis_stop(self: *const wl_pointer) !?struct {time: u32, axis: u32, } {
        return try self.runtime.next(self.object_id, 7, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_axis_stop)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # axis_discrete
    /// 
    /// ## Summary
    /// 
    ///     axis click event
    /// 
    /// ## Description
    /// 
    ///     Discrete step information for scroll and other axes.
    /// 
    ///     This event carries the axis value of the wl_pointer.axis event in
    ///     discrete steps (e.g. mouse wheel clicks).
    /// 
    ///     This event is deprecated with wl_pointer version 8 - this event is not
    ///     sent to clients supporting version 8 or later.
    /// 
    ///     This event does not occur on its own, it is coupled with a
    ///     wl_pointer.axis event that represents this axis value on a
    ///     continuous scale. The protocol guarantees that each axis_discrete
    ///     event is always followed by exactly one axis event with the same
    ///     axis number within the same wl_pointer.frame. Note that the protocol
    ///     allows for other events to occur between the axis_discrete and
    ///     its coupled axis event, including other axis_discrete or axis
    ///     events. A wl_pointer.frame must not contain more than one axis_discrete
    ///     event per axis type.
    /// 
    ///     This event is optional; continuous scrolling devices
    ///     like two-finger scrolling on touchpads do not have discrete
    ///     steps and do not generate this event.
    /// 
    ///     The discrete value carries the directional information. e.g. a value
    ///     of -2 is two steps towards the negative direction of this axis.
    /// 
    ///     The axis number is identical to the axis number in the associated
    ///     axis event.
    /// 
    ///     The order of wl_pointer.axis_discrete and wl_pointer.axis_source is
    ///     not guaranteed.
    ///       
    /// ## Args 
    /// 
    /// ### axis
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     axis type
    /// 
    /// #### Enum
    /// 
    ///     axis
    /// 
    /// ### discrete
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     number of steps
    /// 
    /// 
    pub fn next_axis_discrete(self: *const wl_pointer) !?struct {axis: u32, discrete: i32, } {
        return try self.runtime.next(self.object_id, 8, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_axis_discrete)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # axis_value120
    /// 
    /// ## Summary
    /// 
    ///     axis high-resolution scroll event
    /// 
    /// ## Description
    /// 
    ///     Discrete high-resolution scroll information.
    /// 
    ///     This event carries high-resolution wheel scroll information,
    ///     with each multiple of 120 representing one logical scroll step
    ///     (a wheel detent). For example, an axis_value120 of 30 is one quarter of
    ///     a logical scroll step in the positive direction, a value120 of
    ///     -240 are two logical scroll steps in the negative direction within the
    ///     same hardware event.
    ///     Clients that rely on discrete scrolling should accumulate the
    ///     value120 to multiples of 120 before processing the event.
    /// 
    ///     The value120 must not be zero.
    /// 
    ///     This event replaces the wl_pointer.axis_discrete event in clients
    ///     supporting wl_pointer version 8 or later.
    /// 
    ///     Where a wl_pointer.axis_source event occurs in the same
    ///     wl_pointer.frame, the axis source applies to this event.
    /// 
    ///     The order of wl_pointer.axis_value120 and wl_pointer.axis_source is
    ///     not guaranteed.
    ///       
    /// ## Args 
    /// 
    /// ### axis
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     axis type
    /// 
    /// #### Enum
    /// 
    ///     axis
    /// 
    /// ### value120
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     scroll distance as fraction of 120
    /// 
    /// 
    pub fn next_axis_value120(self: *const wl_pointer) !?struct {axis: u32, value120: i32, } {
        return try self.runtime.next(self.object_id, 9, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_axis_value120)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # axis_relative_direction
    /// 
    /// ## Summary
    /// 
    ///     axis relative physical direction event
    /// 
    /// ## Description
    /// 
    ///     Relative directional information of the entity causing the axis
    ///     motion.
    /// 
    ///     For a wl_pointer.axis event, the wl_pointer.axis_relative_direction
    ///     event specifies the movement direction of the entity causing the
    ///     wl_pointer.axis event. For example:
    ///     - if a user's fingers on a touchpad move down and this
    ///       causes a wl_pointer.axis vertical_scroll down event, the physical
    ///       direction is 'identical'
    ///     - if a user's fingers on a touchpad move down and this causes a
    ///       wl_pointer.axis vertical_scroll up scroll up event ('natural
    ///       scrolling'), the physical direction is 'inverted'.
    /// 
    ///     A client may use this information to adjust scroll motion of
    ///     components. Specifically, enabling natural scrolling causes the
    ///     content to change direction compared to traditional scrolling.
    ///     Some widgets like volume control sliders should usually match the
    ///     physical direction regardless of whether natural scrolling is
    ///     active. This event enables clients to match the scroll direction of
    ///     a widget to the physical direction.
    /// 
    ///     This event does not occur on its own, it is coupled with a
    ///     wl_pointer.axis event that represents this axis value.
    ///     The protocol guarantees that each axis_relative_direction event is
    ///     always followed by exactly one axis event with the same
    ///     axis number within the same wl_pointer.frame. Note that the protocol
    ///     allows for other events to occur between the axis_relative_direction
    ///     and its coupled axis event.
    /// 
    ///     The axis number is identical to the axis number in the associated
    ///     axis event.
    /// 
    ///     The order of wl_pointer.axis_relative_direction,
    ///     wl_pointer.axis_discrete and wl_pointer.axis_source is not
    ///     guaranteed.
    ///       
    /// ## Args 
    /// 
    /// ### axis
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     axis type
    /// 
    /// #### Enum
    /// 
    ///     axis
    /// 
    /// ### direction
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     physical direction relative to axis motion
    /// 
    /// #### Enum
    /// 
    ///     axis_relative_direction
    /// 
    /// 
    pub fn next_axis_relative_direction(self: *const wl_pointer) !?struct {axis: u32, direction: u32, } {
        return try self.runtime.next(self.object_id, 10, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_axis_relative_direction)).@"fn".return_type.?).error_union.payload).optional.child);
}
};

/// # wl_keyboard
/// 
/// ## Summary
/// 
///     keyboard input device
/// 
/// ## Description
/// 
///       The wl_keyboard interface represents one or more keyboards
///       associated with a seat.
/// 
///       Each wl_keyboard has the following logical state:
/// 
///       - an active surface (possibly null),
///       - the keys currently logically down,
///       - the active modifiers,
///       - the active group.
/// 
///       By default, the active surface is null, the keys currently logically down
///       are empty, the active modifiers and the active group are 0.
///     
pub const wl_keyboard = struct {
    pub const interface = "wl_keyboard";
    pub const version = 9;

    pub const enums = struct{
        /// # keymap_format
        /// 
        /// ## Summary
        /// 
        ///     keyboard mapping format
        /// 
        /// ## Description
        /// 
        ///     This specifies the format of the keymap provided to the
        ///     client with the wl_keyboard.keymap event.
        ///       
        pub const keymap_format = enum(u32) {
            no_keymap = 0,
            xkb_v1 = 1,
        };

        /// # key_state
        /// 
        /// ## Summary
        /// 
        ///     physical key state
        /// 
        /// ## Description
        /// 
        ///     Describes the physical state of a key that produced the key event.
        ///       
        pub const key_state = enum(u32) {
            released = 0,
            pressed = 1,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # release
    /// 
    /// release the keyboard object
    /// ## Args 
    /// 
    /// 
    pub fn release(self: *const wl_keyboard) !void {
        try self.runtime.sendRequest(self.object_id, 0, .{});
    }

    /// # keymap
    /// 
    /// ## Summary
    /// 
    ///     keyboard mapping
    /// 
    /// ## Description
    /// 
    ///     This event provides a file descriptor to the client which can be
    ///     memory-mapped in read-only mode to provide a keyboard mapping
    ///     description.
    /// 
    ///     From version 7 onwards, the fd must be mapped with MAP_PRIVATE by
    ///     the recipient, as MAP_SHARED may fail.
    ///       
    /// ## Args 
    /// 
    /// ### format
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     keymap format
    /// 
    /// #### Enum
    /// 
    ///     keymap_format
    /// 
    /// ### fd
    /// 
    /// #### Type
    /// 
    ///     fd
    /// 
    /// #### Summary
    /// 
    ///     keymap file descriptor
    /// 
    /// ### size
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     keymap size, in bytes
    /// 
    /// 
    pub fn next_keymap(self: *const wl_keyboard) !?struct {format: u32, fd: types.Fd, size: u32, } {
        return try self.runtime.next(self.object_id, 0, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_keymap)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # enter
    /// 
    /// ## Summary
    /// 
    ///     enter event
    /// 
    /// ## Description
    /// 
    ///     Notification that this seat's keyboard focus is on a certain
    ///     surface.
    /// 
    ///     The compositor must send the wl_keyboard.modifiers event after this
    ///     event.
    /// 
    ///     In the wl_keyboard logical state, this event sets the active surface to
    ///     the surface argument and the keys currently logically down to the keys
    ///     in the keys argument. The compositor must not send this event if the
    ///     wl_keyboard already had an active surface immediately before this event.
    ///       
    /// ## Args 
    /// 
    /// ### serial
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     serial number of the enter event
    /// 
    /// ### surface
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     surface gaining keyboard focus
    /// 
    /// #### Interface
    /// 
    ///     wl_surface
    /// 
    /// ### keys
    /// 
    /// #### Type
    /// 
    ///     array
    /// 
    /// #### Summary
    /// 
    ///     the keys currently logically down
    /// 
    /// 
    pub fn next_enter(self: *const wl_keyboard) !?struct {serial: u32, surface: types.ObjectId, keys: std.ArrayList(u8), } {
        return try self.runtime.next(self.object_id, 1, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_enter)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # leave
    /// 
    /// ## Summary
    /// 
    ///     leave event
    /// 
    /// ## Description
    /// 
    ///     Notification that this seat's keyboard focus is no longer on
    ///     a certain surface.
    /// 
    ///     The leave notification is sent before the enter notification
    ///     for the new focus.
    /// 
    ///     In the wl_keyboard logical state, this event resets all values to their
    ///     defaults. The compositor must not send this event if the active surface
    ///     of the wl_keyboard was not equal to the surface argument immediately
    ///     before this event.
    ///       
    /// ## Args 
    /// 
    /// ### serial
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     serial number of the leave event
    /// 
    /// ### surface
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     surface that lost keyboard focus
    /// 
    /// #### Interface
    /// 
    ///     wl_surface
    /// 
    /// 
    pub fn next_leave(self: *const wl_keyboard) !?struct {serial: u32, surface: types.ObjectId, } {
        return try self.runtime.next(self.object_id, 2, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_leave)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # key
    /// 
    /// ## Summary
    /// 
    ///     key event
    /// 
    /// ## Description
    /// 
    ///     A key was pressed or released.
    ///     The time argument is a timestamp with millisecond
    ///     granularity, with an undefined base.
    /// 
    ///     The key is a platform-specific key code that can be interpreted
    ///     by feeding it to the keyboard mapping (see the keymap event).
    /// 
    ///     If this event produces a change in modifiers, then the resulting
    ///     wl_keyboard.modifiers event must be sent after this event.
    /// 
    ///     In the wl_keyboard logical state, this event adds the key to the keys
    ///     currently logically down (if the state argument is pressed) or removes
    ///     the key from the keys currently logically down (if the state argument is
    ///     released). The compositor must not send this event if the wl_keyboard
    ///     did not have an active surface immediately before this event. The
    ///     compositor must not send this event if state is pressed (resp. released)
    ///     and the key was already logically down (resp. was not logically down)
    ///     immediately before this event.
    ///       
    /// ## Args 
    /// 
    /// ### serial
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     serial number of the key event
    /// 
    /// ### time
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     timestamp with millisecond granularity
    /// 
    /// ### key
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     key that produced the event
    /// 
    /// ### state
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     physical state of the key
    /// 
    /// #### Enum
    /// 
    ///     key_state
    /// 
    /// 
    pub fn next_key(self: *const wl_keyboard) !?struct {serial: u32, time: u32, key: u32, state: u32, } {
        return try self.runtime.next(self.object_id, 3, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_key)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # modifiers
    /// 
    /// ## Summary
    /// 
    ///     modifier and group state
    /// 
    /// ## Description
    /// 
    ///     Notifies clients that the modifier and/or group state has
    ///     changed, and it should update its local state.
    /// 
    ///     The compositor may send this event without a surface of the client
    ///     having keyboard focus, for example to tie modifier information to
    ///     pointer focus instead. If a modifier event with pressed modifiers is sent
    ///     without a prior enter event, the client can assume the modifier state is
    ///     valid until it receives the next wl_keyboard.modifiers event. In order to
    ///     reset the modifier state again, the compositor can send a
    ///     wl_keyboard.modifiers event with no pressed modifiers.
    /// 
    ///     In the wl_keyboard logical state, this event updates the modifiers and
    ///     group.
    ///       
    /// ## Args 
    /// 
    /// ### serial
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     serial number of the modifiers event
    /// 
    /// ### mods_depressed
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     depressed modifiers
    /// 
    /// ### mods_latched
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     latched modifiers
    /// 
    /// ### mods_locked
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     locked modifiers
    /// 
    /// ### group
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     keyboard layout
    /// 
    /// 
    pub fn next_modifiers(self: *const wl_keyboard) !?struct {serial: u32, mods_depressed: u32, mods_latched: u32, mods_locked: u32, group: u32, } {
        return try self.runtime.next(self.object_id, 4, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_modifiers)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # repeat_info
    /// 
    /// ## Summary
    /// 
    ///     repeat rate and delay
    /// 
    /// ## Description
    /// 
    ///     Informs the client about the keyboard's repeat rate and delay.
    /// 
    ///     This event is sent as soon as the wl_keyboard object has been created,
    ///     and is guaranteed to be received by the client before any key press
    ///     event.
    /// 
    ///     Negative values for either rate or delay are illegal. A rate of zero
    ///     will disable any repeating (regardless of the value of delay).
    /// 
    ///     This event can be sent later on as well with a new value if necessary,
    ///     so clients should continue listening for the event past the creation
    ///     of wl_keyboard.
    ///       
    /// ## Args 
    /// 
    /// ### rate
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     the rate of repeating keys in characters per second
    /// 
    /// ### delay
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     delay in milliseconds since key down until repeating starts
    /// 
    /// 
    pub fn next_repeat_info(self: *const wl_keyboard) !?struct {rate: i32, delay: i32, } {
        return try self.runtime.next(self.object_id, 5, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_repeat_info)).@"fn".return_type.?).error_union.payload).optional.child);
}
};

/// # wl_touch
/// 
/// ## Summary
/// 
///     touchscreen input device
/// 
/// ## Description
/// 
///       The wl_touch interface represents a touchscreen
///       associated with a seat.
/// 
///       Touch interactions can consist of one or more contacts.
///       For each contact, a series of events is generated, starting
///       with a down event, followed by zero or more motion events,
///       and ending with an up event. Events relating to the same
///       contact point can be identified by the ID of the sequence.
///     
pub const wl_touch = struct {
    pub const interface = "wl_touch";
    pub const version = 9;

    pub const enums = struct{    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # release
    /// 
    /// release the touch object
    /// ## Args 
    /// 
    /// 
    pub fn release(self: *const wl_touch) !void {
        try self.runtime.sendRequest(self.object_id, 0, .{});
    }

    /// # down
    /// 
    /// ## Summary
    /// 
    ///     touch down event and beginning of a touch sequence
    /// 
    /// ## Description
    /// 
    ///     A new touch point has appeared on the surface. This touch point is
    ///     assigned a unique ID. Future events from this touch point reference
    ///     this ID. The ID ceases to be valid after a touch up event and may be
    ///     reused in the future.
    ///       
    /// ## Args 
    /// 
    /// ### serial
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     serial number of the touch down event
    /// 
    /// ### time
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     timestamp with millisecond granularity
    /// 
    /// ### surface
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     surface touched
    /// 
    /// #### Interface
    /// 
    ///     wl_surface
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     the unique ID of this touch point
    /// 
    /// ### x
    /// 
    /// #### Type
    /// 
    ///     fixed
    /// 
    /// #### Summary
    /// 
    ///     surface-local x coordinate
    /// 
    /// ### y
    /// 
    /// #### Type
    /// 
    ///     fixed
    /// 
    /// #### Summary
    /// 
    ///     surface-local y coordinate
    /// 
    /// 
    pub fn next_down(self: *const wl_touch) !?struct {serial: u32, time: u32, surface: types.ObjectId, id: i32, x: types.Fixed, y: types.Fixed, } {
        return try self.runtime.next(self.object_id, 0, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_down)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # up
    /// 
    /// ## Summary
    /// 
    ///     end of a touch event sequence
    /// 
    /// ## Description
    /// 
    ///     The touch point has disappeared. No further events will be sent for
    ///     this touch point and the touch point's ID is released and may be
    ///     reused in a future touch down event.
    ///       
    /// ## Args 
    /// 
    /// ### serial
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     serial number of the touch up event
    /// 
    /// ### time
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     timestamp with millisecond granularity
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     the unique ID of this touch point
    /// 
    /// 
    pub fn next_up(self: *const wl_touch) !?struct {serial: u32, time: u32, id: i32, } {
        return try self.runtime.next(self.object_id, 1, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_up)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # motion
    /// 
    /// ## Summary
    /// 
    ///     update of touch point coordinates
    /// 
    /// ## Description
    /// 
    ///     A touch point has changed coordinates.
    ///       
    /// ## Args 
    /// 
    /// ### time
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     timestamp with millisecond granularity
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     the unique ID of this touch point
    /// 
    /// ### x
    /// 
    /// #### Type
    /// 
    ///     fixed
    /// 
    /// #### Summary
    /// 
    ///     surface-local x coordinate
    /// 
    /// ### y
    /// 
    /// #### Type
    /// 
    ///     fixed
    /// 
    /// #### Summary
    /// 
    ///     surface-local y coordinate
    /// 
    /// 
    pub fn next_motion(self: *const wl_touch) !?struct {time: u32, id: i32, x: types.Fixed, y: types.Fixed, } {
        return try self.runtime.next(self.object_id, 2, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_motion)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # frame
    /// 
    /// ## Summary
    /// 
    ///     end of touch frame event
    /// 
    /// ## Description
    /// 
    ///     Indicates the end of a set of events that logically belong together.
    ///     A client is expected to accumulate the data in all events within the
    ///     frame before proceeding.
    /// 
    ///     A wl_touch.frame terminates at least one event but otherwise no
    ///     guarantee is provided about the set of events within a frame. A client
    ///     must assume that any state not updated in a frame is unchanged from the
    ///     previously known state.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn next_frame(self: *const wl_touch) !?struct {} {
        return try self.runtime.next(self.object_id, 3, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_frame)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # cancel
    /// 
    /// ## Summary
    /// 
    ///     touch session cancelled
    /// 
    /// ## Description
    /// 
    ///     Sent if the compositor decides the touch stream is a global
    ///     gesture. No further events are sent to the clients from that
    ///     particular gesture. Touch cancellation applies to all touch points
    ///     currently active on this client's surface. The client is
    ///     responsible for finalizing the touch points, future touch points on
    ///     this surface may reuse the touch point ID.
    /// 
    ///     No frame event is required after the cancel event.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn next_cancel(self: *const wl_touch) !?struct {} {
        return try self.runtime.next(self.object_id, 4, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_cancel)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # shape
    /// 
    /// ## Summary
    /// 
    ///     update shape of touch point
    /// 
    /// ## Description
    /// 
    ///     Sent when a touchpoint has changed its shape.
    /// 
    ///     This event does not occur on its own. It is sent before a
    ///     wl_touch.frame event and carries the new shape information for
    ///     any previously reported, or new touch points of that frame.
    /// 
    ///     Other events describing the touch point such as wl_touch.down,
    ///     wl_touch.motion or wl_touch.orientation may be sent within the
    ///     same wl_touch.frame. A client should treat these events as a single
    ///     logical touch point update. The order of wl_touch.shape,
    ///     wl_touch.orientation and wl_touch.motion is not guaranteed.
    ///     A wl_touch.down event is guaranteed to occur before the first
    ///     wl_touch.shape event for this touch ID but both events may occur within
    ///     the same wl_touch.frame.
    /// 
    ///     A touchpoint shape is approximated by an ellipse through the major and
    ///     minor axis length. The major axis length describes the longer diameter
    ///     of the ellipse, while the minor axis length describes the shorter
    ///     diameter. Major and minor are orthogonal and both are specified in
    ///     surface-local coordinates. The center of the ellipse is always at the
    ///     touchpoint location as reported by wl_touch.down or wl_touch.move.
    /// 
    ///     This event is only sent by the compositor if the touch device supports
    ///     shape reports. The client has to make reasonable assumptions about the
    ///     shape if it did not receive this event.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     the unique ID of this touch point
    /// 
    /// ### major
    /// 
    /// #### Type
    /// 
    ///     fixed
    /// 
    /// #### Summary
    /// 
    ///     length of the major axis in surface-local coordinates
    /// 
    /// ### minor
    /// 
    /// #### Type
    /// 
    ///     fixed
    /// 
    /// #### Summary
    /// 
    ///     length of the minor axis in surface-local coordinates
    /// 
    /// 
    pub fn next_shape(self: *const wl_touch) !?struct {id: i32, major: types.Fixed, minor: types.Fixed, } {
        return try self.runtime.next(self.object_id, 5, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_shape)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # orientation
    /// 
    /// ## Summary
    /// 
    ///     update orientation of touch point
    /// 
    /// ## Description
    /// 
    ///     Sent when a touchpoint has changed its orientation.
    /// 
    ///     This event does not occur on its own. It is sent before a
    ///     wl_touch.frame event and carries the new shape information for
    ///     any previously reported, or new touch points of that frame.
    /// 
    ///     Other events describing the touch point such as wl_touch.down,
    ///     wl_touch.motion or wl_touch.shape may be sent within the
    ///     same wl_touch.frame. A client should treat these events as a single
    ///     logical touch point update. The order of wl_touch.shape,
    ///     wl_touch.orientation and wl_touch.motion is not guaranteed.
    ///     A wl_touch.down event is guaranteed to occur before the first
    ///     wl_touch.orientation event for this touch ID but both events may occur
    ///     within the same wl_touch.frame.
    /// 
    ///     The orientation describes the clockwise angle of a touchpoint's major
    ///     axis to the positive surface y-axis and is normalized to the -180 to
    ///     +180 degree range. The granularity of orientation depends on the touch
    ///     device, some devices only support binary rotation values between 0 and
    ///     90 degrees.
    /// 
    ///     This event is only sent by the compositor if the touch device supports
    ///     orientation reports.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     the unique ID of this touch point
    /// 
    /// ### orientation
    /// 
    /// #### Type
    /// 
    ///     fixed
    /// 
    /// #### Summary
    /// 
    ///     angle between major axis and positive surface y-axis in degrees
    /// 
    /// 
    pub fn next_orientation(self: *const wl_touch) !?struct {id: i32, orientation: types.Fixed, } {
        return try self.runtime.next(self.object_id, 6, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_orientation)).@"fn".return_type.?).error_union.payload).optional.child);
}
};

/// # wl_output
/// 
/// ## Summary
/// 
///     compositor output region
/// 
/// ## Description
/// 
///       An output describes part of the compositor geometry.  The
///       compositor works in the 'compositor coordinate system' and an
///       output corresponds to a rectangular area in that space that is
///       actually visible.  This typically corresponds to a monitor that
///       displays part of the compositor space.  This object is published
///       as global during start up, or when a monitor is hotplugged.
///     
pub const wl_output = struct {
    pub const interface = "wl_output";
    pub const version = 4;

    pub const enums = struct{
        /// # subpixel
        /// 
        /// ## Summary
        /// 
        ///     subpixel geometry information
        /// 
        /// ## Description
        /// 
        ///     This enumeration describes how the physical
        ///     pixels on an output are laid out.
        ///       
        pub const subpixel = enum(u32) {
            unknown = 0,
            none = 1,
            horizontal_rgb = 2,
            horizontal_bgr = 3,
            vertical_rgb = 4,
            vertical_bgr = 5,
        };

        /// # transform
        /// 
        /// ## Summary
        /// 
        ///     transformation applied to buffer contents
        /// 
        /// ## Description
        /// 
        ///     This describes transformations that clients and compositors apply to
        ///     buffer contents.
        /// 
        ///     The flipped values correspond to an initial flip around a
        ///     vertical axis followed by rotation.
        /// 
        ///     The purpose is mainly to allow clients to render accordingly and
        ///     tell the compositor, so that for fullscreen surfaces, the
        ///     compositor will still be able to scan out directly from client
        ///     surfaces.
        ///       
        pub const transform = enum(u32) {
            normal = 0,
            @"90" = 1,
            @"180" = 2,
            @"270" = 3,
            flipped = 4,
            flipped_90 = 5,
            flipped_180 = 6,
            flipped_270 = 7,
        };

        /// # mode
        /// 
        /// ## Summary
        /// 
        ///     mode information
        /// 
        /// ## Description
        /// 
        ///     These flags describe properties of an output mode.
        ///     They are used in the flags bitfield of the mode event.
        ///       
        pub const mode = enum(u32) {
            current = 0x1,
            preferred = 0x2,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # release
    /// 
    /// ## Summary
    /// 
    ///     release the output object
    /// 
    /// ## Description
    /// 
    ///     Using this request a client can tell the server that it is not going to
    ///     use the output object anymore.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn release(self: *const wl_output) !void {
        try self.runtime.sendRequest(self.object_id, 0, .{});
    }

    /// # geometry
    /// 
    /// ## Summary
    /// 
    ///     properties of the output
    /// 
    /// ## Description
    /// 
    ///     The geometry event describes geometric properties of the output.
    ///     The event is sent when binding to the output object and whenever
    ///     any of the properties change.
    /// 
    ///     The physical size can be set to zero if it doesn't make sense for this
    ///     output (e.g. for projectors or virtual outputs).
    /// 
    ///     The geometry event will be followed by a done event (starting from
    ///     version 2).
    /// 
    ///     Clients should use wl_surface.preferred_buffer_transform instead of the
    ///     transform advertised by this event to find the preferred buffer
    ///     transform to use for a surface.
    /// 
    ///     Note: wl_output only advertises partial information about the output
    ///     position and identification. Some compositors, for instance those not
    ///     implementing a desktop-style output layout or those exposing virtual
    ///     outputs, might fake this information. Instead of using x and y, clients
    ///     should use xdg_output.logical_position. Instead of using make and model,
    ///     clients should use name and description.
    ///       
    /// ## Args 
    /// 
    /// ### x
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     x position within the global compositor space
    /// 
    /// ### y
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     y position within the global compositor space
    /// 
    /// ### physical_width
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     width in millimeters of the output
    /// 
    /// ### physical_height
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     height in millimeters of the output
    /// 
    /// ### subpixel
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     subpixel orientation of the output
    /// 
    /// #### Enum
    /// 
    ///     subpixel
    /// 
    /// ### make
    /// 
    /// #### Type
    /// 
    ///     string
    /// 
    /// #### Summary
    /// 
    ///     textual description of the manufacturer
    /// 
    /// ### model
    /// 
    /// #### Type
    /// 
    ///     string
    /// 
    /// #### Summary
    /// 
    ///     textual description of the model
    /// 
    /// ### transform
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     additional transformation applied to buffer contents during presentation
    /// 
    /// #### Enum
    /// 
    ///     transform
    /// 
    /// 
    pub fn next_geometry(self: *const wl_output) !?struct {x: i32, y: i32, physical_width: i32, physical_height: i32, subpixel: i32, make: types.String, model: types.String, transform: i32, } {
        return try self.runtime.next(self.object_id, 0, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_geometry)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # mode
    /// 
    /// ## Summary
    /// 
    ///     advertise available modes for the output
    /// 
    /// ## Description
    /// 
    ///     The mode event describes an available mode for the output.
    /// 
    ///     The event is sent when binding to the output object and there
    ///     will always be one mode, the current mode.  The event is sent
    ///     again if an output changes mode, for the mode that is now
    ///     current.  In other words, the current mode is always the last
    ///     mode that was received with the current flag set.
    /// 
    ///     Non-current modes are deprecated. A compositor can decide to only
    ///     advertise the current mode and never send other modes. Clients
    ///     should not rely on non-current modes.
    /// 
    ///     The size of a mode is given in physical hardware units of
    ///     the output device. This is not necessarily the same as
    ///     the output size in the global compositor space. For instance,
    ///     the output may be scaled, as described in wl_output.scale,
    ///     or transformed, as described in wl_output.transform. Clients
    ///     willing to retrieve the output size in the global compositor
    ///     space should use xdg_output.logical_size instead.
    /// 
    ///     The vertical refresh rate can be set to zero if it doesn't make
    ///     sense for this output (e.g. for virtual outputs).
    /// 
    ///     The mode event will be followed by a done event (starting from
    ///     version 2).
    /// 
    ///     Clients should not use the refresh rate to schedule frames. Instead,
    ///     they should use the wl_surface.frame event or the presentation-time
    ///     protocol.
    /// 
    ///     Note: this information is not always meaningful for all outputs. Some
    ///     compositors, such as those exposing virtual outputs, might fake the
    ///     refresh rate or the size.
    ///       
    /// ## Args 
    /// 
    /// ### flags
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     bitfield of mode flags
    /// 
    /// #### Enum
    /// 
    ///     mode
    /// 
    /// ### width
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     width of the mode in hardware units
    /// 
    /// ### height
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     height of the mode in hardware units
    /// 
    /// ### refresh
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     vertical refresh rate in mHz
    /// 
    /// 
    pub fn next_mode(self: *const wl_output) !?struct {flags: u32, width: i32, height: i32, refresh: i32, } {
        return try self.runtime.next(self.object_id, 1, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_mode)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # done
    /// 
    /// ## Summary
    /// 
    ///     sent all information about output
    /// 
    /// ## Description
    /// 
    ///     This event is sent after all other properties have been
    ///     sent after binding to the output object and after any
    ///     other property changes done after that. This allows
    ///     changes to the output properties to be seen as
    ///     atomic, even if they happen via multiple events.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn next_done(self: *const wl_output) !?struct {} {
        return try self.runtime.next(self.object_id, 2, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_done)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # scale
    /// 
    /// ## Summary
    /// 
    ///     output scaling properties
    /// 
    /// ## Description
    /// 
    ///     This event contains scaling geometry information
    ///     that is not in the geometry event. It may be sent after
    ///     binding the output object or if the output scale changes
    ///     later. The compositor will emit a non-zero, positive
    ///     value for scale. If it is not sent, the client should
    ///     assume a scale of 1.
    /// 
    ///     A scale larger than 1 means that the compositor will
    ///     automatically scale surface buffers by this amount
    ///     when rendering. This is used for very high resolution
    ///     displays where applications rendering at the native
    ///     resolution would be too small to be legible.
    /// 
    ///     Clients should use wl_surface.preferred_buffer_scale
    ///     instead of this event to find the preferred buffer
    ///     scale to use for a surface.
    /// 
    ///     The scale event will be followed by a done event.
    ///       
    /// ## Args 
    /// 
    /// ### factor
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     scaling factor of output
    /// 
    /// 
    pub fn next_scale(self: *const wl_output) !?struct {factor: i32, } {
        return try self.runtime.next(self.object_id, 3, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_scale)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # name
    /// 
    /// ## Summary
    /// 
    ///     name of this output
    /// 
    /// ## Description
    /// 
    ///     Many compositors will assign user-friendly names to their outputs, show
    ///     them to the user, allow the user to refer to an output, etc. The client
    ///     may wish to know this name as well to offer the user similar behaviors.
    /// 
    ///     The name is a UTF-8 string with no convention defined for its contents.
    ///     Each name is unique among all wl_output globals. The name is only
    ///     guaranteed to be unique for the compositor instance.
    /// 
    ///     The same output name is used for all clients for a given wl_output
    ///     global. Thus, the name can be shared across processes to refer to a
    ///     specific wl_output global.
    /// 
    ///     The name is not guaranteed to be persistent across sessions, thus cannot
    ///     be used to reliably identify an output in e.g. configuration files.
    /// 
    ///     Examples of names include 'HDMI-A-1', 'WL-1', 'X11-1', etc. However, do
    ///     not assume that the name is a reflection of an underlying DRM connector,
    ///     X11 connection, etc.
    /// 
    ///     The name event is sent after binding the output object. This event is
    ///     only sent once per output object, and the name does not change over the
    ///     lifetime of the wl_output global.
    /// 
    ///     Compositors may re-use the same output name if the wl_output global is
    ///     destroyed and re-created later. Compositors should avoid re-using the
    ///     same name if possible.
    /// 
    ///     The name event will be followed by a done event.
    ///       
    /// ## Args 
    /// 
    /// ### name
    /// 
    /// #### Type
    /// 
    ///     string
    /// 
    /// #### Summary
    /// 
    ///     output name
    /// 
    /// 
    pub fn next_name(self: *const wl_output) !?struct {name: types.String, } {
        return try self.runtime.next(self.object_id, 4, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_name)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # description
    /// 
    /// ## Summary
    /// 
    ///     human-readable description of this output
    /// 
    /// ## Description
    /// 
    ///     Many compositors can produce human-readable descriptions of their
    ///     outputs. The client may wish to know this description as well, e.g. for
    ///     output selection purposes.
    /// 
    ///     The description is a UTF-8 string with no convention defined for its
    ///     contents. The description is not guaranteed to be unique among all
    ///     wl_output globals. Examples might include 'Foocorp 11" Display' or
    ///     'Virtual X11 output via :1'.
    /// 
    ///     The description event is sent after binding the output object and
    ///     whenever the description changes. The description is optional, and may
    ///     not be sent at all.
    /// 
    ///     The description event will be followed by a done event.
    ///       
    /// ## Args 
    /// 
    /// ### description
    /// 
    /// #### Type
    /// 
    ///     string
    /// 
    /// #### Summary
    /// 
    ///     output description
    /// 
    /// 
    pub fn next_description(self: *const wl_output) !?struct {description: types.String, } {
        return try self.runtime.next(self.object_id, 5, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_description)).@"fn".return_type.?).error_union.payload).optional.child);
}
};

/// # wl_region
/// 
/// ## Summary
/// 
///     region interface
/// 
/// ## Description
/// 
///       A region object describes an area.
/// 
///       Region objects are used to describe the opaque and input
///       regions of a surface.
///     
pub const wl_region = struct {
    pub const interface = "wl_region";
    pub const version = 1;

    pub const enums = struct{    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # destroy
    /// 
    /// ## Summary
    /// 
    ///     destroy region
    /// 
    /// ## Description
    /// 
    ///     Destroy the region.  This will invalidate the object ID.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn destroy(self: *const wl_region) !void {
        try self.runtime.sendRequest(self.object_id, 0, .{});
    }

    /// # add
    /// 
    /// ## Summary
    /// 
    ///     add rectangle to region
    /// 
    /// ## Description
    /// 
    ///     Add the specified rectangle to the region.
    ///       
    /// ## Args 
    /// 
    /// ### x
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     region-local x coordinate
    /// 
    /// ### y
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     region-local y coordinate
    /// 
    /// ### width
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     rectangle width
    /// 
    /// ### height
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     rectangle height
    /// 
    /// 
    pub fn add(self: *const wl_region, x: i32, y: i32, width: i32, height: i32) !void {
        try self.runtime.sendRequest(self.object_id, 1, .{x, y, width, height, });
    }

    /// # subtract
    /// 
    /// ## Summary
    /// 
    ///     subtract rectangle from region
    /// 
    /// ## Description
    /// 
    ///     Subtract the specified rectangle from the region.
    ///       
    /// ## Args 
    /// 
    /// ### x
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     region-local x coordinate
    /// 
    /// ### y
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     region-local y coordinate
    /// 
    /// ### width
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     rectangle width
    /// 
    /// ### height
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     rectangle height
    /// 
    /// 
    pub fn subtract(self: *const wl_region, x: i32, y: i32, width: i32, height: i32) !void {
        try self.runtime.sendRequest(self.object_id, 2, .{x, y, width, height, });
    }
};

/// # wl_subcompositor
/// 
/// ## Summary
/// 
///     sub-surface compositing
/// 
/// ## Description
/// 
///       The global interface exposing sub-surface compositing capabilities.
///       A wl_surface, that has sub-surfaces associated, is called the
///       parent surface. Sub-surfaces can be arbitrarily nested and create
///       a tree of sub-surfaces.
/// 
///       The root surface in a tree of sub-surfaces is the main
///       surface. The main surface cannot be a sub-surface, because
///       sub-surfaces must always have a parent.
/// 
///       A main surface with its sub-surfaces forms a (compound) window.
///       For window management purposes, this set of wl_surface objects is
///       to be considered as a single window, and it should also behave as
///       such.
/// 
///       The aim of sub-surfaces is to offload some of the compositing work
///       within a window from clients to the compositor. A prime example is
///       a video player with decorations and video in separate wl_surface
///       objects. This should allow the compositor to pass YUV video buffer
///       processing to dedicated overlay hardware when possible.
///     
pub const wl_subcompositor = struct {
    pub const interface = "wl_subcompositor";
    pub const version = 1;

    pub const enums = struct{
        pub const @"error" = enum(u32) {
            bad_surface = 0,
            bad_parent = 1,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # destroy
    /// 
    /// ## Summary
    /// 
    ///     unbind from the subcompositor interface
    /// 
    /// ## Description
    /// 
    ///     Informs the server that the client will not be using this
    ///     protocol object anymore. This does not affect any other
    ///     objects, wl_subsurface objects included.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn destroy(self: *const wl_subcompositor) !void {
        try self.runtime.sendRequest(self.object_id, 0, .{});
    }

    /// # get_subsurface
    /// 
    /// ## Summary
    /// 
    ///     give a surface the role sub-surface
    /// 
    /// ## Description
    /// 
    ///     Create a sub-surface interface for the given surface, and
    ///     associate it with the given parent surface. This turns a
    ///     plain wl_surface into a sub-surface.
    /// 
    ///     The to-be sub-surface must not already have another role, and it
    ///     must not have an existing wl_subsurface object. Otherwise the
    ///     bad_surface protocol error is raised.
    /// 
    ///     Adding sub-surfaces to a parent is a double-buffered operation on the
    ///     parent (see wl_surface.commit). The effect of adding a sub-surface
    ///     becomes visible on the next time the state of the parent surface is
    ///     applied.
    /// 
    ///     The parent surface must not be one of the child surface's descendants,
    ///     and the parent must be different from the child surface, otherwise the
    ///     bad_parent protocol error is raised.
    /// 
    ///     This request modifies the behaviour of wl_surface.commit request on
    ///     the sub-surface, see the documentation on wl_subsurface interface.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Summary
    /// 
    ///     the new sub-surface object ID
    /// 
    /// #### Interface
    /// 
    ///     wl_subsurface
    /// 
    /// ### surface
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     the surface to be turned into a sub-surface
    /// 
    /// #### Interface
    /// 
    ///     wl_surface
    /// 
    /// ### parent
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     the parent surface
    /// 
    /// #### Interface
    /// 
    ///     wl_surface
    /// 
    /// 
    pub fn get_subsurface(self: *const wl_subcompositor, surface: types.ObjectId, parent: types.ObjectId) !struct { id: wl_subsurface, } {
        const id_id = self.runtime.getId();
        try self.runtime.sendRequest(self.object_id, 1, .{id_id, surface, parent, });
        return .{.id = wl_subsurface{.object_id = id_id, .runtime = self.runtime}, };
    }
};

/// # wl_subsurface
/// 
/// ## Summary
/// 
///     sub-surface interface to a wl_surface
/// 
/// ## Description
/// 
///       An additional interface to a wl_surface object, which has been
///       made a sub-surface. A sub-surface has one parent surface. A
///       sub-surface's size and position are not limited to that of the parent.
///       Particularly, a sub-surface is not automatically clipped to its
///       parent's area.
/// 
///       A sub-surface becomes mapped, when a non-NULL wl_buffer is applied
///       and the parent surface is mapped. The order of which one happens
///       first is irrelevant. A sub-surface is hidden if the parent becomes
///       hidden, or if a NULL wl_buffer is applied. These rules apply
///       recursively through the tree of surfaces.
/// 
///       The behaviour of a wl_surface.commit request on a sub-surface
///       depends on the sub-surface's mode. The possible modes are
///       synchronized and desynchronized, see methods
///       wl_subsurface.set_sync and wl_subsurface.set_desync. Synchronized
///       mode caches the wl_surface state to be applied when the parent's
///       state gets applied, and desynchronized mode applies the pending
///       wl_surface state directly. A sub-surface is initially in the
///       synchronized mode.
/// 
///       Sub-surfaces also have another kind of state, which is managed by
///       wl_subsurface requests, as opposed to wl_surface requests. This
///       state includes the sub-surface position relative to the parent
///       surface (wl_subsurface.set_position), and the stacking order of
///       the parent and its sub-surfaces (wl_subsurface.place_above and
///       .place_below). This state is applied when the parent surface's
///       wl_surface state is applied, regardless of the sub-surface's mode.
///       As the exception, set_sync and set_desync are effective immediately.
/// 
///       The main surface can be thought to be always in desynchronized mode,
///       since it does not have a parent in the sub-surfaces sense.
/// 
///       Even if a sub-surface is in desynchronized mode, it will behave as
///       in synchronized mode, if its parent surface behaves as in
///       synchronized mode. This rule is applied recursively throughout the
///       tree of surfaces. This means, that one can set a sub-surface into
///       synchronized mode, and then assume that all its child and grand-child
///       sub-surfaces are synchronized, too, without explicitly setting them.
/// 
///       Destroying a sub-surface takes effect immediately. If you need to
///       synchronize the removal of a sub-surface to the parent surface update,
///       unmap the sub-surface first by attaching a NULL wl_buffer, update parent,
///       and then destroy the sub-surface.
/// 
///       If the parent wl_surface object is destroyed, the sub-surface is
///       unmapped.
/// 
///       A sub-surface never has the keyboard focus of any seat.
/// 
///       The wl_surface.offset request is ignored: clients must use set_position
///       instead to move the sub-surface.
///     
pub const wl_subsurface = struct {
    pub const interface = "wl_subsurface";
    pub const version = 1;

    pub const enums = struct{
        pub const @"error" = enum(u32) {
            bad_surface = 0,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # destroy
    /// 
    /// ## Summary
    /// 
    ///     remove sub-surface interface
    /// 
    /// ## Description
    /// 
    ///     The sub-surface interface is removed from the wl_surface object
    ///     that was turned into a sub-surface with a
    ///     wl_subcompositor.get_subsurface request. The wl_surface's association
    ///     to the parent is deleted. The wl_surface is unmapped immediately.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn destroy(self: *const wl_subsurface) !void {
        try self.runtime.sendRequest(self.object_id, 0, .{});
    }

    /// # set_position
    /// 
    /// ## Summary
    /// 
    ///     reposition the sub-surface
    /// 
    /// ## Description
    /// 
    ///     This schedules a sub-surface position change.
    ///     The sub-surface will be moved so that its origin (top left
    ///     corner pixel) will be at the location x, y of the parent surface
    ///     coordinate system. The coordinates are not restricted to the parent
    ///     surface area. Negative values are allowed.
    /// 
    ///     The scheduled coordinates will take effect whenever the state of the
    ///     parent surface is applied.
    /// 
    ///     If more than one set_position request is invoked by the client before
    ///     the commit of the parent surface, the position of a new request always
    ///     replaces the scheduled position from any previous request.
    /// 
    ///     The initial position is 0, 0.
    ///       
    /// ## Args 
    /// 
    /// ### x
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     x coordinate in the parent surface
    /// 
    /// ### y
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     y coordinate in the parent surface
    /// 
    /// 
    pub fn set_position(self: *const wl_subsurface, x: i32, y: i32) !void {
        try self.runtime.sendRequest(self.object_id, 1, .{x, y, });
    }

    /// # place_above
    /// 
    /// ## Summary
    /// 
    ///     restack the sub-surface
    /// 
    /// ## Description
    /// 
    ///     This sub-surface is taken from the stack, and put back just
    ///     above the reference surface, changing the z-order of the sub-surfaces.
    ///     The reference surface must be one of the sibling surfaces, or the
    ///     parent surface. Using any other surface, including this sub-surface,
    ///     will cause a protocol error.
    /// 
    ///     The z-order is double-buffered. Requests are handled in order and
    ///     applied immediately to a pending state. The final pending state is
    ///     copied to the active state the next time the state of the parent
    ///     surface is applied.
    /// 
    ///     A new sub-surface is initially added as the top-most in the stack
    ///     of its siblings and parent.
    ///       
    /// ## Args 
    /// 
    /// ### sibling
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     the reference surface
    /// 
    /// #### Interface
    /// 
    ///     wl_surface
    /// 
    /// 
    pub fn place_above(self: *const wl_subsurface, sibling: types.ObjectId) !void {
        try self.runtime.sendRequest(self.object_id, 2, .{sibling, });
    }

    /// # place_below
    /// 
    /// ## Summary
    /// 
    ///     restack the sub-surface
    /// 
    /// ## Description
    /// 
    ///     The sub-surface is placed just below the reference surface.
    ///     See wl_subsurface.place_above.
    ///       
    /// ## Args 
    /// 
    /// ### sibling
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Summary
    /// 
    ///     the reference surface
    /// 
    /// #### Interface
    /// 
    ///     wl_surface
    /// 
    /// 
    pub fn place_below(self: *const wl_subsurface, sibling: types.ObjectId) !void {
        try self.runtime.sendRequest(self.object_id, 3, .{sibling, });
    }

    /// # set_sync
    /// 
    /// ## Summary
    /// 
    ///     set sub-surface to synchronized mode
    /// 
    /// ## Description
    /// 
    ///     Change the commit behaviour of the sub-surface to synchronized
    ///     mode, also described as the parent dependent mode.
    /// 
    ///     In synchronized mode, wl_surface.commit on a sub-surface will
    ///     accumulate the committed state in a cache, but the state will
    ///     not be applied and hence will not change the compositor output.
    ///     The cached state is applied to the sub-surface immediately after
    ///     the parent surface's state is applied. This ensures atomic
    ///     updates of the parent and all its synchronized sub-surfaces.
    ///     Applying the cached state will invalidate the cache, so further
    ///     parent surface commits do not (re-)apply old state.
    /// 
    ///     See wl_subsurface for the recursive effect of this mode.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn set_sync(self: *const wl_subsurface) !void {
        try self.runtime.sendRequest(self.object_id, 4, .{});
    }

    /// # set_desync
    /// 
    /// ## Summary
    /// 
    ///     set sub-surface to desynchronized mode
    /// 
    /// ## Description
    /// 
    ///     Change the commit behaviour of the sub-surface to desynchronized
    ///     mode, also described as independent or freely running mode.
    /// 
    ///     In desynchronized mode, wl_surface.commit on a sub-surface will
    ///     apply the pending state directly, without caching, as happens
    ///     normally with a wl_surface. Calling wl_surface.commit on the
    ///     parent surface has no effect on the sub-surface's wl_surface
    ///     state. This mode allows a sub-surface to be updated on its own.
    /// 
    ///     If cached state exists when wl_surface.commit is called in
    ///     desynchronized mode, the pending state is added to the cached
    ///     state, and applied as a whole. This invalidates the cache.
    /// 
    ///     Note: even if a sub-surface is set to desynchronized, a parent
    ///     sub-surface may override it to behave as synchronized. For details,
    ///     see wl_subsurface.
    /// 
    ///     If a surface's parent surface behaves as desynchronized, then
    ///     the cached state is applied on set_desync.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn set_desync(self: *const wl_subsurface) !void {
        try self.runtime.sendRequest(self.object_id, 5, .{});
    }
};
