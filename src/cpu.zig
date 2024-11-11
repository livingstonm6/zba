const std = @import("std");
const MemoryBus = @import("bus.zig").MemoryBus;
const Registers = @import("registers.zig").Registers;

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
        std.log.debug("CPU STEP PC: {}", .{self.state.reg.r15});

        // Fetch opcode
        self.state.opcode = self.bus.read32(self.state.reg.r15);
        std.log.debug("Opcode: {b}", .{self.state.opcode});

        // TODO Execute instruction
        self.running = false;
    }
};
