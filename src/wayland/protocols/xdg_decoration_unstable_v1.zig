const WaylandRuntime = @import("../runtime.zig").WaylandRuntime;

/// # zxdg_decoration_manager_v1
/// 
/// ## Summary
/// 
///     window decoration manager
/// 
/// ## Description
/// 
///       This interface allows a compositor to announce support for server-side
///       decorations.
/// 
///       A window decoration is a set of window controls as deemed appropriate by
///       the party managing them, such as user interface components used to move,
///       resize and change a window's state.
/// 
///       A client can use this protocol to request being decorated by a supporting
///       compositor.
/// 
///       If compositor and client do not negotiate the use of a server-side
///       decoration using this protocol, clients continue to self-decorate as they
///       see fit.
/// 
///       Warning! The protocol described in this file is experimental and
///       backward incompatible changes may be made. Backward compatible changes
///       may be added together with the corresponding interface version bump.
///       Backward incompatible changes are done by bumping the version number in
///       the protocol and interface names and resetting the interface version.
///       Once the protocol is to be declared stable, the 'z' prefix and the
///       version number in the protocol and interface names are removed and the
///       interface version number is reset.
///     
pub const zxdg_decoration_manager_v1 = struct {
    pub const version = 1;

    pub const enums = struct{    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # destroy
    /// 
    /// ## Summary
    /// 
    ///     destroy the decoration manager object
    /// 
    /// ## Description
    /// 
    ///         Destroy the decoration manager. This doesn't destroy objects created
    ///         with the manager.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn destroy() void {}

    /// # get_toplevel_decoration
    /// 
    /// ## Summary
    /// 
    ///     create a new toplevel decoration object
    /// 
    /// ## Description
    /// 
    ///         Create a new decoration object associated with the given toplevel.
    /// 
    ///         Creating an xdg_toplevel_decoration from an xdg_toplevel which has a
    ///         buffer attached or committed is a client error, and any attempts by a
    ///         client to attach or manipulate a buffer prior to the first
    ///         xdg_toplevel_decoration.configure event must also be treated as
    ///         errors.
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
    ///     zxdg_toplevel_decoration_v1
    /// 
    /// ### toplevel
    /// 
    /// #### Type
    /// 
    ///     object
    /// 
    /// #### Interface
    /// 
    ///     xdg_toplevel
    /// 
    /// 
    pub fn get_toplevel_decoration() void {}
};

/// # zxdg_toplevel_decoration_v1
/// 
/// ## Summary
/// 
///     decoration object for a toplevel surface
/// 
/// ## Description
/// 
///       The decoration object allows the compositor to toggle server-side window
///       decorations for a toplevel surface. The client can request to switch to
///       another mode.
/// 
///       The xdg_toplevel_decoration object must be destroyed before its
///       xdg_toplevel.
///     
pub const zxdg_toplevel_decoration_v1 = struct {
    pub const version = 1;

    pub const enums = struct{
        pub const @"error" = enum(u32) {
            unconfigured_buffer = 0,
            already_constructed = 1,
            orphaned = 2,
            invalid_mode = 3,
        };

        /// # mode
        /// 
        /// ## Summary
        /// 
        ///     window decoration modes
        /// 
        /// ## Description
        /// 
        ///         These values describe window decoration modes.
        ///       
        pub const mode = enum(u32) {
            client_side = 1,
            server_side = 2,
        };
    };

    object_id: u32,
    runtime: *WaylandRuntime,

    /// # destroy
    /// 
    /// ## Summary
    /// 
    ///     destroy the decoration object
    /// 
    /// ## Description
    /// 
    ///         Switch back to a mode without any server-side decorations at the next
    ///         commit.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn destroy() void {}

    /// # set_mode
    /// 
    /// ## Summary
    /// 
    ///     set the decoration mode
    /// 
    /// ## Description
    /// 
    ///         Set the toplevel surface decoration mode. This informs the compositor
    ///         that the client prefers the provided decoration mode.
    /// 
    ///         After requesting a decoration mode, the compositor will respond by
    ///         emitting an xdg_surface.configure event. The client should then update
    ///         its content, drawing it without decorations if the received mode is
    ///         server-side decorations. The client must also acknowledge the configure
    ///         when committing the new content (see xdg_surface.ack_configure).
    /// 
    ///         The compositor can decide not to use the client's mode and enforce a
    ///         different mode instead.
    /// 
    ///         Clients whose decoration mode depend on the xdg_toplevel state may send
    ///         a set_mode request in response to an xdg_surface.configure event and wait
    ///         for the next xdg_surface.configure event to prevent unwanted state.
    ///         Such clients are responsible for preventing configure loops and must
    ///         make sure not to send multiple successive set_mode requests with the
    ///         same decoration mode.
    /// 
    ///         If an invalid mode is supplied by the client, the invalid_mode protocol
    ///         error is raised by the compositor.
    ///       
    /// ## Args 
    /// 
    /// ### mode
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     the decoration mode
    /// 
    /// #### Enum
    /// 
    ///     mode
    /// 
    /// 
    pub fn set_mode() void {}

    /// # unset_mode
    /// 
    /// ## Summary
    /// 
    ///     unset the decoration mode
    /// 
    /// ## Description
    /// 
    ///         Unset the toplevel surface decoration mode. This informs the compositor
    ///         that the client doesn't prefer a particular decoration mode.
    /// 
    ///         This request has the same semantics as set_mode.
    ///       
    /// ## Args 
    /// 
    /// 
    pub fn unset_mode() void {}

    /// # configure
    /// 
    /// ## Summary
    /// 
    ///     notify a decoration mode change
    /// 
    /// ## Description
    /// 
    ///         The configure event configures the effective decoration mode. The
    ///         configured state should not be applied immediately. Clients must send an
    ///         ack_configure in response to this event. See xdg_surface.configure and
    ///         xdg_surface.ack_configure for details.
    /// 
    ///         A configure event can be sent at any time. The specified mode must be
    ///         obeyed by the client.
    ///       
    /// ## Args 
    /// 
    /// ### mode
    /// 
    /// #### Type
    /// 
    ///     uint
    /// 
    /// #### Summary
    /// 
    ///     the decoration mode
    /// 
    /// #### Enum
    /// 
    ///     mode
    /// 
    /// 
    pub fn on_configure() void {}
};
