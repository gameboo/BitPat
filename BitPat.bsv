// Bit-string pattern matching for Bluespec
// Inspired by Morten Rhiger's "Type-Safe Pattern Combinators"
// Matthew Naylor, University of Cambridge
// Alexandre Joannou, University of Cambridge

// Imports
import List :: *;
import Printf :: *;
import Recipe :: *;

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
function Tuple2#(Bool, t0) sizedVarBitPat(Integer sz, Bit#(n) x, function t0 f(Bit#(n) x)) =
  (sz == valueOf(n)) ? one(x, f) : error(sprintf("BitPat::sizedVarBitPat - Expecting Bit#(%0d) variable, seen Bit#(%0d) variable", sz, valueOf(n)));
function Tuple2#(Bool, t0) guardedVarBitPat(
    function Bool guard(Bit#(n) x),
    Bit#(n) x,
    function t0 f(Bit#(n) x)
  ) = tuple2(guard(x), f(x));
function Tuple2#(Bool, t2)
           catBitPat(BitPat#(n0, t0, t1) f, BitPat#(n1, t1, t2) g, Bit#(n2) n, t0 k)
             provisos (Add#(n0, n1, n2)) =
  app(f(truncateLSB(n)), g(truncate(n)), k);

// Bit pattern combinators
function BitPat#(n, t0, t0) n(Bit#(n) x) = numBitPat(x);

function BitPat#(n, function t0 f(Bit#(n) x), t0) v() = varBitPat;

function BitPat#(n, function t0 f(Bit#(n) x), t0) sv(Integer x) = sizedVarBitPat(x);

function BitPat#(n, function t0 f(Bit#(n) x), t0) gv(function Bool g(Bit#(n) x)) = guardedVarBitPat(g);

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

function BitPat#(n, t0, t1) guarded(BitPat#(n, t0, t1) p, function Bool g(Bit#(n) x));
  function Tuple2#(Bool, t1) wrapGuard (Bit#(n) s, t0 f);
    match {.b,.r} = p(s, f);
    return tuple2(g(s) && b, r);
  endfunction
  return wrapGuard;
endfunction

// Guarded Recipe
typedef struct {
  Bool guard;
  Recipe recipe;
} GuardedRecipe;
function Bool getGuard(GuardedRecipe gr) = gr.guard;
function Recipe getRecipe(GuardedRecipe gr) = gr.recipe;

// Bit pattern with RHS
function GuardedRecipe when(BitPat#(n, t, Recipe) p, t f, Bit#(n) subject);
  Tuple2#(Bool, Recipe) res = p(subject, f);
  return GuardedRecipe { guard: tpl_1(res), recipe: tpl_2(res) };
endfunction

// Switch statement
typeclass MkSwitch#(type a, type n);
  function a mkSwitch(Bit#(n) val, List#(GuardedRecipe) act);
endtypeclass

instance MkSwitch#(List#(GuardedRecipe), n);
  function mkSwitch(val, acts) = List::reverse(acts);
endinstance

instance MkSwitch#(function a f(function GuardedRecipe f(Bit#(n) val)), n)
         provisos (MkSwitch#(a, n));
  function mkSwitch(val, acts, f) = mkSwitch(val, Cons(f(val), acts));
endinstance

function a switch(Bit#(n) val) provisos (MkSwitch#(a, n));
  return mkSwitch(val, Nil);
endfunction

// Generate rules from guarded actions
module [Module] genRules#(List#(GuardedRecipe) grs) (Empty);
  List#(Bool) guards = map(getGuard, grs);
  List#(RecipeFSM) ms <- compileMutuallyExclusive(map(getRecipe, grs));
  module runMachine#(Bool g, RecipeFSM m) ();
    rule run (g);
      m.start();
    endrule
  endmodule
  zipWithM(runMachine, guards, ms);
endmodule
