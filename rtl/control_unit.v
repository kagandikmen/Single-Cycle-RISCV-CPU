// Control unit of the CPU
// Created:     2024-01-25
// Modified:    2025-05-29
// Author:      Kagan Dikmen

module control_unit
    (
    input [31:0] instr,
    input is_misaligned,

    // multiplexer select signals
    output reg alu_imm_select,
    output reg [1:0] alu_pc_select,
    output reg [1:0] rf_w_select,

    // to ALU
    output reg alu_mux1_select,
    output reg [1:0] alu_mux2_select,
    output reg [3:0] alu_op_select,
    

    // to register file
    output reg w_en_rf,

    // to PC counter
    output reg branch,
    output reg jump,

    output reg ecall,
    output reg ebreak,
    output reg mret,

    output reg [3:0] ldst_mask,
    output reg ldst_is_unsigned,
    output reg st_en,

    // to CSR unit
    output reg csr_r_en,
    output reg csr_w_en,
    output reg [2:0] csr_op,
    output reg [11:0] csr_addr,
    output reg [1:0] csr_imm_select
    );

    `include "../lib/common_library.vh"

    wire [16:0] instr_compressed;

    assign instr_compressed = {instr[14:12], instr[6:0]};

    always @(*)
    begin

        alu_imm_select = 1'b1;     // choose the immediate
        alu_pc_select = 2'b0;      // don't select PC at ALU
        branch = 1'b0;
        jump = 1'b0;
        st_en = 1'b0;
        csr_r_en = 1'b0;
        csr_w_en = 1'b0;
        csr_addr = 12'b0;
        csr_imm_select = 2'b0;
        csr_op = 3'b000;
        mret = 1'b0;
        ecall = 1'b0;
        ebreak = 1'b0;
        ldst_is_unsigned = 1'b0;
        ldst_mask = 4'b0000;
        
        case (instr_compressed)
            {FUNCT3_ADD, R_OPCODE}: // ADD / SUB
            begin
                if (instr[30] == 1'b0)      // ADD
                begin
                    alu_imm_select = 1'b0;
                    alu_mux1_select = 1'b0;
                    alu_mux2_select = 2'b00; 
                    alu_op_select = 4'b0000;
                    w_en_rf = 1'b1;
                    rf_w_select = 2'b00;
                end
                else                        // SUB
                begin
                    alu_imm_select = 1'b0;
                    alu_mux1_select = 1'b0;
                    alu_mux2_select = 2'b00; 
                    alu_op_select = 4'b1000;
                    w_en_rf = 1'b1;
                    rf_w_select = 2'b00;
                end
            end
            {FUNCT3_SLL, R_OPCODE}: // SLL
            begin
                alu_imm_select = 1'b0;
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b10;
                alu_op_select = 4'b0011;
                w_en_rf = 1'b1;
                rf_w_select = 2'b00;
            end
            {FUNCT3_SLT, R_OPCODE}: // SLT
            begin
                alu_imm_select = 1'b0;
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b11;
                alu_op_select = 4'b0011;
                w_en_rf = 1'b1;
                rf_w_select = 2'b00;
            end
            {FUNCT3_SLTU, R_OPCODE}: // SLTU
            begin
                alu_imm_select = 1'b0;
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b11;
                alu_op_select = 4'b0111;
                w_en_rf = 1'b1;
                rf_w_select = 2'b00;
            end
            {FUNCT3_XOR, R_OPCODE}: // XOR
            begin
                alu_imm_select = 1'b0;
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b01;
                alu_op_select = 4'b0100;
                w_en_rf = 1'b1;
                rf_w_select = 2'b00;
            end
            {FUNCT3_SRL, R_OPCODE}: // SRL / SRA
            begin
                if (instr[30] == 1'b0)  // SRL
                begin
                    alu_imm_select = 1'b0;
                    alu_mux1_select = 1'b0;
                    alu_mux2_select = 2'b10; 
                    alu_op_select = 4'b0001; 
                    w_en_rf = 1'b1;
                    rf_w_select = 2'b00;
                end
                else                    // SRA
                begin
                    alu_imm_select = 1'b0;
                    alu_mux1_select = 1'b0;
                    alu_mux2_select = 2'b10;
                    alu_op_select = 4'b0111;
                    w_en_rf = 1'b1;
                    rf_w_select = 2'b00;
                end
            end
            {FUNCT3_OR, R_OPCODE}: // OR
            begin
                alu_imm_select = 1'b0;
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b01;
                alu_op_select = 4'b0110;
                w_en_rf = 1'b1;
                rf_w_select = 2'b00;
            end
            {FUNCT3_AND, R_OPCODE}: // AND
            begin
                alu_imm_select = 1'b0;
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b01; 
                alu_op_select = 4'b0111; 
                w_en_rf = 1'b1;
                rf_w_select = 2'b00;
            end
            {FUNCT3_ADDI, I_OPCODE}: // ADDI
            begin
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b00;
                alu_op_select = 4'b0000;
                w_en_rf = 1'b1;
                rf_w_select = 2'b00;
            end
            {FUNCT3_SLTI, I_OPCODE}: // SLTI
            begin
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b11;
                alu_op_select = 4'b0011;
                w_en_rf = 1'b1;
                rf_w_select = 2'b00;
            end
            {FUNCT3_SLTIU, I_OPCODE}: // SLTIU
            begin
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b11;
                alu_op_select = 4'b0111;
                w_en_rf = 1'b1;
                rf_w_select = 2'b00;
            end
            {FUNCT3_XORI, I_OPCODE}: // XORI
            begin
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b01; 
                alu_op_select = 4'b0100;
                w_en_rf = 1'b1;
                rf_w_select = 2'b00;
            end
            {FUNCT3_ORI, I_OPCODE}: // ORI
            begin
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b01; 
                alu_op_select = 4'b0110;
                w_en_rf = 1'b1;
                rf_w_select = 2'b00;
            end
            {FUNCT3_ANDI, I_OPCODE}: // ANDI
            begin
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b01;
                alu_op_select = 4'b0111;
                w_en_rf = 1'b1;
                rf_w_select = 2'b00;
            end
            {FUNCT3_SLLI, I_OPCODE}: // SLLI
            begin
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b10;
                alu_op_select = 4'b0011;
                w_en_rf = 1'b1;
                rf_w_select = 2'b00;
            end
            {FUNCT3_SRLI, I_OPCODE}: // SRLI / SRAI
            begin
                if (instr[30] == 1'b0)      // SRLI
                begin
                    alu_mux1_select = 1'b0;
                    alu_mux2_select = 2'b10;
                    alu_op_select = 4'b0001;
                    w_en_rf = 1'b1;
                    rf_w_select = 2'b00;
                end
                else                        // SRAI
                begin
                    alu_mux1_select = 1'b0;
                    alu_mux2_select = 2'b10;
                    alu_op_select = 4'b0111;
                    w_en_rf = 1'b1;
                    rf_w_select = 2'b00;
                end
            end
            {FUNCT3_LB, LOAD_OPCODE}: // LB
            begin
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b00;
                alu_op_select = 4'b0000; 
                w_en_rf = 1'b1;
                rf_w_select = 2'b01;
                ldst_mask = 4'b0001;
            end
            {FUNCT3_LH, LOAD_OPCODE}: // LH
            begin
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b00;
                alu_op_select = 4'b0000; 
                w_en_rf = 1'b1;
                rf_w_select = 2'b01;
                ldst_mask = 4'b0011;
            end
            {FUNCT3_LW, LOAD_OPCODE}: // LW
            begin
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b00;
                alu_op_select = 4'b0000; 
                w_en_rf = 1'b1;
                rf_w_select = 2'b01;
                ldst_mask = 4'b1111;
            end
            {FUNCT3_LBU, LOAD_OPCODE}: // LBU
            begin
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b00;
                alu_op_select = 4'b0000; 
                w_en_rf = 1'b1;
                rf_w_select = 2'b01;
                ldst_is_unsigned = 1'b1;
                ldst_mask = 4'b0001;
            end
            {FUNCT3_LHU, LOAD_OPCODE}: // LHU
            begin
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b00;
                alu_op_select = 4'b0000; 
                w_en_rf = 1'b1;
                rf_w_select = 2'b01;
                ldst_is_unsigned = 1'b1;
                ldst_mask = 4'b0011;
            end
            {FUNCT3_SB, S_OPCODE}:  // SB
            begin
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b00; 
                alu_op_select = 4'b0000;
                w_en_rf = 1'b0;
                rf_w_select = 2'b00;
                ldst_mask = 4'b0001;
                st_en = 1'b1;
            end
            {FUNCT3_SH, S_OPCODE}:  // SH
            begin
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b00; 
                alu_op_select = 4'b0000;
                w_en_rf = 1'b0;
                rf_w_select = 2'b00;
                ldst_mask = 4'b0011;
                st_en = 1'b1;
            end
            {FUNCT3_SW, S_OPCODE}:  // SW
            begin
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b00; 
                alu_op_select = 4'b0000;
                w_en_rf = 1'b0;
                rf_w_select = 2'b00;
                ldst_mask = 4'b1111;
                st_en = 1'b1;
            end
            {FUNCT3_BEQ, B_OPCODE}: // BEQ
            begin
                alu_pc_select = 2'b01;
                alu_mux1_select = 1'b1;
                alu_mux2_select = 2'b00;
                alu_op_select = 4'b0000;
                branch = 1'b1; 
                w_en_rf = 1'b0;
                rf_w_select = 2'b00;
            end
            {FUNCT3_BNE, B_OPCODE}: // BNE
            begin
                alu_pc_select = 2'b01;
                alu_mux1_select = 1'b1;
                alu_mux2_select = 2'b00;
                alu_op_select = 4'b0001; 
                branch = 1'b1;
                w_en_rf = 1'b0;
                rf_w_select = 2'b00;
            end
            {FUNCT3_BLT, B_OPCODE}: // BLT
            begin
                alu_pc_select = 2'b01;
                alu_mux1_select = 1'b1;
                alu_mux2_select = 2'b00;
                alu_op_select = 4'b0011; 
                branch = 1'b1;
                w_en_rf = 1'b0;
                rf_w_select = 2'b00;
            end
            {FUNCT3_BGE, B_OPCODE}: // BGE
            begin
                alu_pc_select = 2'b01;
                alu_mux1_select = 1'b1;
                alu_mux2_select = 2'b00;
                alu_op_select = 4'b0010; 
                branch = 1'b1;
                w_en_rf = 1'b0;
                rf_w_select = 2'b00;
            end
            {FUNCT3_BLTU, B_OPCODE}: // BLTU
            begin
                alu_pc_select = 2'b01;
                alu_mux1_select = 1'b1;
                alu_mux2_select = 2'b00;
                alu_op_select = 4'b0111; 
                branch = 1'b1;
                w_en_rf = 1'b0;
                rf_w_select = 2'b00;
            end
            {FUNCT3_BGEU, B_OPCODE}: // BGEU
            begin
                alu_pc_select = 2'b01;
                alu_mux1_select = 1'b1;
                alu_mux2_select = 2'b00;
                alu_op_select = 4'b0110;
                branch = 1'b1; 
                w_en_rf = 1'b0;
                rf_w_select = 2'b00;
            end
            {FUNCT3_FENCE, FENCE_OPCODE}:   // FENCE
            begin
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b00; 
                alu_op_select = 4'b0000;
                w_en_rf = 1'b0;
                rf_w_select = 2'b00;
            end
            {FUNCT3_FENCEI, FENCE_OPCODE}:  // FENCE.I
            begin
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b00; 
                alu_op_select = 4'b0000;
                w_en_rf = 1'b0;
                rf_w_select = 2'b00;
            end
            {FUNCT3_ECALL_EBREAK, SYSTEM_OPCODE}:
            begin
                alu_pc_select = 2'b00;
                alu_mux1_select = 1'b0;
                alu_mux2_select = 2'b00;
                alu_op_select = 4'b0000;   
                alu_imm_select = 1'b1;
                w_en_rf = 1'b0;
                rf_w_select = 2'b00;
                csr_r_en = 1'b1;
                csr_w_en = 1'b0;
                csr_op = 3'b000;
                case (instr[31:20])
                    12'h000:    // ECALL
                    begin
                        ecall = 1'b1;
                        csr_addr <= CSR_MTVEC_ADDR;
                    end
                    12'h001:    // EBREAK
                    begin
                        ebreak = 1'b1;
                        csr_addr <= CSR_MTVEC_ADDR;
                    end
                    12'h302:    // MRET
                    begin
                        mret = 1'b1;
                        csr_addr <= CSR_MEPC_ADDR;
                    end
                endcase
            end
            {FUNCT3_CSRRW, SYSTEM_OPCODE}:
            begin
                alu_pc_select = 2'b00;
                alu_mux2_select = 2'b00;
                alu_op_select = 4'b0000;  
                alu_imm_select = 1'b1;
                w_en_rf = (instr[11:7] == 5'b00000) ? 1'b0 : 1'b1;
                rf_w_select = 2'b11;
                csr_r_en = (instr[11:7] == 5'b00000) ? 1'b0 : 1'b1;
                csr_w_en = 1'b1;
                csr_addr = instr[31:20];
                csr_op = 3'b001;
            end
            {FUNCT3_CSRRS, SYSTEM_OPCODE}:
            begin
                alu_pc_select = 2'b00;
                alu_mux2_select = 2'b00;
                alu_op_select = 4'b0000;  
                alu_imm_select = 1'b1;
                w_en_rf = 1'b1;
                rf_w_select = 2'b11;
                csr_r_en = 1'b1;
                csr_w_en = (instr[19:15] == 5'b00000) ? 1'b0: 1'b1;
                csr_addr = instr[31:20];
                csr_op = 3'b010;
            end
            {FUNCT3_CSRRC, SYSTEM_OPCODE}:
            begin
                alu_pc_select = 2'b00;
                alu_mux2_select = 2'b00;
                alu_op_select = 4'b0000;  
                alu_imm_select = 1'b1;
                w_en_rf = 1'b1;
                rf_w_select = 2'b11;
                csr_r_en = 1'b1;
                csr_w_en = (instr[19:15] == 5'b00000) ? 1'b0: 1'b1;
                csr_addr = instr[31:20];
                csr_op = 3'b011;
            end
            {FUNCT3_CSRRWI, SYSTEM_OPCODE}:
            begin
                w_en_rf = (instr[11:7] == 5'b00000) ? 1'b0 : 1'b1;
                rf_w_select = 2'b11;
                csr_r_en = (instr[11:7] == 5'b00000) ? 1'b0 : 1'b1;
                csr_w_en = 1'b1;
                csr_addr = instr[31:20];
                csr_imm_select = 2'b01;
                csr_op = 3'b101;
            end
            {FUNCT3_CSRRSI, SYSTEM_OPCODE}:
            begin
                w_en_rf = 1'b1;
                rf_w_select = 2'b11;
                csr_r_en = 1'b1;
                csr_w_en = (instr[19:15] == 5'b00000) ? 1'b0: 1'b1;
                csr_addr = instr[31:20];
                csr_imm_select = 2'b01;
                csr_op = 3'b110;
            end
            {FUNCT3_CSRRCI, SYSTEM_OPCODE}:
            begin
                w_en_rf = 1'b1;
                rf_w_select = 2'b11;
                csr_r_en = 1'b1;
                csr_w_en = (instr[19:15] == 5'b00000) ? 1'b0: 1'b1;
                csr_addr = instr[31:20];
                csr_imm_select = 2'b01;
                csr_op = 3'b111;
            end
            default:    // JAL / JALR / LUI / AUIPC
            begin
                case (instr[6:0])
                    JAL_OPCODE:
                    begin
                        alu_pc_select = 2'b01;
                        alu_mux1_select = 1'b0;
                        alu_mux2_select = 2'b00;
                        alu_op_select = 4'b0000; 
                        jump = 1'b1;
                        w_en_rf = 1'b1;
                        rf_w_select = 2'b10;
                    end
                    JALR_OPCODE:
                    begin
                        alu_mux1_select = 1'b0;
                        alu_mux2_select = 2'b00;
                        alu_op_select = 4'b0000;
                        jump = 1'b1;
                        w_en_rf = 1'b1;
                        rf_w_select = 2'b10;
                    end
                    LUI_OPCODE:
                    begin
                        alu_pc_select = 2'b10;
                        alu_mux1_select = 1'b0;
                        alu_mux2_select = 2'b00;
                        alu_op_select = 4'b0000;
                        w_en_rf = 1'b1;
                        rf_w_select = 2'b00;
                    end
                    AUIPC_OPCODE:
                    begin
                        alu_pc_select = 2'b01;
                        alu_mux1_select = 1'b0;
                        alu_mux2_select = 2'b00;
                        alu_op_select = 4'b0000;
                        w_en_rf = 1'b1;
                        rf_w_select = 2'b00;
                    end
                    default:
                    begin
                        alu_mux1_select = 1'b0;
                        alu_mux2_select = 2'b00;
                        alu_op_select = 4'b0000;
                        w_en_rf = 1'b0;
                        rf_w_select = 2'b00;
                    end
                endcase
            end
        endcase  
        
        if(is_misaligned)
        begin
            csr_r_en = 1'b1;
            csr_w_en = 1'b0;
            csr_op = 3'b000;
            csr_addr = CSR_MTVEC_ADDR;
            csr_imm_select = 2'b10;     // select instr
        end
    end
    

endmodule