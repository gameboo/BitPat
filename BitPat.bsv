// Bit-string pattern matching for Bluespec
// Inspired by Morten Rhiger's "Type-Safe Pattern Combinators"
// Matthew Naylor, University of Cambridge
// Alexandre Joannou, University of Cambridge

import List :: *;
import Printf :: *;

// Continuation combinators
function Tuple2#(Bool, t0) one(t1 v, function t0 k(t1 v)) =
  tuple2(True, k(v));
function Tuple2#(Bool, t2) app(function Tuple2#(Bool, t1) m(t0 v),
                               function Tuple2#(Bool, t2) n(t1 v), t0 k);
  match {.b1, .k1} = m(k);
  match {.b2, .k2} = n(k1);
  return tuple2(b1 && b2, k2);
endfunction

// Bit patterns (type synonym)
typedef function Tuple2#(Bool, t1) f(Bit#(n) x, t0 k)
  BitPat#(numeric type n, type t0, type t1);

// Bit pattern combinators
// BitPat specific numeric value
function Tuple2#(Bool, t1) numBitPat(Bit#(n) a, Bit#(n) b, t1 k) =
  tuple2(a == b, k);
// BitPat variable
function Tuple2#(Bool, t0) varBitPat(Bit#(n) x, function t0 f(Bit#(n) x)) =
  one(x, f);
// BitPat variable of an explicit bit size
function Tuple2#(Bool, t0) sizedVarBitPat(Integer sz, Bit#(n) x,
                                          function t0 f(Bit#(n) x)) =
  (sz == valueOf(n)) ? one(x, f) : error(sprintf("BitPat::sizedVarBitPat - Expecting Bit#(%0d) variable, seen Bit#(%0d) variable", sz, valueOf(n)));
// BitPat variable guarded with a predicate
function Tuple2#(Bool, t0) guardedVarBitPat(function Bool guard(Bit#(n) x),
                                            Bit#(n) x,
                                            function t0 f(Bit#(n) x)) =
  tuple2(guard(x), f(x));
// BitPat concatenation
function Tuple2#(Bool, t2) catBitPat(BitPat#(n0, t0, t1) f,
                                     BitPat#(n1, t1, t2) g, Bit#(n2) n, t0 k)
                                     provisos (Add#(n0, n1, n2)) =
  app(f(truncateLSB(n)), g(truncate(n)), k);

// Bit pattern combinator wrappers
function BitPat#(n, t0, t0) n(Bit#(n) x) = numBitPat(x);
function BitPat#(n, function t0 f(Bit#(n) x), t0) v() = varBitPat;
function BitPat#(n, function t0 f(Bit#(n) x), t0) sv(Integer x) =
  sizedVarBitPat(x);
function BitPat#(n, function t0 f(Bit#(n) x), t0) gv(
  function Bool g(Bit#(n) x)) = guardedVarBitPat(g);
function BitPat#(n2, t0, t2) cat(BitPat#(n0, t0, t1) p,
                                 BitPat#(n1, t1, t2) q)
           provisos(Add#(n0, n1, n2)) = catBitPat(p, q);

// Type class for constructing patterns
//
//   pat(p0, p1, p2, ...) = cat(p0, cat(p1, cat(p2, ...
//
typeclass Pat#(type a, type b) dependencies (a determines b);
  function a pat(b x);
endtypeclass

instance Pat#(BitPat#(n, t0, t1), BitPat#(n, t0, t1));
  function pat(p) = p;
endinstance

instance Pat#(function a f(BitPat#(n1, t1, t2) y), BitPat#(n0, t0, t1))
                  provisos(Pat#(a, BitPat#(TAdd#(n0, n1), t0, t2)));
  function pat(x, y) = pat(cat(x, y));
endinstance

// Function to guard a pattern based on a predicate on the case subject
function BitPat#(n, t0, t1) guarded(BitPat#(n, t0, t1) p,
                                    function Bool g(Bit#(n) x));
  function Tuple2#(Bool, t1) wrapGuard (Bit#(n) s, t0 f);
    match {.b,.r} = p(s, f);
    return tuple2(g(s) && b, r);
  endfunction
  return wrapGuard;
endfunction

/////////////////////
// Utility classes //
////////////////////////////////////////////////////////////////////////////////
// switch var args function typeclass
typeclass MkSwitch#(type a, type n, type b) dependencies ((a, n) determines b);
  function a mkSwitch(Bit#(n) val, List#(b) act);
endtypeclass
instance MkSwitch#(List#(b), n, b);
  function mkSwitch(val, acts) = List::reverse(acts);
endinstance
instance MkSwitch#(function a f(function b f(Bit#(n) val)), n, b)
         provisos (MkSwitch#(a, n, b));
  function mkSwitch(val, acts, f) = mkSwitch(val, Cons(f(val), acts));
endinstance
function a switch(Bit#(n) val) provisos (MkSwitch#(a, n, x), GuardedEntity#(x, x_body));
  return mkSwitch(val, Nil);
endfunction
// guarded entity class
typeclass GuardedEntity#(type a, type b)
  dependencies (a determines b, b determines a);
  function Bool getGuard(a x);
  function b getEntity(a x);
  function a when(BitPat#(n, t, b) p, t f, Bit#(n) subject);
  module genRules#(List#(a) xs) (Tuple2#(Rules, PulseWire));
endtypeclass

////////////
// Action //
////////////////////////////////////////////////////////////////////////////////
typedef struct {
  Bool guard;
  Action body;
} GuardedAction;
// GuardedEntity instance
instance GuardedEntity#(GuardedAction, Action);
  function Bool getGuard(GuardedAction x) = x.guard;
  function Action getEntity(GuardedAction x) = x.body;
  function GuardedAction when(BitPat#(n, t, Action) p, t f, Bit#(n) subject);
    Tuple2#(Bool, Action) res = p(subject, f);
    return GuardedAction { guard: tpl_1(res), body: tpl_2(res) };
  endfunction
  module genRules#(List#(GuardedAction) xs) (Tuple2#(Rules, PulseWire));
    PulseWire done <- mkPulseWireOR;
    function Rules createRule(GuardedAction x) = rules
      rule guarded_rule (x.guard); x.body; done.send; endrule
    endrules;
    return tuple2(fold(rJoin, map(createRule, xs)), done);
  endmodule
endinstance

///////////////////
// List#(Action) //
////////////////////////////////////////////////////////////////////////////////
typedef struct {
  Bool guard;
  List#(Action) body;
} GuardedActionList;
`define MaxListDepth 256
typedef TLog#(`MaxListDepth) MaxDepthSz;
// GuardedEntity instance
instance GuardedEntity#(GuardedActionList, List#(Action));
  function Bool getGuard(GuardedActionList x) = x.guard;
  function List#(Action) getEntity(GuardedActionList x) = x.body;
  function GuardedActionList when(BitPat#(n, t, List#(Action)) p, t f, Bit#(n) subject);
    Tuple2#(Bool, List#(Action)) res = p(subject, f);
    return GuardedActionList { guard: tpl_1(res), body: tpl_2(res) };
  endfunction
  module genRules#(List#(GuardedActionList) xs) (Tuple2#(Rules, PulseWire));
    Reg#(Bit#(MaxDepthSz)) step <- mkReg(0);
    PulseWire done <- mkPulseWireOR;
    function Rules createRule(GuardedActionList x);
      Rules allRules = emptyRules;
      for (Integer i = 0; i < length(x.body); i = i + 1)
        allRules = rJoin(allRules, rules
          rule guarded_rule (x.guard && step == fromInteger(i));
            x.body[i];
            if (step == fromInteger(length(x.body) - 1)) begin
              step <= 0;
              done.send();
            end else step <= step + 1;
          endrule
        endrules);
      return allRules;
    endfunction
    return tuple2(fold(rJoin, map(createRule, xs)), done);
  endmodule
endinstance
