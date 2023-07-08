const std = @import("std");
const help = @import("help.zig");
const mem = std.mem;
const os = std.os;
const fs = std.fs;

const Flags = struct {
    number_nonblank: bool = false,
    show_ends: bool = false,
    number: bool = false,
    squeeze_blank: bool = false,
    show_tabs: bool = false,
    show_nonprinting: bool = false,
    ignored: bool = false,
    stdin: bool = false,
};

pub fn count_digits(comptime num_type: type,number: num_type) usize {
    var count: usize = 0;
    var temp_number = number;
    while (temp_number != 0) : (count += 1) temp_number /= 10;
    return count;
}

pub fn main() !void {
    //Allocator setup
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    //preparing all the differnt ins and outs
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    const stderr = std.io.getStdErr().writer();
    const stdin = std.io.getStdIn().reader();

    //Time to read the args and put them into a iterator
    var args = try std.process.argsWithAllocator(allocator);
    _ = args.skip();
    defer args.deinit();

    //ArrayList of all the filenames from args that will be parsed by the while loop further down
    var files = std.ArrayList([]const u8).init(allocator);
    defer files.deinit();

    //ArrayList for all the characters we are gonna read from the files in the arguments
    //Basically becomes one large string, splitting by newline characters comes later
    var contents = std.ArrayList(u8).init(allocator);
    defer contents.deinit();

    //This while will parse all the different arguments
    var flags: Flags = .{};
    while (args.next()) |arg| {
        if (mem.eql(u8, arg, "--version")) {
            try stdout.print("{s}\n", .{help.version});
            os.exit(0);
        }
        if (mem.eql(u8, arg, "--help")) {
            try stdout.print("{s}\n", .{help.usage});
            os.exit(0);
        }

        if (arg[0] == '-' and arg.len == 1) try files.append("-");

        if (arg[0] == '-') for (arg[1..]) |char| switch (char) {
            'A' => {
                flags.show_nonprinting = true;
                flags.show_ends = true;
                flags.show_tabs = true;
            },
            'b' => {
                flags.number_nonblank = true;
                flags.number = true;
            },
            'e' => {
                flags.show_nonprinting = true;
                flags.show_ends = true;
            },
            'E' => flags.show_ends = true,
            'n' => flags.number = true,
            's' => flags.squeeze_blank = true,
            't' => {
                flags.show_nonprinting = true;
                flags.show_tabs = true;
            },
            'T' => flags.show_tabs = true,
            'u' => flags.ignored = true,
            'v' => flags.show_nonprinting = true,
            else => {
                try stderr.print("{c} is not a valid flag\nCheck the --help flag for more info\n", .{char});
                os.exit(1);
            },
        };
        if (arg[0] != '-') try files.append(arg);
    }

    for (files.items) |value| {
        //Handle stdin
        if (mem.eql(u8, value, "-")) {
            flags.stdin = false;
            var stdin_size = try stdin.context.getEndPos();
            try stdin.readAllArrayList(&contents, stdin_size);
            continue;
        }

        //Get the absolute path for the files in the arguments
        var buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
        const cwd = try std.os.getcwd(&buf);
        const path = try fs.path.join(allocator, &[_][]const u8{ cwd, value });
        defer allocator.free(path);

        //Time to open all the files and add their contents to a ArrayList
        const file = try fs.openFileAbsolute(path, .{});
        defer file.close();
        const file_length = try file.getEndPos();
        const text = try file.readToEndAlloc(allocator, file_length);
        defer allocator.free(text);
        try contents.appendSlice(text);
    }

    var line_number: usize = 1;
    var iter = mem.splitAny(u8, contents.items, "\n");
    var first_occurance_empty_line: bool = true;
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();
    while (iter.next()) |line| : (line_number += 1) {
        //Remove repeating blank lines
        if (flags.squeeze_blank and line.len == 0) {
            if (first_occurance_empty_line) first_occurance_empty_line = false else continue;
        } else first_occurance_empty_line = true;

        //number lines if number flag is set and dont number when number_nonblank flag is set and it is an actual empty line
        if (flags.number and !(flags.number_nonblank and line.len == 0)) {
            var digits = 6 - count_digits(usize, line_number);
            while (digits > 0) : (digits -= 1) {
                try buffer.append(' ');
            }
            try buffer.appendSlice(try std.fmt.allocPrint(allocator, "{d}", .{line_number}));
            try buffer.append(' ');
        } else line_number -= 1;

        //Time to write!
        if (flags.show_nonprinting or flags.show_tabs) {
            for (line) |char| {
                // Replace tabs with ^I if showtabs flag is set
                if (flags.show_tabs and char == '\t') try buffer.appendSlice("I^");
                // Replace different nonprintable characters printable ones
                if (flags.show_nonprinting) switch (char) {
                    '\r' => try buffer.appendSlice("^M"),
                    '\x08' => try buffer.appendSlice("^H"),
                    '\x07' => try buffer.appendSlice("^G"),
                    '\x7F' => try buffer.appendSlice("^?"),
                    else => try buffer.append(char),
                };
                //else just write the character
                try buffer.append(char);
            }
        } else try buffer.appendSlice(line);
        //This will show the ending of the line with a dollarsign
        if (flags.show_ends) try buffer.append('$');
        //A newline to end the line
        try buffer.append('\n');
    }
    try stdout.print("{s}", .{buffer.items});
    try bw.flush();
}
