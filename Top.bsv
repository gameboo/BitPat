import BitPat :: *;
import List :: *;
import StmtFSM :: * ;
import FIFO :: *;
import SpecialFIFOs :: *;

module top ();

  FIFO#(Bit#(0)) dummy <- mkBypassFIFO();

  // Semantics of add instruction
  function Stmt add(Bit#(5) rs2, Bit#(5) rs1, Bit#(5) rd) = par
    action
      $display("%0t --- add0a %d, %d, %d", $time, rd, rs1, rs2);
      dummy.enq(0);
    endaction
    seq
      action
        $display("%0t --- add0b %d, %d, %d", $time, rd, rs1, rs2);
        dummy.deq();
      endaction
      $display("%0t --- add1b %d, %d, %d", $time, rd, rs1, rs2);
      $display("%0t --- add2b %d, %d, %d", $time, rd, rs1, rs2);
    endseq
  endpar;

  // Semantics of addi instruction
  function Stmt addi(Bit#(12) imm, Bit#(5) rs1, Bit#(5) rd) = seq
    $display("addi %d, %d, %d", rd, rs1, imm);
  endseq;

  Bit#(32) instr = 32'b0000000_00001_00010_000_00011_0110011;

  genFSMs(
    switch(instr,
      when(pat(n(7'b0), v, v, n(3'b0), v, n(7'b0110011)), add),
      when(pat(v,       v,    n(3'b0), v, n(7'b0010011)), addi)
    )
  );
endmodule
