// Matthew Naylor, University of Cambridge
// Alexandre Joannou, University of Cambridge

import BitPat :: *;
import Recipe :: *;
import List :: *;

typedef Bit#(5) RS;
typedef Bit#(5) RD;
typedef Bit#(n) Imm#(numeric type n);

// Semantics of add instruction
//when(pat(n(7'b0), sv(5), sv(5), n(3'b0), sv(5), n(7'b0110011)), add),
Pat6#(N#(7,0), V#(RS), V#(RS), N#(3,0), V#(RD), N#(7,7'b0110011)) pat_add = ?;
function Recipe add(Bit#(5) rs2, Bit#(5) rs1, Bit#(5) rd) = rAct(action
  $display("add %d, %d, %d", rd, rs1, rs2);
endaction);

Pat5#(V#(Imm#(12)), V#(RS), N#(3,3'b000), V#(RD), N#(7, 7'b0010011)) pat_addi = ?;
// Semantics of addi instruction with rd == 5
function Recipe addi_rd5(Imm#(12) imm, RS rs1, RD rd) = rAct(action
  $display("addi %d, %d, %d (rd == 5)", rd, rs1, imm);
endaction);

// Semantics of addi instruction with rd != 5
function Recipe addi_rdnot5(Bit#(12) imm, Bit#(5) rs1, Bit#(5) rd) = rAct(action
  $display("addi %d, %d, %d (rd != 5)", rd, rs1, imm);
endaction);

Pat1#(V#(Bit#(32))) dummy_pat = ?;
function Recipe dummy(Bit#(32) inst) = rAct(action
  $display("dummy: 0x%0x", inst);
endaction);

function Bool eq (Bit#(n) x, Bit#(n) y) = x == y;
function Bool neq (Bit#(n) x, Bit#(n) y) = x != y;

function Bool guardEQ5 (Bit#(32) x) = x[19:15] == 5;
function Bool guardNEQ5 (Bit#(32) x) = x[19:15] != 5;

module top ();
  //Bit#(32) instr = 32'd0;
  //Bit#(32) instr = 32'b0000000_00001_00010_000_00011_0110011;
  Bit#(32) instr = 32'b0000000_00001_00010_000_00011_0010011;
  //Bit#(32) instr = 32'b0000000_00001_00101_000_00011_0010011;

  genRules(
    switch(instr,
      //when(pat(v), dummy)
      //when(toBitPat(dummy_pat), dummy)
      /*
      XXX example of compile time sv error:
      when(pat(n(7'b0), sv(5), sv(8), n(3'b0), sv(5), n(7'b0110011)), add),
      */
      //when(pat(n(7'b0), sv(5), sv(5), n(3'b0), sv(5), n(7'b0110011)), add),
      when(toBitPat(pat_add), add),
      //when(pat(v,  gv(eq(5)), n(3'b0), v, n(7'b0010011)), addi_rd5),
      when(
        guarded(pat(v,  v, n(3'b0), v, n(7'b0010011)), guardEQ5),
        addi_rd5),
      //when(pat(v, gv(neq(5)), n(3'b0), v, n(7'b0010011)), addi_rdnot5)
      when(
        //guarded(pat(v, v, n(3'b0), v, n(7'b0010011)), guardNEQ5),
        guarded(toBitPat(pat_addi), guardNEQ5),
        addi_rdnot5)
    )
  );
endmodule
