const std = @import("std");
const WaylandRuntime = @import("../WaylandRuntime.zig");
const wayland_types = @import("../wayland_types.zig");

/// # xdg_wm_base
/// 
/// ## Summary
/// 
///     create desktop-style surfaces
/// 
/// ## Description
/// 
///       The xdg_wm_base interface is exposed as a global object enabling clients
///       to turn their wl_surfaces into windows in a desktop environment. It
///       defines the basic functionality needed for clients and the compositor to
///       create windows that can be dragged, resized, maximized, etc, as well as
///       creating transient windows such as popup menus.
///     
pub const xdg_wm_base = struct {
    pub const interface = "xdg_wm_base";
    pub const version = 7;

    pub const enums = struct{
        pub const @"error" = enum(u32) {
            role = 0,
            defunct_surfaces = 1,
            not_the_topmost_popup = 2,
            invalid_popup_parent = 3,
            invalid_surface_state = 4,
            invalid_positioner = 5,
            unresponsive = 6,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # destroy
    /// 
    /// ## Summary
    /// 
    ///     destroy xdg_wm_base
    /// 
    /// ## Description
    /// 
    ///     Destroy this xdg_wm_base object.
    /// 
    ///     Destroying a bound xdg_wm_base object while there are surfaces
    ///     still alive created by this xdg_wm_base object instance is illegal
    ///     and will result in a defunct_surfaces error.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn destroy(self: *const xdg_wm_base) !void {
        try self.runtime.sendRequest(self.object_id, 0, .{});
    }

    /// # create_positioner
    /// 
    /// ## Summary
    /// 
    ///     create a positioner object
    /// 
    /// ## Description
    /// 
    ///     Create a positioner object. A positioner object is used to position
    ///     surfaces relative to some parent surface. See the interface description
    ///     and xdg_surface.get_popup for details.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Interface
    /// 
    ///     xdg_positioner
    /// 
    /// 
    pub fn create_positioner(self: *const xdg_wm_base) !struct { id: xdg_positioner, } {
        const id_id = self.runtime.getId();
        try self.runtime.sendRequest(self.object_id, 1, .{id_id, });
        return .{.id = xdg_positioner{.object_id = id_id, .runtime = self.runtime}, };
    }

    /// # get_xdg_surface
    /// 
    /// ## Summary
    /// 
    ///     create a shell surface from a surface
    /// 
    /// ## Description
    /// 
    ///     This creates an xdg_surface for the given surface. While xdg_surface
    ///     itself is not a role, the corresponding surface may only be assigned
    ///     a role extending xdg_surface, such as xdg_toplevel or xdg_popup. It is
    ///     illegal to create an xdg_surface for a wl_surface which already has an
    ///     assigned role and this will result in a role error.
    /// 
    ///     This creates an xdg_surface for the given surface. An xdg_surface is
    ///     used as basis to define a role to a given surface, such as xdg_toplevel
    ///     or xdg_popup. It also manages functionality shared between xdg_surface
    ///     based surface roles.
    /// 
    ///     See the documentation of xdg_surface for more details about what an
    ///     xdg_surface is and how it is used.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Interface
    /// 
    ///     xdg_surface
    /// 
    /// ### surface
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Interface
    /// 
    ///     wl_surface
    /// 
    /// 
    pub fn get_xdg_surface(self: *const xdg_wm_base, surface: wayland_types.ObjectId) !struct { id: xdg_surface, } {
        const id_id = self.runtime.getId();
        try self.runtime.sendRequest(self.object_id, 2, .{id_id, surface, });
        return .{.id = xdg_surface{.object_id = id_id, .runtime = self.runtime}, };
    }

    /// # pong
    /// 
    /// ## Summary
    /// 
    ///     respond to a ping event
    /// 
    /// ## Description
    /// 
    ///     A client must respond to a ping event with a pong request or
    ///     the client may be deemed unresponsive. See xdg_wm_base.ping
    ///     and xdg_wm_base.error.unresponsive.
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
    ///     serial of the ping event
    /// 
    /// 
    pub fn pong(self: *const xdg_wm_base, serial: u32) !void {
        try self.runtime.sendRequest(self.object_id, 3, .{serial, });
    }

    /// # ping
    /// 
    /// ## Summary
    /// 
    ///     check if the client is alive
    /// 
    /// ## Description
    /// 
    ///     The ping event asks the client if it's still alive. Pass the
    ///     serial specified in the event back to the compositor by sending
    ///     a "pong" request back with the specified serial. See xdg_wm_base.pong.
    /// 
    ///     Compositors can use this to determine if the client is still
    ///     alive. It's unspecified what will happen if the client doesn't
    ///     respond to the ping request, or in what timeframe. Clients should
    ///     try to respond in a reasonable amount of time. The “unresponsive”
    ///     error is provided for compositors that wish to disconnect unresponsive
    ///     clients.
    /// 
    ///     A compositor is free to ping in any way it wants, but a client must
    ///     always respond to any xdg_wm_base object it created.
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
    ///     pass this to the pong request
    /// 
    /// 
    pub fn next_ping(self: *const xdg_wm_base) !?struct {serial: u32, } {
        return try self.runtime.next(self.object_id, 0, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_ping)).@"fn".return_type.?).error_union.payload).optional.child);
}
};

/// # xdg_positioner
/// 
/// ## Summary
/// 
///     child surface positioner
/// 
/// ## Description
/// 
///       The xdg_positioner provides a collection of rules for the placement of a
///       child surface relative to a parent surface. Rules can be defined to ensure
///       the child surface remains within the visible area's borders, and to
///       specify how the child surface changes its position, such as sliding along
///       an axis, or flipping around a rectangle. These positioner-created rules are
///       constrained by the requirement that a child surface must intersect with or
///       be at least partially adjacent to its parent surface.
/// 
///       See the various requests for details about possible rules.
/// 
///       At the time of the request, the compositor makes a copy of the rules
///       specified by the xdg_positioner. Thus, after the request is complete the
///       xdg_positioner object can be destroyed or reused; further changes to the
///       object will have no effect on previous usages.
/// 
///       For an xdg_positioner object to be considered complete, it must have a
///       non-zero size set by set_size, and a non-zero anchor rectangle set by
///       set_anchor_rect. Passing an incomplete xdg_positioner object when
///       positioning a surface raises an invalid_positioner error.
///     
pub const xdg_positioner = struct {
    pub const interface = "xdg_positioner";
    pub const version = 7;

    pub const enums = struct{
        pub const @"error" = enum(u32) {
            invalid_input = 0,
        };

        pub const anchor = enum(u32) {
            none = 0,
            top = 1,
            bottom = 2,
            left = 3,
            right = 4,
            top_left = 5,
            bottom_left = 6,
            top_right = 7,
            bottom_right = 8,
        };

        pub const gravity = enum(u32) {
            none = 0,
            top = 1,
            bottom = 2,
            left = 3,
            right = 4,
            top_left = 5,
            bottom_left = 6,
            top_right = 7,
            bottom_right = 8,
        };

        /// # constraint_adjustment
        /// 
        /// ## Summary
        /// 
        ///     constraint adjustments
        /// 
        /// ## Description
        /// 
        ///     The constraint adjustment value define ways the compositor will adjust
        ///     the position of the surface, if the unadjusted position would result
        ///     in the surface being partly constrained.
        /// 
        ///     Whether a surface is considered 'constrained' is left to the compositor
        ///     to determine. For example, the surface may be partly outside the
        ///     compositor's defined 'work area', thus necessitating the child surface's
        ///     position be adjusted until it is entirely inside the work area.
        /// 
        ///     The adjustments can be combined, according to a defined precedence: 1)
        ///     Flip, 2) Slide, 3) Resize.
        ///       
        pub const constraint_adjustment = enum(u32) {
            /// # none
            /// 
            /// ## Summary
            /// 
            ///     don't move the child surface when constrained
            /// 
            /// ## Description
            /// 
            ///       Don't alter the surface position even if it is constrained on some
            ///       axis, for example partially outside the edge of an output.
            ///     
            none = 0,
            /// # slide_x
            /// 
            /// ## Summary
            /// 
            ///     move along the x axis until unconstrained
            /// 
            /// ## Description
            /// 
            ///       Slide the surface along the x axis until it is no longer constrained.
            /// 
            ///       First try to slide towards the direction of the gravity on the x axis
            ///       until either the edge in the opposite direction of the gravity is
            ///       unconstrained or the edge in the direction of the gravity is
            ///       constrained.
            /// 
            ///       Then try to slide towards the opposite direction of the gravity on the
            ///       x axis until either the edge in the direction of the gravity is
            ///       unconstrained or the edge in the opposite direction of the gravity is
            ///       constrained.
            ///     
            slide_x = 1,
            /// # slide_y
            /// 
            /// ## Summary
            /// 
            ///     move along the y axis until unconstrained
            /// 
            /// ## Description
            /// 
            ///       Slide the surface along the y axis until it is no longer constrained.
            /// 
            ///       First try to slide towards the direction of the gravity on the y axis
            ///       until either the edge in the opposite direction of the gravity is
            ///       unconstrained or the edge in the direction of the gravity is
            ///       constrained.
            /// 
            ///       Then try to slide towards the opposite direction of the gravity on the
            ///       y axis until either the edge in the direction of the gravity is
            ///       unconstrained or the edge in the opposite direction of the gravity is
            ///       constrained.
            ///     
            slide_y = 2,
            /// # flip_x
            /// 
            /// ## Summary
            /// 
            ///     invert the anchor and gravity on the x axis
            /// 
            /// ## Description
            /// 
            ///       Invert the anchor and gravity on the x axis if the surface is
            ///       constrained on the x axis. For example, if the left edge of the
            ///       surface is constrained, the gravity is 'left' and the anchor is
            ///       'left', change the gravity to 'right' and the anchor to 'right'.
            /// 
            ///       If the adjusted position also ends up being constrained, the resulting
            ///       position of the flip_x adjustment will be the one before the
            ///       adjustment.
            ///     
            flip_x = 4,
            /// # flip_y
            /// 
            /// ## Summary
            /// 
            ///     invert the anchor and gravity on the y axis
            /// 
            /// ## Description
            /// 
            ///       Invert the anchor and gravity on the y axis if the surface is
            ///       constrained on the y axis. For example, if the bottom edge of the
            ///       surface is constrained, the gravity is 'bottom' and the anchor is
            ///       'bottom', change the gravity to 'top' and the anchor to 'top'.
            /// 
            ///       The adjusted position is calculated given the original anchor
            ///       rectangle and offset, but with the new flipped anchor and gravity
            ///       values.
            /// 
            ///       If the adjusted position also ends up being constrained, the resulting
            ///       position of the flip_y adjustment will be the one before the
            ///       adjustment.
            ///     
            flip_y = 8,
            /// # resize_x
            /// 
            /// ## Summary
            /// 
            ///     horizontally resize the surface
            /// 
            /// ## Description
            /// 
            ///       Resize the surface horizontally so that it is completely
            ///       unconstrained.
            ///     
            resize_x = 16,
            /// # resize_y
            /// 
            /// ## Summary
            /// 
            ///     vertically resize the surface
            /// 
            /// ## Description
            /// 
            ///       Resize the surface vertically so that it is completely unconstrained.
            ///     
            resize_y = 32,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # destroy
    /// 
    /// ## Summary
    /// 
    ///     destroy the xdg_positioner object
    /// 
    /// ## Description
    /// 
    ///     Notify the compositor that the xdg_positioner will no longer be used.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn destroy(self: *const xdg_positioner) !void {
        try self.runtime.sendRequest(self.object_id, 0, .{});
    }

    /// # set_size
    /// 
    /// ## Summary
    /// 
    ///     set the size of the to-be positioned rectangle
    /// 
    /// ## Description
    /// 
    ///     Set the size of the surface that is to be positioned with the positioner
    ///     object. The size is in surface-local coordinates and corresponds to the
    ///     window geometry. See xdg_surface.set_window_geometry.
    /// 
    ///     If a zero or negative size is set the invalid_input error is raised.
    ///       
    /// ## Args 
    /// 
    /// ### width
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     width of positioned rectangle
    /// 
    /// ### height
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     height of positioned rectangle
    /// 
    /// 
    pub fn set_size(self: *const xdg_positioner, width: i32, height: i32) !void {
        try self.runtime.sendRequest(self.object_id, 1, .{width, height, });
    }

    /// # set_anchor_rect
    /// 
    /// ## Summary
    /// 
    ///     set the anchor rectangle within the parent surface
    /// 
    /// ## Description
    /// 
    ///     Specify the anchor rectangle within the parent surface that the child
    ///     surface will be placed relative to. The rectangle is relative to the
    ///     window geometry as defined by xdg_surface.set_window_geometry of the
    ///     parent surface.
    /// 
    ///     When the xdg_positioner object is used to position a child surface, the
    ///     anchor rectangle may not extend outside the window geometry of the
    ///     positioned child's parent surface.
    /// 
    ///     If a negative size is set the invalid_input error is raised.
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
    ///     x position of anchor rectangle
    /// 
    /// ### y
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     y position of anchor rectangle
    /// 
    /// ### width
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     width of anchor rectangle
    /// 
    /// ### height
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     height of anchor rectangle
    /// 
    /// 
    pub fn set_anchor_rect(self: *const xdg_positioner, x: i32, y: i32, width: i32, height: i32) !void {
        try self.runtime.sendRequest(self.object_id, 2, .{x, y, width, height, });
    }

    /// # set_anchor
    /// 
    /// ## Summary
    /// 
    ///     set anchor rectangle anchor
    /// 
    /// ## Description
    /// 
    ///     Defines the anchor point for the anchor rectangle. The specified anchor
    ///     is used derive an anchor point that the child surface will be
    ///     positioned relative to. If a corner anchor is set (e.g. 'top_left' or
    ///     'bottom_right'), the anchor point will be at the specified corner;
    ///     otherwise, the derived anchor point will be centered on the specified
    ///     edge, or in the center of the anchor rectangle if no edge is specified.
    ///       
    /// ## Args 
    /// 
    /// ### anchor
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     anchor
    /// 
    /// #### Enum
    /// 
    ///     anchor
    /// 
    /// 
    pub fn set_anchor(self: *const xdg_positioner, anchor: u32) !void {
        try self.runtime.sendRequest(self.object_id, 3, .{anchor, });
    }

    /// # set_gravity
    /// 
    /// ## Summary
    /// 
    ///     set child surface gravity
    /// 
    /// ## Description
    /// 
    ///     Defines in what direction a surface should be positioned, relative to
    ///     the anchor point of the parent surface. If a corner gravity is
    ///     specified (e.g. 'bottom_right' or 'top_left'), then the child surface
    ///     will be placed towards the specified gravity; otherwise, the child
    ///     surface will be centered over the anchor point on any axis that had no
    ///     gravity specified. If the gravity is not in the ‘gravity’ enum, an
    ///     invalid_input error is raised.
    ///       
    /// ## Args 
    /// 
    /// ### gravity
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     gravity direction
    /// 
    /// #### Enum
    /// 
    ///     gravity
    /// 
    /// 
    pub fn set_gravity(self: *const xdg_positioner, gravity: u32) !void {
        try self.runtime.sendRequest(self.object_id, 4, .{gravity, });
    }

    /// # set_constraint_adjustment
    /// 
    /// ## Summary
    /// 
    ///     set the adjustment to be done when constrained
    /// 
    /// ## Description
    /// 
    ///     Specify how the window should be positioned if the originally intended
    ///     position caused the surface to be constrained, meaning at least
    ///     partially outside positioning boundaries set by the compositor. The
    ///     adjustment is set by constructing a bitmask describing the adjustment to
    ///     be made when the surface is constrained on that axis.
    /// 
    ///     If no bit for one axis is set, the compositor will assume that the child
    ///     surface should not change its position on that axis when constrained.
    /// 
    ///     If more than one bit for one axis is set, the order of how adjustments
    ///     are applied is specified in the corresponding adjustment descriptions.
    /// 
    ///     The default adjustment is none.
    ///       
    /// ## Args 
    /// 
    /// ### constraint_adjustment
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     bit mask of constraint adjustments
    /// 
    /// #### Enum
    /// 
    ///     constraint_adjustment
    /// 
    /// 
    pub fn set_constraint_adjustment(self: *const xdg_positioner, constraint_adjustment: u32) !void {
        try self.runtime.sendRequest(self.object_id, 5, .{constraint_adjustment, });
    }

    /// # set_offset
    /// 
    /// ## Summary
    /// 
    ///     set surface position offset
    /// 
    /// ## Description
    /// 
    ///     Specify the surface position offset relative to the position of the
    ///     anchor on the anchor rectangle and the anchor on the surface. For
    ///     example if the anchor of the anchor rectangle is at (x, y), the surface
    ///     has the gravity bottom|right, and the offset is (ox, oy), the calculated
    ///     surface position will be (x + ox, y + oy). The offset position of the
    ///     surface is the one used for constraint testing. See
    ///     set_constraint_adjustment.
    /// 
    ///     An example use case is placing a popup menu on top of a user interface
    ///     element, while aligning the user interface element of the parent surface
    ///     with some user interface element placed somewhere in the popup surface.
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
    ///     surface position x offset
    /// 
    /// ### y
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     surface position y offset
    /// 
    /// 
    pub fn set_offset(self: *const xdg_positioner, x: i32, y: i32) !void {
        try self.runtime.sendRequest(self.object_id, 6, .{x, y, });
    }

    /// # set_reactive
    /// 
    /// ## Summary
    /// 
    ///     continuously reconstrain the surface
    /// 
    /// ## Description
    /// 
    ///     When set reactive, the surface is reconstrained if the conditions used
    ///     for constraining changed, e.g. the parent window moved.
    /// 
    ///     If the conditions changed and the popup was reconstrained, an
    ///     xdg_popup.configure event is sent with updated geometry, followed by an
    ///     xdg_surface.configure event.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn set_reactive(self: *const xdg_positioner) !void {
        try self.runtime.sendRequest(self.object_id, 7, .{});
    }

    /// # set_parent_size
    /// 
    /// ## Summary
    /// 
    ///     
    /// 
    /// ## Description
    /// 
    ///     Set the parent window geometry the compositor should use when
    ///     positioning the popup. The compositor may use this information to
    ///     determine the future state the popup should be constrained using. If
    ///     this doesn't match the dimension of the parent the popup is eventually
    ///     positioned against, the behavior is undefined.
    /// 
    ///     The arguments are given in the surface-local coordinate space.
    ///       
    /// ## Args 
    /// 
    /// ### parent_width
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     future window geometry width of parent
    /// 
    /// ### parent_height
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     future window geometry height of parent
    /// 
    /// 
    pub fn set_parent_size(self: *const xdg_positioner, parent_width: i32, parent_height: i32) !void {
        try self.runtime.sendRequest(self.object_id, 8, .{parent_width, parent_height, });
    }

    /// # set_parent_configure
    /// 
    /// ## Summary
    /// 
    ///     set parent configure this is a response to
    /// 
    /// ## Description
    /// 
    ///     Set the serial of an xdg_surface.configure event this positioner will be
    ///     used in response to. The compositor may use this information together
    ///     with set_parent_size to determine what future state the popup should be
    ///     constrained using.
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
    ///     serial of parent configure event
    /// 
    /// 
    pub fn set_parent_configure(self: *const xdg_positioner, serial: u32) !void {
        try self.runtime.sendRequest(self.object_id, 9, .{serial, });
    }
};

/// # xdg_surface
/// 
/// ## Summary
/// 
///     desktop user interface surface base interface
/// 
/// ## Description
/// 
///       An interface that may be implemented by a wl_surface, for
///       implementations that provide a desktop-style user interface.
/// 
///       It provides a base set of functionality required to construct user
///       interface elements requiring management by the compositor, such as
///       toplevel windows, menus, etc. The types of functionality are split into
///       xdg_surface roles.
/// 
///       Creating an xdg_surface does not set the role for a wl_surface. In order
///       to map an xdg_surface, the client must create a role-specific object
///       using, e.g., get_toplevel, get_popup. The wl_surface for any given
///       xdg_surface can have at most one role, and may not be assigned any role
///       not based on xdg_surface.
/// 
///       A role must be assigned before any other requests are made to the
///       xdg_surface object.
/// 
///       The client must call wl_surface.commit on the corresponding wl_surface
///       for the xdg_surface state to take effect.
/// 
///       Creating an xdg_surface from a wl_surface which has a buffer attached or
///       committed is a client error, and any attempts by a client to attach or
///       manipulate a buffer prior to the first xdg_surface.configure call must
///       also be treated as errors.
/// 
///       After creating a role-specific object and setting it up (e.g. by sending
///       the title, app ID, size constraints, parent, etc), the client must
///       perform an initial commit without any buffer attached. The compositor
///       will reply with initial wl_surface state such as
///       wl_surface.preferred_buffer_scale followed by an xdg_surface.configure
///       event. The client must acknowledge it and is then allowed to attach a
///       buffer to map the surface.
/// 
///       Mapping an xdg_surface-based role surface is defined as making it
///       possible for the surface to be shown by the compositor. Note that
///       a mapped surface is not guaranteed to be visible once it is mapped.
/// 
///       For an xdg_surface to be mapped by the compositor, the following
///       conditions must be met:
///       (1) the client has assigned an xdg_surface-based role to the surface
///       (2) the client has set and committed the xdg_surface state and the
///       role-dependent state to the surface
///       (3) the client has committed a buffer to the surface
/// 
///       A newly-unmapped surface is considered to have met condition (1) out
///       of the 3 required conditions for mapping a surface if its role surface
///       has not been destroyed, i.e. the client must perform the initial commit
///       again before attaching a buffer.
///     
pub const xdg_surface = struct {
    pub const interface = "xdg_surface";
    pub const version = 7;

    pub const enums = struct{
        pub const @"error" = enum(u32) {
            not_constructed = 1,
            already_constructed = 2,
            unconfigured_buffer = 3,
            invalid_serial = 4,
            invalid_size = 5,
            defunct_role_object = 6,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # destroy
    /// 
    /// ## Summary
    /// 
    ///     destroy the xdg_surface
    /// 
    /// ## Description
    /// 
    ///     Destroy the xdg_surface object. An xdg_surface must only be destroyed
    ///     after its role object has been destroyed, otherwise
    ///     a defunct_role_object error is raised.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn destroy(self: *const xdg_surface) !void {
        try self.runtime.sendRequest(self.object_id, 0, .{});
    }

    /// # get_toplevel
    /// 
    /// ## Summary
    /// 
    ///     assign the xdg_toplevel surface role
    /// 
    /// ## Description
    /// 
    ///     This creates an xdg_toplevel object for the given xdg_surface and gives
    ///     the associated wl_surface the xdg_toplevel role.
    /// 
    ///     See the documentation of xdg_toplevel for more details about what an
    ///     xdg_toplevel is and how it is used.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Interface
    /// 
    ///     xdg_toplevel
    /// 
    /// 
    pub fn get_toplevel(self: *const xdg_surface) !struct { id: xdg_toplevel, } {
        const id_id = self.runtime.getId();
        try self.runtime.sendRequest(self.object_id, 1, .{id_id, });
        return .{.id = xdg_toplevel{.object_id = id_id, .runtime = self.runtime}, };
    }

    /// # get_popup
    /// 
    /// ## Summary
    /// 
    ///     assign the xdg_popup surface role
    /// 
    /// ## Description
    /// 
    ///     This creates an xdg_popup object for the given xdg_surface and gives
    ///     the associated wl_surface the xdg_popup role.
    /// 
    ///     If null is passed as a parent, a parent surface must be specified using
    ///     some other protocol, before committing the initial state.
    /// 
    ///     See the documentation of xdg_popup for more details about what an
    ///     xdg_popup is and how it is used.
    ///       
    /// ## Args 
    /// 
    /// ### id
    /// 
    /// #### Type
    /// 
    ///     new_id
    /// 
    /// #### Interface
    /// 
    ///     xdg_popup
    /// 
    /// ### parent
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Interface
    /// 
    ///     xdg_surface
    /// 
    /// #### Allow Null
    /// 
    ///     true
    /// 
    /// ### positioner
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Interface
    /// 
    ///     xdg_positioner
    /// 
    /// 
    pub fn get_popup(self: *const xdg_surface, parent: wayland_types.ObjectId, positioner: wayland_types.ObjectId) !struct { id: xdg_popup, } {
        const id_id = self.runtime.getId();
        try self.runtime.sendRequest(self.object_id, 2, .{id_id, parent, positioner, });
        return .{.id = xdg_popup{.object_id = id_id, .runtime = self.runtime}, };
    }

    /// # set_window_geometry
    /// 
    /// ## Summary
    /// 
    ///     set the new window geometry
    /// 
    /// ## Description
    /// 
    ///     The window geometry of a surface is its "visible bounds" from the
    ///     user's perspective. Client-side decorations often have invisible
    ///     portions like drop-shadows which should be ignored for the
    ///     purposes of aligning, placing and constraining windows.
    /// 
    ///     The window geometry is double-buffered state, see wl_surface.commit.
    /// 
    ///     When maintaining a position, the compositor should treat the (x, y)
    ///     coordinate of the window geometry as the top left corner of the window.
    ///     A client changing the (x, y) window geometry coordinate should in
    ///     general not alter the position of the window.
    /// 
    ///     Once the window geometry of the surface is set, it is not possible to
    ///     unset it, and it will remain the same until set_window_geometry is
    ///     called again, even if a new subsurface or buffer is attached.
    /// 
    ///     If never set, the value is the full bounds of the surface,
    ///     including any subsurfaces. This updates dynamically on every
    ///     commit. This unset is meant for extremely simple clients.
    /// 
    ///     The arguments are given in the surface-local coordinate space of
    ///     the wl_surface associated with this xdg_surface, and may extend outside
    ///     of the wl_surface itself to mark parts of the subsurface tree as part of
    ///     the window geometry.
    /// 
    ///     When applied, the effective window geometry will be the set window
    ///     geometry clamped to the bounding rectangle of the combined
    ///     geometry of the surface of the xdg_surface and the associated
    ///     subsurfaces.
    /// 
    ///     The effective geometry will not be recalculated unless a new call to
    ///     set_window_geometry is done and the new pending surface state is
    ///     subsequently applied.
    /// 
    ///     The width and height of the effective window geometry must be
    ///     greater than zero. Setting an invalid size will raise an
    ///     invalid_size error.
    ///       
    /// ## Args 
    /// 
    /// ### x
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// ### y
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// ### width
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// ### height
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// 
    pub fn set_window_geometry(self: *const xdg_surface, x: i32, y: i32, width: i32, height: i32) !void {
        try self.runtime.sendRequest(self.object_id, 3, .{x, y, width, height, });
    }

    /// # ack_configure
    /// 
    /// ## Summary
    /// 
    ///     ack a configure event
    /// 
    /// ## Description
    /// 
    ///     When a configure event is received, if a client commits the
    ///     surface in response to the configure event, then the client
    ///     must make an ack_configure request sometime before the commit
    ///     request, passing along the serial of the configure event.
    /// 
    ///     For instance, for toplevel surfaces the compositor might use this
    ///     information to move a surface to the top left only when the client has
    ///     drawn itself for the maximized or fullscreen state.
    /// 
    ///     If the client receives multiple configure events before it
    ///     can respond to one, it only has to ack the last configure event.
    ///     Acking a configure event that was never sent raises an invalid_serial
    ///     error.
    /// 
    ///     A client is not required to commit immediately after sending
    ///     an ack_configure request - it may even ack_configure several times
    ///     before its next surface commit.
    /// 
    ///     A client may send multiple ack_configure requests before committing, but
    ///     only the last request sent before a commit indicates which configure
    ///     event the client really is responding to.
    /// 
    ///     Sending an ack_configure request consumes the serial number sent with
    ///     the request, as well as serial numbers sent by all configure events
    ///     sent on this xdg_surface prior to the configure event referenced by
    ///     the committed serial.
    /// 
    ///     It is an error to issue multiple ack_configure requests referencing a
    ///     serial from the same configure event, or to issue an ack_configure
    ///     request referencing a serial from a configure event issued before the
    ///     event identified by the last ack_configure request for the same
    ///     xdg_surface. Doing so will raise an invalid_serial error.
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
    ///     the serial from the configure event
    /// 
    /// 
    pub fn ack_configure(self: *const xdg_surface, serial: u32) !void {
        try self.runtime.sendRequest(self.object_id, 4, .{serial, });
    }

    /// # configure
    /// 
    /// ## Summary
    /// 
    ///     suggest a surface change
    /// 
    /// ## Description
    /// 
    ///     The configure event marks the end of a configure sequence. A configure
    ///     sequence is a set of one or more events configuring the state of the
    ///     xdg_surface, including the final xdg_surface.configure event.
    /// 
    ///     Where applicable, xdg_surface surface roles will during a configure
    ///     sequence extend this event as a latched state sent as events before the
    ///     xdg_surface.configure event. Such events should be considered to make up
    ///     a set of atomically applied configuration states, where the
    ///     xdg_surface.configure commits the accumulated state.
    /// 
    ///     Clients should arrange their surface for the new states, and then send
    ///     an ack_configure request with the serial sent in this configure event at
    ///     some point before committing the new surface.
    /// 
    ///     If the client receives multiple configure events before it can respond
    ///     to one, it is free to discard all but the last event it received.
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
    ///     serial of the configure event
    /// 
    /// 
    pub fn next_configure(self: *const xdg_surface) !?struct {serial: u32, } {
        return try self.runtime.next(self.object_id, 0, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_configure)).@"fn".return_type.?).error_union.payload).optional.child);
}
};

/// # xdg_toplevel
/// 
/// ## Summary
/// 
///     toplevel surface
/// 
/// ## Description
/// 
///       This interface defines an xdg_surface role which allows a surface to,
///       among other things, set window-like properties such as maximize,
///       fullscreen, and minimize, set application-specific metadata like title and
///       id, and well as trigger user interactive operations such as interactive
///       resize and move.
/// 
///       A xdg_toplevel by default is responsible for providing the full intended
///       visual representation of the toplevel, which depending on the window
///       state, may mean things like a title bar, window controls and drop shadow.
/// 
///       Unmapping an xdg_toplevel means that the surface cannot be shown
///       by the compositor until it is explicitly mapped again.
///       All active operations (e.g., move, resize) are canceled and all
///       attributes (e.g. title, state, stacking, ...) are discarded for
///       an xdg_toplevel surface when it is unmapped. The xdg_toplevel returns to
///       the state it had right after xdg_surface.get_toplevel. The client
///       can re-map the toplevel by performing a commit without any buffer
///       attached, waiting for a configure event and handling it as usual (see
///       xdg_surface description).
/// 
///       Attaching a null buffer to a toplevel unmaps the surface.
///     
pub const xdg_toplevel = struct {
    pub const interface = "xdg_toplevel";
    pub const version = 7;

    pub const enums = struct{
        pub const @"error" = enum(u32) {
            invalid_resize_edge = 0,
            invalid_parent = 1,
            invalid_size = 2,
        };

        /// # resize_edge
        /// 
        /// ## Summary
        /// 
        ///     edge values for resizing
        /// 
        /// ## Description
        /// 
        ///     These values are used to indicate which edge of a surface
        ///     is being dragged in a resize operation.
        ///       
        pub const resize_edge = enum(u32) {
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

        /// # state
        /// 
        /// ## Summary
        /// 
        ///     types of state on the surface
        /// 
        /// ## Description
        /// 
        ///     The different state values used on the surface. This is designed for
        ///     state values like maximized, fullscreen. It is paired with the
        ///     configure event to ensure that both the client and the compositor
        ///     setting the state can be synchronized.
        /// 
        ///     States set in this way are double-buffered, see wl_surface.commit.
        ///       
        pub const state = enum(u32) {
            /// # maximized
            /// 
            /// ## Summary
            /// 
            ///     the surface is maximized
            /// 
            /// ## Description
            /// 
            ///       The surface is maximized. The window geometry specified in the configure
            ///       event must be obeyed by the client, or the xdg_wm_base.invalid_surface_state
            ///       error is raised.
            /// 
            ///       The client should draw without shadow or other
            ///       decoration outside of the window geometry.
            ///     
            maximized = 1,
            /// # fullscreen
            /// 
            /// ## Summary
            /// 
            ///     the surface is fullscreen
            /// 
            /// ## Description
            /// 
            ///       The surface is fullscreen. The window geometry specified in the
            ///       configure event is a maximum; the client cannot resize beyond it. For
            ///       a surface to cover the whole fullscreened area, the geometry
            ///       dimensions must be obeyed by the client. For more details, see
            ///       xdg_toplevel.set_fullscreen.
            ///     
            fullscreen = 2,
            /// # resizing
            /// 
            /// ## Summary
            /// 
            ///     the surface is being resized
            /// 
            /// ## Description
            /// 
            ///       The surface is being resized. The window geometry specified in the
            ///       configure event is a maximum; the client cannot resize beyond it.
            ///       Clients that have aspect ratio or cell sizing configuration can use
            ///       a smaller size, however.
            ///     
            resizing = 3,
            /// # activated
            /// 
            /// ## Summary
            /// 
            ///     the surface is now activated
            /// 
            /// ## Description
            /// 
            ///       Client window decorations should be painted as if the window is
            ///       active. Do not assume this means that the window actually has
            ///       keyboard or pointer focus.
            ///     
            activated = 4,
            /// # tiled_left
            /// 
            /// ## Summary
            /// 
            ///     the surface’s left edge is tiled
            /// 
            /// ## Description
            /// 
            ///       The window is currently in a tiled layout and the left edge is
            ///       considered to be adjacent to another part of the tiling grid.
            /// 
            ///       The client should draw without shadow or other decoration outside of
            ///       the window geometry on the left edge.
            ///     
            tiled_left = 5,
            /// # tiled_right
            /// 
            /// ## Summary
            /// 
            ///     the surface’s right edge is tiled
            /// 
            /// ## Description
            /// 
            ///       The window is currently in a tiled layout and the right edge is
            ///       considered to be adjacent to another part of the tiling grid.
            /// 
            ///       The client should draw without shadow or other decoration outside of
            ///       the window geometry on the right edge.
            ///     
            tiled_right = 6,
            /// # tiled_top
            /// 
            /// ## Summary
            /// 
            ///     the surface’s top edge is tiled
            /// 
            /// ## Description
            /// 
            ///       The window is currently in a tiled layout and the top edge is
            ///       considered to be adjacent to another part of the tiling grid.
            /// 
            ///       The client should draw without shadow or other decoration outside of
            ///       the window geometry on the top edge.
            ///     
            tiled_top = 7,
            /// # tiled_bottom
            /// 
            /// ## Summary
            /// 
            ///     the surface’s bottom edge is tiled
            /// 
            /// ## Description
            /// 
            ///       The window is currently in a tiled layout and the bottom edge is
            ///       considered to be adjacent to another part of the tiling grid.
            /// 
            ///       The client should draw without shadow or other decoration outside of
            ///       the window geometry on the bottom edge.
            ///     
            tiled_bottom = 8,
            /// # suspended
            /// 
            /// ## Summary
            /// 
            ///     surface repaint is suspended
            /// 
            /// ## Description
            /// 
            ///       The surface is currently not ordinarily being repainted; for
            ///       example because its content is occluded by another window, or its
            ///       outputs are switched off due to screen locking.
            ///     
            suspended = 9,
            /// # constrained_left
            /// 
            /// ## Summary
            /// 
            ///     the surface’s left edge is constrained
            /// 
            /// ## Description
            /// 
            ///           The left edge of the window is currently constrained, meaning it
            ///           shouldn't attempt to resize from that edge. It can for example mean
            ///           it's tiled next to a monitor edge on the constrained side of the
            ///           window.
            ///     
            constrained_left = 10,
            /// # constrained_right
            /// 
            /// ## Summary
            /// 
            ///     the surface’s right edge is constrained
            /// 
            /// ## Description
            /// 
            ///           The right edge of the window is currently constrained, meaning it
            ///           shouldn't attempt to resize from that edge. It can for example mean
            ///           it's tiled next to a monitor edge on the constrained side of the
            ///           window.
            ///     
            constrained_right = 11,
            /// # constrained_top
            /// 
            /// ## Summary
            /// 
            ///     the surface’s top edge is constrained
            /// 
            /// ## Description
            /// 
            ///           The top edge of the window is currently constrained, meaning it
            ///           shouldn't attempt to resize from that edge. It can for example mean
            ///           it's tiled next to a monitor edge on the constrained side of the
            ///           window.
            ///     
            constrained_top = 12,
            /// # constrained_bottom
            /// 
            /// ## Summary
            /// 
            ///     the surface’s bottom edge is tiled
            /// 
            /// ## Description
            /// 
            ///           The bottom edge of the window is currently constrained, meaning it
            ///           shouldn't attempt to resize from that edge. It can for example mean
            ///           it's tiled next to a monitor edge on the constrained side of the
            ///           window.
            ///     
            constrained_bottom = 13,
        };

        pub const wm_capabilities = enum(u32) {
            window_menu = 1,
            maximize = 2,
            fullscreen = 3,
            minimize = 4,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # destroy
    /// 
    /// ## Summary
    /// 
    ///     destroy the xdg_toplevel
    /// 
    /// ## Description
    /// 
    ///     This request destroys the role surface and unmaps the surface;
    ///     see "Unmapping" behavior in interface section for details.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn destroy(self: *const xdg_toplevel) !void {
        try self.runtime.sendRequest(self.object_id, 0, .{});
    }

    /// # set_parent
    /// 
    /// ## Summary
    /// 
    ///     set the parent of this surface
    /// 
    /// ## Description
    /// 
    ///     Set the "parent" of this surface. This surface should be stacked
    ///     above the parent surface and all other ancestor surfaces.
    /// 
    ///     Parent surfaces should be set on dialogs, toolboxes, or other
    ///     "auxiliary" surfaces, so that the parent is raised when the dialog
    ///     is raised.
    /// 
    ///     Setting a null parent for a child surface unsets its parent. Setting
    ///     a null parent for a surface which currently has no parent is a no-op.
    /// 
    ///     Only mapped surfaces can have child surfaces. Setting a parent which
    ///     is not mapped is equivalent to setting a null parent. If a surface
    ///     becomes unmapped, its children's parent is set to the parent of
    ///     the now-unmapped surface. If the now-unmapped surface has no parent,
    ///     its children's parent is unset. If the now-unmapped surface becomes
    ///     mapped again, its parent-child relationship is not restored.
    /// 
    ///     The parent toplevel must not be one of the child toplevel's
    ///     descendants, and the parent must be different from the child toplevel,
    ///     otherwise the invalid_parent protocol error is raised.
    ///       
    /// ## Args 
    /// 
    /// ### parent
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Interface
    /// 
    ///     xdg_toplevel
    /// 
    /// #### Allow Null
    /// 
    ///     true
    /// 
    /// 
    pub fn set_parent(self: *const xdg_toplevel, parent: wayland_types.ObjectId) !void {
        try self.runtime.sendRequest(self.object_id, 1, .{parent, });
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
    /// 
    pub fn set_title(self: *const xdg_toplevel, title: []const u8) !void {
        try self.runtime.sendRequest(self.object_id, 2, .{wayland_types.String{.data = title}, });
    }

    /// # set_app_id
    /// 
    /// ## Summary
    /// 
    ///     set application ID
    /// 
    /// ## Description
    /// 
    ///     Set an application identifier for the surface.
    /// 
    ///     The app ID identifies the general class of applications to which
    ///     the surface belongs. The compositor can use this to group multiple
    ///     surfaces together, or to determine how to launch a new application.
    /// 
    ///     For D-Bus activatable applications, the app ID is used as the D-Bus
    ///     service name.
    /// 
    ///     The compositor shell will try to group application surfaces together
    ///     by their app ID. As a best practice, it is suggested to select app
    ///     ID's that match the basename of the application's .desktop file.
    ///     For example, "org.freedesktop.FooViewer" where the .desktop file is
    ///     "org.freedesktop.FooViewer.desktop".
    /// 
    ///     Like other properties, a set_app_id request can be sent after the
    ///     xdg_toplevel has been mapped to update the property.
    /// 
    ///     See the desktop-entry specification [0] for more details on
    ///     application identifiers and how they relate to well-known D-Bus
    ///     names and .desktop files.
    /// 
    ///     [0] https://standards.freedesktop.org/desktop-entry-spec/
    ///       
    /// ## Args 
    /// 
    /// ### app_id
    /// 
    /// #### Type
    /// 
    ///     string
    /// 
    /// 
    pub fn set_app_id(self: *const xdg_toplevel, app_id: []const u8) !void {
        try self.runtime.sendRequest(self.object_id, 3, .{wayland_types.String{.data = app_id}, });
    }

    /// # show_window_menu
    /// 
    /// ## Summary
    /// 
    ///     show the window menu
    /// 
    /// ## Description
    /// 
    ///     Clients implementing client-side decorations might want to show
    ///     a context menu when right-clicking on the decorations, giving the
    ///     user a menu that they can use to maximize or minimize the window.
    /// 
    ///     This request asks the compositor to pop up such a window menu at
    ///     the given position, relative to the local surface coordinates of
    ///     the parent surface. There are no guarantees as to what menu items
    ///     the window menu contains, or even if a window menu will be drawn
    ///     at all.
    /// 
    ///     This request must be used in response to some sort of user action
    ///     like a button press, key press, or touch down event.
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
    ///     the wl_seat of the user event
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
    ///     the serial of the user event
    /// 
    /// ### x
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     the x position to pop up the window menu at
    /// 
    /// ### y
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     the y position to pop up the window menu at
    /// 
    /// 
    pub fn show_window_menu(self: *const xdg_toplevel, seat: wayland_types.ObjectId, serial: u32, x: i32, y: i32) !void {
        try self.runtime.sendRequest(self.object_id, 4, .{seat, serial, x, y, });
    }

    /// # move
    /// 
    /// ## Summary
    /// 
    ///     start an interactive move
    /// 
    /// ## Description
    /// 
    ///     Start an interactive, user-driven move of the surface.
    /// 
    ///     This request must be used in response to some sort of user action
    ///     like a button press, key press, or touch down event. The passed
    ///     serial is used to determine the type of interactive move (touch,
    ///     pointer, etc).
    /// 
    ///     The server may ignore move requests depending on the state of
    ///     the surface (e.g. fullscreen or maximized), or if the passed serial
    ///     is no longer valid.
    /// 
    ///     If triggered, the surface will lose the focus of the device
    ///     (wl_pointer, wl_touch, etc) used for the move. It is up to the
    ///     compositor to visually indicate that the move is taking place, such as
    ///     updating a pointer cursor, during the move. There is no guarantee
    ///     that the device focus will return when the move is completed.
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
    ///     the wl_seat of the user event
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
    ///     the serial of the user event
    /// 
    /// 
    pub fn move(self: *const xdg_toplevel, seat: wayland_types.ObjectId, serial: u32) !void {
        try self.runtime.sendRequest(self.object_id, 5, .{seat, serial, });
    }

    /// # resize
    /// 
    /// ## Summary
    /// 
    ///     start an interactive resize
    /// 
    /// ## Description
    /// 
    ///     Start a user-driven, interactive resize of the surface.
    /// 
    ///     This request must be used in response to some sort of user action
    ///     like a button press, key press, or touch down event. The passed
    ///     serial is used to determine the type of interactive resize (touch,
    ///     pointer, etc).
    /// 
    ///     The server may ignore resize requests depending on the state of
    ///     the surface (e.g. fullscreen or maximized).
    /// 
    ///     If triggered, the client will receive configure events with the
    ///     "resize" state enum value and the expected sizes. See the "resize"
    ///     enum value for more details about what is required. The client
    ///     must also acknowledge configure events using "ack_configure". After
    ///     the resize is completed, the client will receive another "configure"
    ///     event without the resize state.
    /// 
    ///     If triggered, the surface also will lose the focus of the device
    ///     (wl_pointer, wl_touch, etc) used for the resize. It is up to the
    ///     compositor to visually indicate that the resize is taking place,
    ///     such as updating a pointer cursor, during the resize. There is no
    ///     guarantee that the device focus will return when the resize is
    ///     completed.
    /// 
    ///     The edges parameter specifies how the surface should be resized, and
    ///     is one of the values of the resize_edge enum. Values not matching
    ///     a variant of the enum will cause the invalid_resize_edge protocol error.
    ///     The compositor may use this information to update the surface position
    ///     for example when dragging the top left corner. The compositor may also
    ///     use this information to adapt its behavior, e.g. choose an appropriate
    ///     cursor image.
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
    ///     the wl_seat of the user event
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
    ///     the serial of the user event
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
    ///     resize_edge
    /// 
    /// 
    pub fn resize(self: *const xdg_toplevel, seat: wayland_types.ObjectId, serial: u32, edges: u32) !void {
        try self.runtime.sendRequest(self.object_id, 6, .{seat, serial, edges, });
    }

    /// # set_max_size
    /// 
    /// ## Summary
    /// 
    ///     set the maximum size
    /// 
    /// ## Description
    /// 
    ///     Set a maximum size for the window.
    /// 
    ///     The client can specify a maximum size so that the compositor does
    ///     not try to configure the window beyond this size.
    /// 
    ///     The width and height arguments are in window geometry coordinates.
    ///     See xdg_surface.set_window_geometry.
    /// 
    ///     Values set in this way are double-buffered, see wl_surface.commit.
    /// 
    ///     The compositor can use this information to allow or disallow
    ///     different states like maximize or fullscreen and draw accurate
    ///     animations.
    /// 
    ///     Similarly, a tiling window manager may use this information to
    ///     place and resize client windows in a more effective way.
    /// 
    ///     The client should not rely on the compositor to obey the maximum
    ///     size. The compositor may decide to ignore the values set by the
    ///     client and request a larger size.
    /// 
    ///     If never set, or a value of zero in the request, means that the
    ///     client has no expected maximum size in the given dimension.
    ///     As a result, a client wishing to reset the maximum size
    ///     to an unspecified state can use zero for width and height in the
    ///     request.
    /// 
    ///     Requesting a maximum size to be smaller than the minimum size of
    ///     a surface is illegal and will result in an invalid_size error.
    /// 
    ///     The width and height must be greater than or equal to zero. Using
    ///     strictly negative values for width or height will result in a
    ///     invalid_size error.
    ///       
    /// ## Args 
    /// 
    /// ### width
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// ### height
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// 
    pub fn set_max_size(self: *const xdg_toplevel, width: i32, height: i32) !void {
        try self.runtime.sendRequest(self.object_id, 7, .{width, height, });
    }

    /// # set_min_size
    /// 
    /// ## Summary
    /// 
    ///     set the minimum size
    /// 
    /// ## Description
    /// 
    ///     Set a minimum size for the window.
    /// 
    ///     The client can specify a minimum size so that the compositor does
    ///     not try to configure the window below this size.
    /// 
    ///     The width and height arguments are in window geometry coordinates.
    ///     See xdg_surface.set_window_geometry.
    /// 
    ///     Values set in this way are double-buffered, see wl_surface.commit.
    /// 
    ///     The compositor can use this information to allow or disallow
    ///     different states like maximize or fullscreen and draw accurate
    ///     animations.
    /// 
    ///     Similarly, a tiling window manager may use this information to
    ///     place and resize client windows in a more effective way.
    /// 
    ///     The client should not rely on the compositor to obey the minimum
    ///     size. The compositor may decide to ignore the values set by the
    ///     client and request a smaller size.
    /// 
    ///     If never set, or a value of zero in the request, means that the
    ///     client has no expected minimum size in the given dimension.
    ///     As a result, a client wishing to reset the minimum size
    ///     to an unspecified state can use zero for width and height in the
    ///     request.
    /// 
    ///     Requesting a minimum size to be larger than the maximum size of
    ///     a surface is illegal and will result in an invalid_size error.
    /// 
    ///     The width and height must be greater than or equal to zero. Using
    ///     strictly negative values for width and height will result in a
    ///     invalid_size error.
    ///       
    /// ## Args 
    /// 
    /// ### width
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// ### height
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// 
    pub fn set_min_size(self: *const xdg_toplevel, width: i32, height: i32) !void {
        try self.runtime.sendRequest(self.object_id, 8, .{width, height, });
    }

    /// # set_maximized
    /// 
    /// ## Summary
    /// 
    ///     maximize the window
    /// 
    /// ## Description
    /// 
    ///     Maximize the surface.
    /// 
    ///     After requesting that the surface should be maximized, the compositor
    ///     will respond by emitting a configure event. Whether this configure
    ///     actually sets the window maximized is subject to compositor policies.
    ///     The client must then update its content, drawing in the configured
    ///     state. The client must also acknowledge the configure when committing
    ///     the new content (see ack_configure).
    /// 
    ///     It is up to the compositor to decide how and where to maximize the
    ///     surface, for example which output and what region of the screen should
    ///     be used.
    /// 
    ///     If the surface was already maximized, the compositor will still emit
    ///     a configure event with the "maximized" state.
    /// 
    ///     If the surface is in a fullscreen state, this request has no direct
    ///     effect. It may alter the state the surface is returned to when
    ///     unmaximized unless overridden by the compositor.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn set_maximized(self: *const xdg_toplevel) !void {
        try self.runtime.sendRequest(self.object_id, 9, .{});
    }

    /// # unset_maximized
    /// 
    /// ## Summary
    /// 
    ///     unmaximize the window
    /// 
    /// ## Description
    /// 
    ///     Unmaximize the surface.
    /// 
    ///     After requesting that the surface should be unmaximized, the compositor
    ///     will respond by emitting a configure event. Whether this actually
    ///     un-maximizes the window is subject to compositor policies.
    ///     If available and applicable, the compositor will include the window
    ///     geometry dimensions the window had prior to being maximized in the
    ///     configure event. The client must then update its content, drawing it in
    ///     the configured state. The client must also acknowledge the configure
    ///     when committing the new content (see ack_configure).
    /// 
    ///     It is up to the compositor to position the surface after it was
    ///     unmaximized; usually the position the surface had before maximizing, if
    ///     applicable.
    /// 
    ///     If the surface was already not maximized, the compositor will still
    ///     emit a configure event without the "maximized" state.
    /// 
    ///     If the surface is in a fullscreen state, this request has no direct
    ///     effect. It may alter the state the surface is returned to when
    ///     unmaximized unless overridden by the compositor.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn unset_maximized(self: *const xdg_toplevel) !void {
        try self.runtime.sendRequest(self.object_id, 10, .{});
    }

    /// # set_fullscreen
    /// 
    /// ## Summary
    /// 
    ///     set the window as fullscreen on an output
    /// 
    /// ## Description
    /// 
    ///     Make the surface fullscreen.
    /// 
    ///     After requesting that the surface should be fullscreened, the
    ///     compositor will respond by emitting a configure event. Whether the
    ///     client is actually put into a fullscreen state is subject to compositor
    ///     policies. The client must also acknowledge the configure when
    ///     committing the new content (see ack_configure).
    /// 
    ///     The output passed by the request indicates the client's preference as
    ///     to which display it should be set fullscreen on. If this value is NULL,
    ///     it's up to the compositor to choose which display will be used to map
    ///     this surface.
    /// 
    ///     If the surface doesn't cover the whole output, the compositor will
    ///     position the surface in the center of the output and compensate with
    ///     with border fill covering the rest of the output. The content of the
    ///     border fill is undefined, but should be assumed to be in some way that
    ///     attempts to blend into the surrounding area (e.g. solid black).
    /// 
    ///     If the fullscreened surface is not opaque, the compositor must make
    ///     sure that other screen content not part of the same surface tree (made
    ///     up of subsurfaces, popups or similarly coupled surfaces) are not
    ///     visible below the fullscreened surface.
    ///       
    /// ## Args 
    /// 
    /// ### output
    /// 
    /// #### Type
    /// 
    ///     object
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
    pub fn set_fullscreen(self: *const xdg_toplevel, output: wayland_types.ObjectId) !void {
        try self.runtime.sendRequest(self.object_id, 11, .{output, });
    }

    /// # unset_fullscreen
    /// 
    /// ## Summary
    /// 
    ///     unset the window as fullscreen
    /// 
    /// ## Description
    /// 
    ///     Make the surface no longer fullscreen.
    /// 
    ///     After requesting that the surface should be unfullscreened, the
    ///     compositor will respond by emitting a configure event.
    ///     Whether this actually removes the fullscreen state of the client is
    ///     subject to compositor policies.
    /// 
    ///     Making a surface unfullscreen sets states for the surface based on the following:
    ///     * the state(s) it may have had before becoming fullscreen
    ///     * any state(s) decided by the compositor
    ///     * any state(s) requested by the client while the surface was fullscreen
    /// 
    ///     The compositor may include the previous window geometry dimensions in
    ///     the configure event, if applicable.
    /// 
    ///     The client must also acknowledge the configure when committing the new
    ///     content (see ack_configure).
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn unset_fullscreen(self: *const xdg_toplevel) !void {
        try self.runtime.sendRequest(self.object_id, 12, .{});
    }

    /// # set_minimized
    /// 
    /// ## Summary
    /// 
    ///     set the window as minimized
    /// 
    /// ## Description
    /// 
    ///     Request that the compositor minimize your surface. There is no
    ///     way to know if the surface is currently minimized, nor is there
    ///     any way to unset minimization on this surface.
    /// 
    ///     If you are looking to throttle redrawing when minimized, please
    ///     instead use the wl_surface.frame event for this, as this will
    ///     also work with live previews on windows in Alt-Tab, Expose or
    ///     similar compositor features.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn set_minimized(self: *const xdg_toplevel) !void {
        try self.runtime.sendRequest(self.object_id, 13, .{});
    }

    /// # configure
    /// 
    /// ## Summary
    /// 
    ///     suggest a surface change
    /// 
    /// ## Description
    /// 
    ///     This configure event asks the client to resize its toplevel surface or
    ///     to change its state. The configured state should not be applied
    ///     immediately. See xdg_surface.configure for details.
    /// 
    ///     The width and height arguments specify a hint to the window
    ///     about how its surface should be resized in window geometry
    ///     coordinates. See set_window_geometry.
    /// 
    ///     If the width or height arguments are zero, it means the client
    ///     should decide its own window dimension. This may happen when the
    ///     compositor needs to configure the state of the surface but doesn't
    ///     have any information about any previous or expected dimension.
    /// 
    ///     The states listed in the event specify how the width/height
    ///     arguments should be interpreted, and possibly how it should be
    ///     drawn.
    /// 
    ///     Clients must send an ack_configure in response to this event. See
    ///     xdg_surface.configure and xdg_surface.ack_configure for details.
    ///       
    /// ## Args 
    /// 
    /// ### width
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// ### height
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// ### states
    /// 
    /// #### Type
    /// 
    ///     array
    /// 
    /// 
    pub fn next_configure(self: *const xdg_toplevel) !?struct {width: i32, height: i32, states: std.ArrayList(u8), } {
        return try self.runtime.next(self.object_id, 0, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_configure)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # close
    /// 
    /// ## Summary
    /// 
    ///     surface wants to be closed
    /// 
    /// ## Description
    /// 
    ///     The close event is sent by the compositor when the user
    ///     wants the surface to be closed. This should be equivalent to
    ///     the user clicking the close button in client-side decorations,
    ///     if your application has any.
    /// 
    ///     This is only a request that the user intends to close the
    ///     window. The client may choose to ignore this request, or show
    ///     a dialog to ask the user to save their data, etc.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn next_close(self: *const xdg_toplevel) !?struct {} {
        return try self.runtime.next(self.object_id, 1, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_close)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # configure_bounds
    /// 
    /// ## Summary
    /// 
    ///     recommended window geometry bounds
    /// 
    /// ## Description
    /// 
    ///     The configure_bounds event may be sent prior to a xdg_toplevel.configure
    ///     event to communicate the bounds a window geometry size is recommended
    ///     to constrain to.
    /// 
    ///     The passed width and height are in surface coordinate space. If width
    ///     and height are 0, it means bounds is unknown and equivalent to as if no
    ///     configure_bounds event was ever sent for this surface.
    /// 
    ///     The bounds can for example correspond to the size of a monitor excluding
    ///     any panels or other shell components, so that a surface isn't created in
    ///     a way that it cannot fit.
    /// 
    ///     The bounds may change at any point, and in such a case, a new
    ///     xdg_toplevel.configure_bounds will be sent, followed by
    ///     xdg_toplevel.configure and xdg_surface.configure.
    ///       
    /// ## Args 
    /// 
    /// ### width
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// ### height
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// 
    pub fn next_configure_bounds(self: *const xdg_toplevel) !?struct {width: i32, height: i32, } {
        return try self.runtime.next(self.object_id, 2, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_configure_bounds)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # wm_capabilities
    /// 
    /// ## Summary
    /// 
    ///     compositor capabilities
    /// 
    /// ## Description
    /// 
    ///     This event advertises the capabilities supported by the compositor. If
    ///     a capability isn't supported, clients should hide or disable the UI
    ///     elements that expose this functionality. For instance, if the
    ///     compositor doesn't advertise support for minimized toplevels, a button
    ///     triggering the set_minimized request should not be displayed.
    /// 
    ///     The compositor will ignore requests it doesn't support. For instance,
    ///     a compositor which doesn't advertise support for minimized will ignore
    ///     set_minimized requests.
    /// 
    ///     Compositors must send this event once before the first
    ///     xdg_surface.configure event. When the capabilities change, compositors
    ///     must send this event again and then send an xdg_surface.configure
    ///     event.
    /// 
    ///     The configured state should not be applied immediately. See
    ///     xdg_surface.configure for details.
    /// 
    ///     The capabilities are sent as an array of 32-bit unsigned integers in
    ///     native endianness.
    ///       
    /// ## Args 
    /// 
    /// ### capabilities
    /// 
    /// #### Type
    /// 
    ///     array
    /// 
    /// #### Summary
    /// 
    ///     array of 32-bit capabilities
    /// 
    /// 
    pub fn next_wm_capabilities(self: *const xdg_toplevel) !?struct {capabilities: std.ArrayList(u8), } {
        return try self.runtime.next(self.object_id, 3, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_wm_capabilities)).@"fn".return_type.?).error_union.payload).optional.child);
}
};

/// # xdg_popup
/// 
/// ## Summary
/// 
///     short-lived, popup surfaces for menus
/// 
/// ## Description
/// 
///       A popup surface is a short-lived, temporary surface. It can be used to
///       implement for example menus, popovers, tooltips and other similar user
///       interface concepts.
/// 
///       A popup can be made to take an explicit grab. See xdg_popup.grab for
///       details.
/// 
///       When the popup is dismissed, a popup_done event will be sent out, and at
///       the same time the surface will be unmapped. See the xdg_popup.popup_done
///       event for details.
/// 
///       Explicitly destroying the xdg_popup object will also dismiss the popup and
///       unmap the surface. Clients that want to dismiss the popup when another
///       surface of their own is clicked should dismiss the popup using the destroy
///       request.
/// 
///       A newly created xdg_popup will be stacked on top of all previously created
///       xdg_popup surfaces associated with the same xdg_toplevel.
/// 
///       The parent of an xdg_popup must be mapped (see the xdg_surface
///       description) before the xdg_popup itself.
/// 
///       The client must call wl_surface.commit on the corresponding wl_surface
///       for the xdg_popup state to take effect.
///     
pub const xdg_popup = struct {
    pub const interface = "xdg_popup";
    pub const version = 7;

    pub const enums = struct{
        pub const @"error" = enum(u32) {
            invalid_grab = 0,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # destroy
    /// 
    /// ## Summary
    /// 
    ///     remove xdg_popup interface
    /// 
    /// ## Description
    /// 
    ///     This destroys the popup. Explicitly destroying the xdg_popup
    ///     object will also dismiss the popup, and unmap the surface.
    /// 
    ///     If this xdg_popup is not the "topmost" popup, the
    ///     xdg_wm_base.not_the_topmost_popup protocol error will be sent.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn destroy(self: *const xdg_popup) !void {
        try self.runtime.sendRequest(self.object_id, 0, .{});
    }

    /// # grab
    /// 
    /// ## Summary
    /// 
    ///     make the popup take an explicit grab
    /// 
    /// ## Description
    /// 
    ///     This request makes the created popup take an explicit grab. An explicit
    ///     grab will be dismissed when the user dismisses the popup, or when the
    ///     client destroys the xdg_popup. This can be done by the user clicking
    ///     outside the surface, using the keyboard, or even locking the screen
    ///     through closing the lid or a timeout.
    /// 
    ///     If the compositor denies the grab, the popup will be immediately
    ///     dismissed.
    /// 
    ///     This request must be used in response to some sort of user action like a
    ///     button press, key press, or touch down event. The serial number of the
    ///     event should be passed as 'serial'.
    /// 
    ///     The parent of a grabbing popup must either be an xdg_toplevel surface or
    ///     another xdg_popup with an explicit grab. If the parent is another
    ///     xdg_popup it means that the popups are nested, with this popup now being
    ///     the topmost popup.
    /// 
    ///     Nested popups must be destroyed in the reverse order they were created
    ///     in, e.g. the only popup you are allowed to destroy at all times is the
    ///     topmost one.
    /// 
    ///     When compositors choose to dismiss a popup, they may dismiss every
    ///     nested grabbing popup as well. When a compositor dismisses popups, it
    ///     will follow the same dismissing order as required from the client.
    /// 
    ///     If the topmost grabbing popup is destroyed, the grab will be returned to
    ///     the parent of the popup, if that parent previously had an explicit grab.
    /// 
    ///     If the parent is a grabbing popup which has already been dismissed, this
    ///     popup will be immediately dismissed. If the parent is a popup that did
    ///     not take an explicit grab, an error will be raised.
    /// 
    ///     During a popup grab, the client owning the grab will receive pointer
    ///     and touch events for all their surfaces as normal (similar to an
    ///     "owner-events" grab in X11 parlance), while the top most grabbing popup
    ///     will always have keyboard focus.
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
    ///     the wl_seat of the user event
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
    ///     the serial of the user event
    /// 
    /// 
    pub fn grab(self: *const xdg_popup, seat: wayland_types.ObjectId, serial: u32) !void {
        try self.runtime.sendRequest(self.object_id, 1, .{seat, serial, });
    }

    /// # reposition
    /// 
    /// ## Summary
    /// 
    ///     recalculate the popup's location
    /// 
    /// ## Description
    /// 
    ///     Reposition an already-mapped popup. The popup will be placed given the
    ///     details in the passed xdg_positioner object, and a
    ///     xdg_popup.repositioned followed by xdg_popup.configure and
    ///     xdg_surface.configure will be emitted in response. Any parameters set
    ///     by the previous positioner will be discarded.
    /// 
    ///     The passed token will be sent in the corresponding
    ///     xdg_popup.repositioned event. The new popup position will not take
    ///     effect until the corresponding configure event is acknowledged by the
    ///     client. See xdg_popup.repositioned for details. The token itself is
    ///     opaque, and has no other special meaning.
    /// 
    ///     If multiple reposition requests are sent, the compositor may skip all
    ///     but the last one.
    /// 
    ///     If the popup is repositioned in response to a configure event for its
    ///     parent, the client should send an xdg_positioner.set_parent_configure
    ///     and possibly an xdg_positioner.set_parent_size request to allow the
    ///     compositor to properly constrain the popup.
    /// 
    ///     If the popup is repositioned together with a parent that is being
    ///     resized, but not in response to a configure event, the client should
    ///     send an xdg_positioner.set_parent_size request.
    ///       
    /// ## Args 
    /// 
    /// ### positioner
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Interface
    /// 
    ///     xdg_positioner
    /// 
    /// ### token
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     reposition request token
    /// 
    /// 
    pub fn reposition(self: *const xdg_popup, positioner: wayland_types.ObjectId, token: u32) !void {
        try self.runtime.sendRequest(self.object_id, 2, .{positioner, token, });
    }

    /// # configure
    /// 
    /// ## Summary
    /// 
    ///     configure the popup surface
    /// 
    /// ## Description
    /// 
    ///     This event asks the popup surface to configure itself given the
    ///     configuration. The configured state should not be applied immediately.
    ///     See xdg_surface.configure for details.
    /// 
    ///     The x and y arguments represent the position the popup was placed at
    ///     given the xdg_positioner rule, relative to the upper left corner of the
    ///     window geometry of the parent surface.
    /// 
    ///     For version 2 or older, the configure event for an xdg_popup is only
    ///     ever sent once for the initial configuration. Starting with version 3,
    ///     it may be sent again if the popup is setup with an xdg_positioner with
    ///     set_reactive requested, or in response to xdg_popup.reposition requests.
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
    ///     x position relative to parent surface window geometry
    /// 
    /// ### y
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     y position relative to parent surface window geometry
    /// 
    /// ### width
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     window geometry width
    /// 
    /// ### height
    /// 
    /// #### Type
    /// 
    ///     int
    /// 
    /// #### Summary
    /// 
    ///     window geometry height
    /// 
    /// 
    pub fn next_configure(self: *const xdg_popup) !?struct {x: i32, y: i32, width: i32, height: i32, } {
        return try self.runtime.next(self.object_id, 0, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_configure)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # popup_done
    /// 
    /// ## Summary
    /// 
    ///     popup interaction is done
    /// 
    /// ## Description
    /// 
    ///     The popup_done event is sent out when a popup is dismissed by the
    ///     compositor. The client should destroy the xdg_popup object at this
    ///     point.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn next_popup_done(self: *const xdg_popup) !?struct {} {
        return try self.runtime.next(self.object_id, 1, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_popup_done)).@"fn".return_type.?).error_union.payload).optional.child);
}

    /// # repositioned
    /// 
    /// ## Summary
    /// 
    ///     signal the completion of a repositioned request
    /// 
    /// ## Description
    /// 
    ///     The repositioned event is sent as part of a popup configuration
    ///     sequence, together with xdg_popup.configure and lastly
    ///     xdg_surface.configure to notify the completion of a reposition request.
    /// 
    ///     The repositioned event is to notify about the completion of a
    ///     xdg_popup.reposition request. The token argument is the token passed
    ///     in the xdg_popup.reposition request.
    /// 
    ///     Immediately after this event is emitted, xdg_popup.configure and
    ///     xdg_surface.configure will be sent with the updated size and position,
    ///     as well as a new configure serial.
    /// 
    ///     The client should optionally update the content of the popup, but must
    ///     acknowledge the new popup configuration for the new position to take
    ///     effect. See xdg_surface.ack_configure for details.
    ///       
    /// ## Args 
    /// 
    /// ### token
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     reposition request token
    /// 
    /// 
    pub fn next_repositioned(self: *const xdg_popup) !?struct {token: u32, } {
        return try self.runtime.next(self.object_id, 2, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_repositioned)).@"fn".return_type.?).error_union.payload).optional.child);
}
};
