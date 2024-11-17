const std = @import("std");
const CPUMode = @import("cpu.zig").CPUMode;

pub const RegisterType = enum { R0, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14, R15, PC, CPSR, SPSR };
pub const CPUFlagType = enum(u5) { N, Z, C, V };

pub const Registers = struct {
    r0: u32 = 0,
    r1: u32 = 0,
    r2: u32 = 0,
    r3: u32 = 0,
    r4: u32 = 0,
    r5: u32 = 0,
    r6: u32 = 0,
    r7: u32 = 0,

    r8: u32 = 0,
    r8_fiq: u32 = 0,

    r9: u32 = 0,
    r9_fiq: u32 = 0,

    r10: u32 = 0,
    r10_fiq: u32 = 0,

    r11: u32 = 0,
    r11_fiq: u32 = 0,

    r12: u32 = 0,
    r12_fiq: u32 = 0,

    r13: u32 = 0,
    r13_fiq: u32 = 0,
    r13_svc: u32 = 0,
    r13_abt: u32 = 0,
    r13_irq: u32 = 0,
    r13_und: u32 = 0,

    r14: u32 = 0,
    r14_fiq: u32 = 0,
    r14_svc: u32 = 0,
    r14_abt: u32 = 0,
    r14_irq: u32 = 0,
    r14_und: u32 = 0,

    // PC
    r15: u32 = 0x00000000,

    cpsr: u32 = 0b10000,
    spsr_fiq: u32 = 0,
    spsr_svc: u32 = 0,
    spsr_abt: u32 = 0,
    spsr_irq: u32 = 0,
    spsr_und: u32 = 0,

    pub fn print(self: Registers) void {
        const mode = self.getCPUMode();
        const r0 = self.read(RegisterType.R0);
        const r1 = self.read(RegisterType.R1);
        const r2 = self.read(RegisterType.R2);
        const r3 = self.read(RegisterType.R3);
        const r4 = self.read(RegisterType.R4);
        const r5 = self.read(RegisterType.R5);
        const r6 = self.read(RegisterType.R6);
        const r7 = self.read(RegisterType.R7);
        const r8 = self.read(RegisterType.R8);
        const r9 = self.read(RegisterType.R9);
        const r10 = self.read(RegisterType.R10);
        const r11 = self.read(RegisterType.R11);
        const r12 = self.read(RegisterType.R12);
        const r13 = self.read(RegisterType.R13);
        const r14 = self.read(RegisterType.R14);
        const r15 = self.read(RegisterType.R15);
        const cpsr = self.read(RegisterType.CPSR);

        std.log.debug("CPU Mode: {?s}", .{std.enums.tagName(CPUMode, mode)});
        std.log.debug(" r0: 0x{x:0>8}    r1: 0x{x:0>8}   r2: 0x{x:0>8}   r3: 0x{x:0>8}   r4: 0x{x:0>8}", .{ r0, r1, r2, r3, r4 });
        std.log.debug(" r5: 0x{x:0>8}    r6: 0x{x:0>8}   r7: 0x{x:0>8}   r8: 0x{x:0>8}   r9: 0x{x:0>8}", .{ r5, r6, r7, r8, r9 });
        std.log.debug("r10: 0x{x:0>8}   r11: 0x{x:0>8}  r12: 0x{x:0>8}  r13: 0x{x:0>8}  r14: 0x{x:0>8}", .{ r10, r11, r12, r13, r14 });
        std.log.debug("r15: 0x{x:0>8}  CPSR: 0x{x:0>8}\n", .{ r15, cpsr });
    }

    pub fn getCPUMode(self: Registers) CPUMode {
        const bits: u5 = @intCast(self.cpsr & 0b11111);

        switch (bits) {
            0b10000 => return CPUMode.USER,
            0b10001 => return CPUMode.FIQ,
            0b10010 => return CPUMode.IRQ,
            0b10011 => return CPUMode.SVC,
            0b10111 => return CPUMode.ABT,
            0b11011 => return CPUMode.UND,
            0b11111 => return CPUMode.USER,
            else => unreachable,
        }
    }

    pub fn readFlag(self: Registers, flag: CPUFlagType) bool {
        const status_reg = self.read(RegisterType.CPSR);

        return (status_reg >> (28 + @intFromEnum(flag))) == 1;
    }

    pub fn setFlags(self: *Registers, n: u8, z: u8, c: u8, v: u8) void {
        const flags = .{ n, z, c, v };

        for (flags, 0..) |flag, i| {
            const mask: u32 = 1 << (28 + i);
            if (flag == '1') {
                self.cpsr |= mask;
            } else if (flag == '0') {
                self.cpsr &= ~mask;
            }
        }
    }

    pub fn read(self: Registers, reg: RegisterType) u32 {
        const mode = self.getCPUMode();
        switch (reg) {
            RegisterType.R0 => return self.r0,
            RegisterType.R1 => return self.r1,
            RegisterType.R2 => return self.r2,
            RegisterType.R3 => return self.r3,
            RegisterType.R4 => return self.r4,
            RegisterType.R5 => return self.r5,
            RegisterType.R6 => return self.r6,
            RegisterType.R7 => return self.r7,
            RegisterType.R8 => {
                if (mode == CPUMode.FIQ) return self.r8_fiq;
                return self.r8;
            },
            RegisterType.R9 => {
                if (mode == CPUMode.FIQ) return self.r9_fiq;
                return self.r9;
            },
            RegisterType.R10 => {
                if (mode == CPUMode.FIQ) return self.r10_fiq;
                return self.r10;
            },
            RegisterType.R11 => {
                if (mode == CPUMode.FIQ) return self.r11_fiq;
                return self.r11;
            },
            RegisterType.R12 => {
                if (mode == CPUMode.FIQ) return self.r12_fiq;
                return self.r12;
            },
            RegisterType.R13 => {
                switch (mode) {
                    CPUMode.ABT => return self.r13_abt,
                    CPUMode.FIQ => return self.r13_fiq,
                    CPUMode.IRQ => return self.r13_irq,
                    CPUMode.SVC => return self.r13_svc,
                    CPUMode.UND => return self.r13_und,
                    CPUMode.USER => return self.r13,
                }
            },
            RegisterType.R14 => {
                switch (mode) {
                    CPUMode.ABT => return self.r14_abt,
                    CPUMode.FIQ => return self.r14_fiq,
                    CPUMode.IRQ => return self.r14_irq,
                    CPUMode.SVC => return self.r14_svc,
                    CPUMode.UND => return self.r14_und,
                    CPUMode.USER => return self.r14,
                }
            },
            RegisterType.R15 => return self.r15,
            RegisterType.PC => return self.r15,
            RegisterType.CPSR => return self.cpsr,
            RegisterType.SPSR => {
                switch (mode) {
                    CPUMode.ABT => return self.spsr_abt,
                    CPUMode.FIQ => return self.spsr_fiq,
                    CPUMode.IRQ => return self.spsr_irq,
                    CPUMode.SVC => return self.spsr_svc,
                    CPUMode.UND => return self.spsr_und,
                    CPUMode.USER => unreachable,
                }
            },
        }
    }

    pub fn write(self: *Registers, reg: RegisterType, value: u32) void {
        const mode = self.getCPUMode();
        switch (reg) {
            RegisterType.R0 => self.r0 = value,
            RegisterType.R1 => self.r1 = value,
            RegisterType.R2 => self.r2 = value,
            RegisterType.R3 => self.r3 = value,
            RegisterType.R4 => self.r4 = value,
            RegisterType.R5 => self.r5 = value,
            RegisterType.R6 => self.r6 = value,
            RegisterType.R7 => self.r7 = value,
            RegisterType.R8 => {
                if (mode == CPUMode.FIQ) self.r8_fiq = value else self.r8 = value;
            },
            RegisterType.R9 => {
                if (mode == CPUMode.FIQ) self.r9_fiq = value else self.r9 = value;
            },
            RegisterType.R10 => {
                if (mode == CPUMode.FIQ) self.r10_fiq = value else self.r10 = value;
            },
            RegisterType.R11 => {
                if (mode == CPUMode.FIQ) self.r11_fiq = value else self.r11 = value;
            },
            RegisterType.R12 => {
                if (mode == CPUMode.FIQ) self.r12_fiq = value else self.r12 = value;
            },
            RegisterType.R13 => {
                switch (mode) {
                    CPUMode.ABT => self.r13_abt = value,
                    CPUMode.FIQ => self.r13_fiq = value,
                    CPUMode.IRQ => self.r13_irq = value,
                    CPUMode.SVC => self.r13_svc = value,
                    CPUMode.UND => self.r13_und = value,
                    CPUMode.USER => self.r13 = value,
                }
            },
            RegisterType.R14 => {
                switch (mode) {
                    CPUMode.ABT => self.r14_abt = value,
                    CPUMode.FIQ => self.r14_fiq = value,
                    CPUMode.IRQ => self.r14_irq = value,
                    CPUMode.SVC => self.r14_svc = value,
                    CPUMode.UND => self.r14_und = value,
                    CPUMode.USER => self.r14 = value,
                }
            },
            RegisterType.R15 => self.r15 = value,
            RegisterType.PC => self.r15 = value,
            RegisterType.CPSR => self.cpsr = value,
            RegisterType.SPSR => {
                switch (mode) {
                    CPUMode.ABT => self.spsr_abt = value,
                    CPUMode.FIQ => self.spsr_fiq = value,
                    CPUMode.IRQ => self.spsr_irq = value,
                    CPUMode.SVC => self.spsr_svc = value,
                    CPUMode.UND => self.spsr_und = value,
                    CPUMode.USER => unreachable,
                }
            },
        }
    }
};
