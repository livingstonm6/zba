const std = @import("std");
const MemoryBus = @import("bus.zig").MemoryBus;
const Registers = @import("registers.zig").Registers;
const decodeOpcode = @import("instruction.zig").decodeOpcode;

pub const CPUMode = enum { USER, FIQ, SVC, ABT, IRQ, UND };

pub const CPUState = struct {
    reg: Registers = Registers{},
    opcode: u32 = undefined,
    mode: CPUMode = CPUMode.USER,
};

pub const CPU = struct {
    bus: *const MemoryBus,
    running: bool = true,
    state: CPUState = CPUState{},

    pub fn step(self: *CPU) void {
        std.log.debug("CPU STEP PC: 0x{x}", .{self.state.reg.r15});

        self.state.opcode = self.bus.read32(self.state.reg.r15);
        self.state.reg.r15 += 4;
        std.log.debug("Opcode: {b} ({x})", .{ self.state.opcode, self.state.opcode });

        var instruction = decodeOpcode(self.state.opcode);
        if (instruction.checkCondition(&self.state)) instruction.execute(&instruction, &self.state) else std.log.debug("Condition failed", .{});

        self.state.reg.print();
    }
};
