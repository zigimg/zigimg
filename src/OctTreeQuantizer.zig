const color = @import("color.zig");
const std = @import("std");

const OctTreeQuantizer = @This();

const MaxDepth = 8;

root_node: Node,
levels: [MaxDepth]NodeArrayList,
area_allocator: std.heap.ArenaAllocator,

const NodeArrayList = std.ArrayList(*Node);

pub fn init(allocator: std.mem.Allocator) OctTreeQuantizer {
    var result = OctTreeQuantizer{
        .root_node = Node{},
        .area_allocator = std.heap.ArenaAllocator.init(allocator),
        .levels = undefined,
    };
    var i: usize = 0;
    while (i < result.levels.len) : (i += 1) {
        result.levels[i] = NodeArrayList.init(allocator);
    }
    result.root_node.init(0, &result) catch unreachable;
    return result;
}

pub fn deinit(self: *OctTreeQuantizer) void {
    self.area_allocator.deinit();
    var i: usize = 0;
    while (i < self.levels.len) : (i += 1) {
        self.levels[i].deinit();
    }
}

pub fn allocateNode(self: *OctTreeQuantizer) !*Node {
    return try self.area_allocator.allocator().create(Node);
}

pub fn addLevelNode(self: *OctTreeQuantizer, level: i32, node: *Node) !void {
    try self.levels[@intCast(level)].append(node);
}

pub fn addColor(self: *OctTreeQuantizer, color_value: color.Rgba32) !void {
    try self.root_node.addColor(color_value, 0, self);
}

pub fn getPaletteIndex(self: OctTreeQuantizer, color_value: color.Rgba32) !usize {
    return try self.root_node.getPaletteIndex(color_value, 0);
}

pub fn makePalette(self: *OctTreeQuantizer, color_count: usize, palette: []color.Rgba32) anyerror![]color.Rgba32 {
    var palette_index: usize = 0;

    var root_leaf_nodes = try self.root_node.getLeafNodes(self.area_allocator.child_allocator);
    defer root_leaf_nodes.deinit();
    var leaf_count = root_leaf_nodes.items.len;

    var level: usize = MaxDepth - 1;
    while (level >= 0) : (level -= 1) {
        for (self.levels[level].items) |node| {
            leaf_count -= @intCast(node.removeLeaves());
            if (leaf_count <= color_count) {
                break;
            }
        }
        if (leaf_count <= color_count) {
            break;
        }
        try self.levels[level].resize(0);
    }

    var processed_root_leaf_nodes = try self.root_node.getLeafNodes(self.area_allocator.child_allocator);
    defer processed_root_leaf_nodes.deinit();

    for (processed_root_leaf_nodes.items) |node| {
        if (palette_index >= color_count) {
            break;
        }
        if (node.isLeaf()) {
            palette[palette_index] = node.getColor();
            node.palette_index = palette_index;
            palette_index += 1;
        }
    }

    return palette[0..palette_index];
}

const Node = struct {
    red: u32 = 0,
    green: u32 = 0,
    blue: u32 = 0,
    reference_count: u32 = 0,
    palette_index: usize = 0,
    children: [8]?*Node = undefined,

    pub fn init(self: *Node, level: i32, parent: *OctTreeQuantizer) !void {
        self.red = 0;
        self.green = 0;
        self.blue = 0;
        self.reference_count = 0;
        self.palette_index = 0;

        var i: usize = 0;
        while (i < self.children.len) : (i += 1) {
            self.children[i] = null;
        }

        if (level < (MaxDepth - 1)) {
            try parent.addLevelNode(level, self);
        }
    }

    pub fn isLeaf(self: Node) bool {
        return self.reference_count > 0;
    }

    pub fn getColor(self: Node) color.Rgba32 {
        return color.Rgba32.initRgb(@intCast(self.red / self.reference_count), @intCast(self.green / self.reference_count), @intCast(self.blue / self.reference_count));
    }

    pub fn addColor(self: *Node, color_value: color.Rgba32, level: i32, parent: *OctTreeQuantizer) anyerror!void {
        if (level >= MaxDepth) {
            self.red += color_value.r;
            self.green += color_value.g;
            self.blue += color_value.b;
            self.reference_count += 1;
            return;
        }
        const index = getColorIndex(color_value, level);
        if (index >= self.children.len) {
            return error.InvalidColorIndex;
        }
        if (self.children[index]) |child| {
            try child.addColor(color_value, level + 1, parent);
        } else {
            var new_node = try parent.allocateNode();
            try new_node.init(level, parent);
            try new_node.addColor(color_value, level + 1, parent);
            self.children[index] = new_node;
        }
    }

    pub fn getPaletteIndex(self: Node, color_value: color.Rgba32, level: i32) anyerror!usize {
        if (self.isLeaf()) {
            return self.palette_index;
        }

        const index = getColorIndex(color_value, level);

        if (self.children[index]) |child| {
            return try child.getPaletteIndex(color_value, level + 1);
        } else {
            for (self.children) |childOptional| {
                if (childOptional) |child| {
                    return try child.getPaletteIndex(color_value, level + 1);
                }
            }
        }

        return error.ColorNotFound;
    }

    pub fn getLeafNodes(self: Node, allocator: std.mem.Allocator) anyerror!NodeArrayList {
        var leaf_nodes = NodeArrayList.init(allocator);

        for (self.children) |child_opt| {
            if (child_opt) |child| {
                if (child.isLeaf()) {
                    try leaf_nodes.append(child);
                } else {
                    var child_nodes = try child.getLeafNodes(allocator);
                    defer child_nodes.deinit();
                    for (child_nodes.items) |child_node| {
                        try leaf_nodes.append(child_node);
                    }
                }
            }
        }

        return leaf_nodes;
    }

    pub fn removeLeaves(self: *Node) i32 {
        var result: i32 = 0;
        for (self.children, 0..) |child_opt, i| {
            if (child_opt) |child| {
                self.red += child.red;
                self.green += child.green;
                self.blue += child.blue;
                self.reference_count += child.reference_count;
                result += 1;
                self.children[i] = null;
            }
        }
        return result - 1;
    }

    inline fn getColorIndex(color_value: color.Rgba32, level: i32) usize {
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
