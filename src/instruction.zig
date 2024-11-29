const std = @import("std");
const CPUState = @import("cpu.zig").CPUState;
const CPUFlagType = @import("registers.zig").CPUFlagType;
const RegisterType = @import("registers.zig").RegisterType;

pub const Instruction = struct {
    opcode: u32,
    execute: *const fn (*Instruction, *CPUState) void = undefined,

    pub fn checkCondition(self: Instruction, state: *CPUState) bool {
        const cond: u4 = @intCast(self.opcode >> 28);
        switch (cond) {
            0b0000 => return state.reg.readFlag(CPUFlagType.Z),
            0b0001 => return !state.reg.readFlag(CPUFlagType.Z),
            0b0010 => return state.reg.readFlag(CPUFlagType.C),
            0b0011 => return !state.reg.readFlag(CPUFlagType.C),
            0b0100 => return state.reg.readFlag(CPUFlagType.N),
            0b0101 => return !state.reg.readFlag(CPUFlagType.N),
            0b0110 => return state.reg.readFlag(CPUFlagType.V),
            0b0111 => return !state.reg.readFlag(CPUFlagType.V),
            0b1000 => return (state.reg.readFlag(CPUFlagType.C) and !state.reg.readFlag(CPUFlagType.Z)),
            0b1001 => return (!state.reg.readFlag(CPUFlagType.C) or state.reg.readFlag(CPUFlagType.Z)),
            0b1010 => return (state.reg.readFlag(CPUFlagType.N) == state.reg.readFlag(CPUFlagType.V)),
            0b1011 => return (state.reg.readFlag(CPUFlagType.N) != state.reg.readFlag(CPUFlagType.V)),
            0b1100 => return (!state.reg.readFlag(CPUFlagType.Z) and (state.reg.readFlag(CPUFlagType.N) == state.reg.readFlag(CPUFlagType.V))),
            0b1101 => return (state.reg.readFlag(CPUFlagType.Z) or (state.reg.readFlag(CPUFlagType.N) != state.reg.readFlag(CPUFlagType.V))),
            0b1110 => return true,
            0b1111 => unreachable,
        }
    }
};

fn branch(self: *Instruction, state: *CPUState) void {
    std.log.debug("Executing Branch instruction", .{});
    var link = false;
    if ((self.opcode >> 24) & 1 == 1) link = true;

    std.log.debug("Link: {}", .{link});

    if (link) state.reg.write(RegisterType.R14, state.reg.r15);

    const offset: i24 = @intCast(self.opcode & 0xFFFFFF);
    const sub = offset < 0;
    const mask: u32 = 1 << 31;
    const offset_magnitude: u32 = (@as(u32, @intCast(offset << 2)) & ~mask) + 4; // add 4 due to prefetching for now

    if (sub) state.reg.r15 -= offset_magnitude else state.reg.r15 += offset_magnitude;
}

fn barrelShift(value: u32, shift: u8, state: *CPUState, carry: *u8) u32 {
    var shift_amount: u5 = undefined;
    if (shift & 1 == 1) {
        // register
        const rs: RegisterType = @enumFromInt(shift >> 4);
        shift_amount = @intCast(state.reg.read(rs) & 0xFF);
    } else {
        shift_amount = @intCast(shift >> 7);
    }

    const shift_type: u2 = @intCast((shift >> 2) & 0b11);

    switch (shift_type) {
        0b00 => {
            // logical left
            if (shift_amount > 0) {
                const temp: u33 = @as(u33, @intCast(value)) << shift_amount;
                carry.* = if (temp >> 32 == 1) '1' else '0';
                return @intCast(temp & 0xFFFFFFFF);
            }
            carry.* = '-';
            return value;
        },
        0b01 => {
            // logical right
            if (shift_amount == 0) {
                carry.* = if ((value >> 31) & 1 == 1) '1' else '0';
                return 0;
            }

            const temp = value >> @intCast(shift_amount - 1);
            carry.* = if (temp & 1 == 1) '1' else '0';
            return temp >> 1;
        },
        0b10 => {
            // arithmetic right
            const bit31 = (value >> 31);
            if (shift_amount == 0) {
                carry.* = if (bit31 == 1) '1' else '0';
                if (bit31 == 0) return 0;
                return std.math.maxInt(u32);
            }
            const temp = value >> @intCast(shift_amount - 1);
            carry.* = if (temp & 1 == 1) '1' else '0';

            if (bit31 == 0) {
                return temp >> 1;
            }

            var mask: u32 = 0;
            for (0..shift_amount) |i| {
                _ = i;
                mask = (mask << 1) | 1;
            }
            return (temp >> 1) | (mask << @intCast(31 - shift_amount));
        },
        0b11 => {
            // rotate right
            if (shift_amount == 0) {
                // RRX
                carry.* = if (value & 1 == 1) '1' else '0';
                const old_carry: u32 = if (state.reg.readFlag(CPUFlagType.C)) 1 else 0;
                return (value >> 1) | (old_carry << 31);
            }
            var mask: u32 = 0;
            for (0..(shift_amount - 1)) |i| {
                _ = i;
                mask = (mask << 1) | 1;
            }
            const bits = value & mask;

            const temp = value >> @intCast(shift_amount - 1);
            carry.* = if (temp & 1 == 1) '1' else '0';

            return (temp >> 1) | (bits << shift_amount);
        },
    }
}

fn dataProc(self: *Instruction, state: *CPUState) void {
    const opcode = (self.opcode >> 21) & 0b1111;
    const set_flags = ((self.opcode >> 20) & 0b1) == 1;
    const rn: RegisterType = @enumFromInt((self.opcode >> 16) & 0b1111);
    const rd: RegisterType = @enumFromInt((self.opcode >> 12) & 0b1111);
    const immediate_operand = (self.opcode >> 25) & 1 == 1;

    var operand1 = state.reg.read(rn);

    var operand2: u32 = undefined;
    var new_carry: u8 = '0';
    if (immediate_operand) {
        operand2 = self.opcode & 0xFF;
        // Rotate
        const rotate: u4 = 2 * @as(u4, @intCast((self.opcode >> 8) & 0b1111));
        std.log.debug("Rotate: {}", .{rotate});
        if (rotate != 0) {
            var mask: u32 = 0;
            for (0..rotate) |i| {
                _ = i;
                mask = (mask << 1) | 1;
            }

            const bits: u32 = operand2 & mask;

            const temp = operand2 >> @intCast(rotate - 1);
            new_carry = if (temp & 1 == 1) '1' else '0';

            operand2 = (temp >> 1) | (bits << (31 - @as(u5, @intCast(rotate)) + 1));
        } else {
            new_carry = '0';
        }
    } else {
        const rm: RegisterType = @enumFromInt(self.opcode & 0b1111);
        operand2 = state.reg.read(rm) & 0xFF;
        // Shift
        const shift: u8 = @intCast((self.opcode >> 4) & 0xFF);
        operand2 = barrelShift(operand2, shift, state, &new_carry);
    }
    var result: u32 = undefined;
    var write = true;
    var logical = false;
    var overflow: u1 = 0;

    std.log.debug("Operand 1: 0x{x:0>8}", .{operand1});
    std.log.debug("Operand 2: 0x{x:0>8}", .{operand2});

    switch (opcode) {
        0b0000 => {
            std.log.debug("Logical AND", .{});
            result = operand1 & operand2;
            logical = true;
        },
        0b0001 => {
            std.log.debug("Logical OR", .{});
            result = operand1 ^ operand2;
            logical = true;
        },
        0b0010 => {
            std.log.debug("SUB", .{});
            const temp = @subWithOverflow(operand1, operand2);
            result = temp[0];
            overflow = temp[1];
        },
        0b0011 => {
            std.log.debug("Reverse SUB", .{});
            const temp = @subWithOverflow(operand2, operand1);
            result = temp[0];
            overflow = temp[1];
        },
        0b0100 => {
            std.log.debug("ADD", .{});
            const temp = @addWithOverflow(operand1, operand2);
            result = temp[0];
            overflow = temp[1];
        },
        0b0101 => {
            std.log.debug("ADC", .{});
            const carry: u32 = if (state.reg.readFlag(CPUFlagType.C)) 1 else 0;
            const temp1 = @addWithOverflow(operand1, operand2);
            const temp2 = @addWithOverflow(temp1[0], carry);
            result = temp2[0];
            overflow = if (temp1[1] == 1 or temp2[1] == 1) 1 else 0;
        },
        0b0110 => {
            std.log.debug("SUBC", .{});
            const carry: u32 = if (state.reg.readFlag(CPUFlagType.C)) 1 else 0;
            operand2 = if (operand2 == 0 and carry == 0) 1 else operand2 + carry - 1;
            const temp = @subWithOverflow(operand1, operand2);
            result = temp[0];
            overflow = temp[1];
        },
        0b0111 => {
            std.log.debug("Reverse SUBC", .{});
            const carry: u32 = if (state.reg.readFlag(CPUFlagType.C)) 1 else 0;
            operand1 = if (operand1 == 0 and carry == 0) 1 else operand1 + carry - 1;
            const temp = @subWithOverflow(operand2, operand1);
            result = temp[0];
            overflow = temp[1];
        },
        0b1000 => {
            if (!set_flags) {
                // MRS
            }

            std.log.debug("TST (AND No Write)", .{});
            result = operand1 & operand2;
            logical = true;
            write = false;
        },
        0b1001 => {
            std.log.debug("TEQ (EOR No Write)", .{});
            result = operand1 ^ operand2;
            logical = true;
            write = false;
        },
        0b1010 => {
            std.log.debug("CMP (SUB No Write)", .{});
            const temp = @subWithOverflow(operand1, operand2);
            result = temp[0];
            overflow = temp[1];
            write = false;
        },
        0b1011 => {
            std.log.debug("CMN (ADD No Write)", .{});
            const temp = @addWithOverflow(operand1, operand2);
            result = temp[0];
            overflow = temp[1];
            write = false;
        },
        0b1100 => {
            std.log.debug("Logical OR", .{});
            result = operand1 | operand2;
            logical = true;
        },
        0b1101 => {
            std.log.debug("MOV", .{});
            result = operand2;
            logical = true;
        },
        0b1110 => {
            std.log.debug("BIC", .{});
            result = operand1 & ~operand2;
            logical = true;
        },
        0b1111 => {
            std.log.debug("MVN", .{});
            result = ~operand2;
            logical = true;
        },
        else => unreachable,
    }

    if (write) state.reg.write(rd, result);

    if (set_flags) {
        const n: u8 = if (result >> 31 == 1) '1' else '0'; // negative / less than
        const z: u8 = if (result == 0) '1' else '0'; // zero
        const c: u8 = if (new_carry == 1) '1' else '0'; // carry / borrow / extend
        var v: u8 = '-'; // overflow

        if (!logical) {
            v = if (overflow == 1) '1' else '0';
        }

        state.reg.setFlags(n, z, c, v);
    }
}

fn singleDataTransfer(self: *Instruction, state: *CPUState) void {
    std.log.debug("Single data transfer", .{});
    const immediate_offset = (self.opcode >> 25) & 1 == 1;
    const pre_indexing = (self.opcode >> 24) & 1 == 1;
    const up = (self.opcode >> 23) & 1 == 1;
    const byte = (self.opcode >> 22) & 1 == 1;
    const write_back = (self.opcode >> 21) & 1 == 1;
    const load = (self.opcode >> 20) & 1 == 1;
    std.log.debug("Immediate offset: {}", .{immediate_offset});
    std.log.debug("Pre-indexing: {}", .{pre_indexing});
    std.log.debug("Up: {}", .{up});
    std.log.debug("Byte: {}", .{byte});
    std.log.debug("Write back: {}", .{write_back});
    std.log.debug("Load: {}", .{load});

    const rn: RegisterType = @enumFromInt((self.opcode >> 16) & 0b1111);
    const rd: RegisterType = @enumFromInt((self.opcode >> 12) & 0b1111);
    std.log.debug("Rn: {?s}", .{std.enums.tagName(RegisterType, rn)});
    std.log.debug("Rd: {?s}", .{std.enums.tagName(RegisterType, rd)});

    var offset: u32 = undefined;

    if (immediate_offset) {
        offset = self.opcode & 0xFFF;
    } else {
        const rm: RegisterType = @enumFromInt(self.opcode & 0b1111);
        const rm_value = state.reg.read(rm);
        const shift: u8 = @intCast((self.opcode >> 4) & 0xFF);
        var carry: u8 = 0;
        offset = barrelShift(rm_value, shift, state, &carry);
    }

    std.log.debug("Offset: 0x{x:0>8}", .{offset});

    const base = state.reg.read(rn);

    var address = if (!pre_indexing) base else if (up) base + offset else base - offset;

    std.log.debug("Address: 0x{x:0>8}", .{address});
    // Transfer
    if (load) {
        const value: u32 = if (byte) @intCast(state.bus.read8(address)) else state.bus.read32(address);
        state.reg.write(rd, value);
    } else {
        var value = state.reg.read(rd);
        if (byte) {
            value &= 0xFF;
            value |= (value << 8);
            value |= (value << 16);
        }

        state.bus.write32(address, value);
    }

    if (!pre_indexing) {
        if (up) address += offset else address -= offset;
    }
    if (write_back) state.reg.write(rn, address);
}

pub fn decodeOpcode(opcode: u32) Instruction {
    var inst = Instruction{ .opcode = opcode };

    if (((opcode >> 25) & 0b111) == 0b101) {
        inst.execute = branch;
    } else if (((opcode >> 25) & 0b111) == 0b001) {
        // Data processing with immediate
        inst.execute = dataProc;
    } else if (((opcode >> 26) & 0b11 == 1) and ((opcode >> 4) & 1 != 1)) {
        inst.execute = singleDataTransfer;
    } else {
        std.log.debug("ERROR: Unrecognized opcode", .{});
        unreachable;
    }

    return inst;
}
