// Bit-string pattern matching for Bluespec
// Inspired by Morten Rhiger's "Type-Safe Pattern Combinators"
// Matthew Naylor, University of Cambridge
// Alexandre Joannou, University of Cambridge

// Imports
import List :: *;

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
function Tuple2#(Bool, t1) numBitPat(Bit#(n) a, Bit#(n) b, t1 k) =
  tuple2(a == b, k);
function Tuple2#(Bool, t0) varBitPat(Bit#(n) x, function t0 f(Bit#(n) x)) =
  one(x, f);
function Tuple2#(Bool, t2)
           catBitPat(BitPat#(n0, t0, t1) f, BitPat#(n1, t1, t2) g, Bit#(n2) n, t0 k)
             provisos (Add#(n0, n1, n2)) =
  app(f(truncateLSB(n)), g(truncate(n)), k);

// Bit pattern combinators
function BitPat#(n, t0, t0) n(Bit#(n) x) = numBitPat(x);

function BitPat#(n, function t0 f(Bit#(n) x), t0) v() = varBitPat;

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

// Guarded actions
typedef struct {
  Bool guard;
  Action body;
} GuardedAction;

// Bit pattern with RHS
function GuardedAction when(BitPat#(n, t, Action) p, t f, Bit#(n) subject);
  Tuple2#(Bool, Action) res = p(subject, f);
  return GuardedAction { guard: tpl_1(res), body: tpl_2(res) };
endfunction

// Switch statement
typeclass MkSwitch#(type a, type n);
  function a mkSwitch(Bit#(n) val, List#(GuardedAction) act);
endtypeclass

instance MkSwitch#(List#(GuardedAction), n);
  function mkSwitch(val, acts) = List::reverse(acts);
endinstance

instance MkSwitch#(function a f(function GuardedAction f(Bit#(n) val)), n)
         provisos (MkSwitch#(a, n));
  function mkSwitch(val, acts, f) = mkSwitch(val, Cons(f(val), acts));
endinstance

function a switch(Bit#(n) val) provisos (MkSwitch#(a, n));
  return mkSwitch(val, Nil);
endfunction

// Generate rules from guarded actions
module genRules#(List#(GuardedAction) actions) (Empty);
  Integer n = length(actions);
  List#(GuardedAction) acts = actions;
  for (Integer i = 0; i < n; i=i+1) begin
    GuardedAction act = List::head(acts);
    rule generatedRule (act.guard);
      act.body;
    endrule
    acts = List::tail(acts);
  end
endmodule
