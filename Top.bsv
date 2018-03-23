// Matthew Naylor, University of Cambridge
// Alexandre Joannou, University of Cambridge

import BitPat :: *;
import Recipe :: *;
import List :: *;

// Semantics of add instruction
function Recipe add(Bit#(5) rs2, Bit#(5) rs1, Bit#(5) rd) = rAct(action
  $display("add %d, %d, %d", rd, rs1, rs2);
endaction);

// Semantics of addi instruction with rd == 5
function Recipe addi_rd5(Bit#(12) imm, Bit#(5) rs1, Bit#(5) rd) = rAct(action
  $display("addi %d, %d, %d (rd == 5)", rd, rs1, imm);
endaction);

// Semantics of addi instruction with rd != 5
function Recipe addi_rdnot5(Bit#(12) imm, Bit#(5) rs1, Bit#(5) rd) = rAct(action
  $display("addi %d, %d, %d (rd != 5)", rd, rs1, imm);
endaction);

function Bool eq (Bit#(n) x, Bit#(n) y) = x == y;
function Bool neq (Bit#(n) x, Bit#(n) y) = x != y;

module top ();
  //Bit#(32) instr = 32'b0000000_00001_00010_000_00011_0110011;
  Bit#(32) instr = 32'b0000000_00001_00010_000_00011_0010011;
  //Bit#(32) instr = 32'b0000000_00001_00101_000_00011_0010011;

  genRules(
    switch(instr,
      /*
      XXX example of compile time sv error:
      when(pat(n(7'b0), sv(5), sv(8), n(3'b0), sv(5), n(7'b0110011)), add),
      */
      when(pat(n(7'b0), sv(5), sv(5), n(3'b0), sv(5), n(7'b0110011)), add),
      when(pat(v,  gv(eq(5)), n(3'b0), v, n(7'b0010011)), addi_rd5),
      when(pat(v, gv(neq(5)), n(3'b0), v, n(7'b0010011)), addi_rdnot5)
    )
  );
endmodule
