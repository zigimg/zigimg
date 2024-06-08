const color = @import("color.zig");
const std = @import("std");

const OctTreeQuantizer = @This();

const MaxDepth = 8;

pub const Error = std.mem.Allocator.Error ||
    error{ InvalidColorIndex, ColorNotFound };

root_node: Node = .{},
levels: [MaxDepth]?*Node = [_]?*Node{null} ** MaxDepth,
area_allocator: std.heap.ArenaAllocator,

pub fn init(allocator: std.mem.Allocator) OctTreeQuantizer {
    var result = OctTreeQuantizer{
        .area_allocator = std.heap.ArenaAllocator.init(allocator),
    };
    result.root_node.init(0, &result);
    return result;
}

pub fn deinit(self: *OctTreeQuantizer) void {
    self.area_allocator.deinit();
}

pub fn allocateNode(self: *OctTreeQuantizer) Error!*Node {
    return try self.area_allocator.allocator().create(Node);
}

pub fn addLevelNode(self: *OctTreeQuantizer, level: i32, node: *Node) void {
    node.level_next = self.levels[@intCast(level)];
    self.levels[@intCast(level)] = node;
}

pub fn addColor(self: *OctTreeQuantizer, color_value: anytype) Error!void {
    try self.root_node.addColor(color_value, 0, self);
}

pub fn getPaletteIndex(self: OctTreeQuantizer, color_value: anytype) Error!usize {
    return try self.root_node.getPaletteIndex(color_value, 0);
}

pub fn makePalette(self: *OctTreeQuantizer, color_count: u32, palette: []color.Rgba32) []color.Rgba32 {
    var leaf_count = self.root_node.countLeafNodes();

    var level: u8 = MaxDepth - 1;
    while (level > 0) : (level -= 1) {
        var node_it = self.levels[level];

        while (node_it) |node| {
            leaf_count -= @intCast(node.removeLeaves());
            if (leaf_count <= color_count) {
                break;
            }
            node_it = node.level_next;
        }

        if (leaf_count <= color_count) {
            break;
        }
    }

    var make_palette_context = MakePaletteContext{ .palette = palette, .color_count = color_count };
    self.root_node.makePalette(&make_palette_context);

    return palette[0..make_palette_context.palette_index];
}

fn anyColorToRgb24(color_value: anytype) color.Rgb24 {
    const T = @TypeOf(color_value);

    if (T == color.Rgb24) {
        return color_value;
    }

    const has_alpha_type = @hasField(T, "a");
    if (has_alpha_type) {
        const premultiplied_alpha = color_value.toPremultipliedAlpha();

        return color.Rgb24.fromU32Rgba(premultiplied_alpha.toU32Rgba());
    } else {
        return color.Rgb24.fromU32Rgb(color_value.toU32Rgb());
    }
}

const MakePaletteContext = struct {
    palette: []color.Rgba32,
    palette_index: u32 = 0,
    color_count: u32 = 0,
};

const Node = struct {
    red: u32 = 0,
    green: u32 = 0,
    blue: u32 = 0,
    reference_count: u32 = 0,
    palette_index: u32 = 0,
    children: [8]?*Node = [_]?*Node{null} ** 8,
    level_next: ?*Node = null,

    pub fn init(self: *Node, level: i32, parent: *OctTreeQuantizer) void {
        self.* = Node{};

        if (level < (MaxDepth - 1)) {
            parent.addLevelNode(level, self);
        }
    }

    pub fn isLeaf(self: Node) bool {
        return self.reference_count > 0;
    }

    pub fn getColor(self: Node) color.Rgba32 {
        return color.Rgba32.initRgb(@intCast(self.red / self.reference_count), @intCast(self.green / self.reference_count), @intCast(self.blue / self.reference_count));
    }

    pub fn addColor(self: *Node, source_color: anytype, level: i32, parent: *OctTreeQuantizer) Error!void {
        if (level >= MaxDepth) {
            const color_value = anyColorToRgb24(source_color);

            self.red += color_value.r;
            self.green += color_value.g;
            self.blue += color_value.b;
            self.reference_count += 1;
            return;
        }

        const index = getColorIndex(source_color, level);
        if (index >= self.children.len) {
            return Error.InvalidColorIndex;
        }

        if (self.children[index]) |child| {
            try child.addColor(source_color, level + 1, parent);
        } else {
            var new_node = try parent.allocateNode();
            new_node.init(level, parent);
            try new_node.addColor(source_color, level + 1, parent);
            self.children[index] = new_node;
        }
    }

    pub fn getPaletteIndex(self: Node, source_color: anytype, level: i32) Error!usize {
        if (self.isLeaf()) {
            return self.palette_index;
        }

        const index = getColorIndex(source_color, level);

        if (self.children[index]) |child| {
            return try child.getPaletteIndex(source_color, level + 1);
        } else {
            for (self.children) |child_opt| {
                if (child_opt) |child| {
                    return try child.getPaletteIndex(source_color, level + 1);
                }
            }
        }

        return Error.ColorNotFound;
    }

    pub fn countLeafNodes(self: Node) usize {
        if (self.isLeaf()) {
            return 1;
        }

        var count: usize = 0;
        for (self.children) |child_opt| {
            if (child_opt) |child| {
                count += child.countLeafNodes();
            }
        }

        return count;
    }

    pub fn makePalette(self: *Node, context: *MakePaletteContext) void {
        if (self.isLeaf()) {
            if (context.palette_index >= context.color_count) {
                return;
            }

            context.palette[context.palette_index] = self.getColor();
            self.palette_index = context.palette_index;
            context.palette_index += 1;
        }

        for (self.children) |child_opt| {
            if (child_opt) |child| {
                child.makePalette(context);
            }
        }
    }

    pub fn removeLeaves(self: *Node) i32 {
        var result: i32 = 0;
        for (self.children, 0..) |child_opt, index| {
            if (child_opt) |child| {
                self.red +%= child.red;
                self.green +%= child.green;
                self.blue +%= child.blue;
                self.reference_count +%= child.reference_count;
                result += 1;
                self.children[index] = null;
            }
        }
        return result - 1;
    }

    inline fn getColorIndex(source_color: anytype, level: i32) usize {
        const color_value = anyColorToRgb24(source_color);

        var index: usize = 0;
        const mask = @as(u8, 0b10000000) >> @intCast(level);
        if (color_value.r & mask != 0) {
            index |= 0b100;
        }
        if (color_value.g & mask != 0) {
            index |= 0b010;
        }
        if (color_value.b & mask != 0) {
            index |= 0b001;
        }
        return index;
    }
};
