import BitPat :: *;
import Recipe :: *;
import List :: *;

// Semantics of add instruction
function Recipe add(Bit#(5) rs2, Bit#(5) rs1, Bit#(5) rd) = rAct(action
  $display("add %d, %d, %d", rd, rs1, rs2);
endaction);

// Semantics of addi instruction
function Recipe addi(Bit#(12) imm, Bit#(5) rs1, Bit#(5) rd) = rAct(action
  $display("addi %d, %d, %d", rd, rs1, imm);
endaction);

module top ();
  Bit#(32) instr = 32'b0000000_00001_00010_000_00011_0110011;

  genRules(
    switch(instr,
      when(pat(n(7'b0), v, v, n(3'b0), v, n(7'b0110011)), add),
      when(pat(v,       v,    n(3'b0), v, n(7'b0010011)), addi)
    )
  );
endmodule
