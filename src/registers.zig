const CPUMode = @import("cpu.zig").CPUMode;
const RegisterType = enum { R0, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14, R15, PC, CPSR, SPSR };

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
    r15: u32 = 0,

    cpsr: u32 = 0,
    spsr_fiq: u32 = 0,
    spsr_svc: u32 = 0,
    spsr_abt: u32 = 0,
    spsr_irq: u32 = 0,
    spsr_und: u32 = 0,

    pub fn read(self: Registers, reg: RegisterType, mode: CPUMode) u32 {
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
                    CPUMode.ABT => return self.cpsr_abt,
                    CPUMode.FIQ => return self.cpsr_fiq,
                    CPUMode.IRQ => return self.cpsr_irq,
                    CPUMode.SVC => return self.cpsr_svc,
                    CPUMode.UND => return self.cpsr_und,
                    CPUMode.USER => return self.cpsr,
                }
            },
        }
    }

    pub fn write(self: Registers, reg: RegisterType, mode: CPUMode, value: u32) void {
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
                if (mode == CPUMode.FIQ) self.r9_fiq = value else self.r9;
            },
            RegisterType.R10 => {
                if (mode == CPUMode.FIQ) self.r10_fi = value else self.r10;
            },
            RegisterType.R11 => {
                if (mode == CPUMode.FIQ) self.r11_fi = value else self.r11;
            },
            RegisterType.R12 => {
                if (mode == CPUMode.FIQ) self.r12_fi = value else self.r12;
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
                    CPUMode.ABT => self.cpsr_abt = value,
                    CPUMode.FIQ => self.cpsr_fiq = value,
                    CPUMode.IRQ => self.cpsr_irq = value,
                    CPUMode.SVC => self.cpsr_svc = value,
                    CPUMode.UND => self.cpsr_und = value,
                    CPUMode.USER => self.cpsr = value,
                }
            },
        }
    }
};
