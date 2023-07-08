pub const usage: []const u8 = 
\\Concatenate FILE(s) to standard output.
\\
\\With no FILE, or when FILE is -, read standard input.
\\
\\-A, --show-all
\\       equivalent to -vET (PARTIALLY IMPLEMENTED)
\\
\\-b, --number-nonblank
\\       number nonempty output lines, overrides -n
\\
\\-e     equivalent to -vE (PARTIALLY IMPLEMENTED)
\\
\\-E, --show-ends
\\       display $ at end of each line
\\
\\-n, --number
\\       number all output lines
\\
\\-s, --squeeze-blank
\\       suppress repeated empty output lines
\\
\\-t     equivalent to -vT (NOT IMPLEMENTED)
\\
\\-T, --show-tabs
\\       display TAB characters as ^I
\\
\\-u     (ignored)
\\
\\-v, --show-nonprinting
\\       use ^ and M- notation, except for LFD and TAB (NOT IMPLEMENTED)
\\
\\--help display this help and exit
\\
\\--version
\\       output version information and exit
;

pub const version = 
\\zcat - concatenate files together
\\This a cat reimplentation is written in zig to learn the language
\\Use at your own discretion!
;