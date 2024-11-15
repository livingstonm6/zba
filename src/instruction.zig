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
