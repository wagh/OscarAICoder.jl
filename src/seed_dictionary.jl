module SeedDictionary

export SEED_DICTIONARY

SEED_DICTIONARY = [
    Dict(
        "input" => "Define a polynomial ring R with variables x0, x1, x2, and x3 over the rational numbers QQ.",
        "output" => "R, (x0, x1, x2, x3) = polynomial_ring(QQ, [\"x0\", \"x1\", \"x2\", \"x3\"])",
    ),
    Dict(
        "input" => "Define an ideal I in R generated by the polynomials x0 and x1.",
        "output" => "I = ideal(R, [x0, x1])",
    ),
    Dict(
        "input" => "Define another ideal J in R generated by the polynomials x2 and x3.",
        "output" => "J = ideal(R, [x2, x3])",
    ),
    Dict(
        "input" => "Construct a matrix A with elements from R based on given polynomial expressions.",
        "output" => "A = matrix(R, [[1, x0, x1, 0, 0], [1, 0, 0, x2, x3]])",
    ),
    Dict(
        "input" => "Compute the transpose of the syzygy module of A and store it in B.",
        "output" => "B = transpose(syz(transpose(A)))",
    ),
    Dict(
        "input" => "Define a point ideal U at (0, 0) in R.",
        "output" => "U = complement_of_point_ideal(R, [0, 0])",
    ),
    Dict(
        "input" => "Localize the ring R at the point ideal U and store it as Rloc.",
        "output" => "Rloc, _ = localization(R, U)",
    ),
    Dict(
        "input" => "Define an ideal I in Rloc generated by polynomials f and g.",
        "output" => "I = ideal(Rloc, [f, g])",
    ),
    Dict(
        "input" => "Compute the quotient ring A of Rloc modulo I and store it as A.",
        "output" => "A, _ = quo(Rloc, I)",
    ),
    Dict(
        "input" => "Find the dimension of the vector space associated with A.",
        "output" => "vector_space_dimension(A)",
    ),
    Dict(
        "input" => "Compute the quotient ring QQ[x, y] modulo the ideal (x - y).",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"]);\nI = ideal(R, [ (x - y)] );\nQ = R / I;\nprint(Q)",
    ),
    Dict(
        "input" => "Find the prime factorization of the polynomial x^3 - x in QQ[x].",
        "output" => "R, x = polynomial_ring(QQ, \"x\");\nf = R(x^3 - x);\nprint(factor(f))",
    ),
    Dict(
        "input" => "Check if the polynomial x^2 + y^2 is irreducible in RR[x, y].",
        "output" => "R, x, y = polynomial_ring(RR, [\"x\", \"y\"]);\nf = R(x^2 + y^2);\nprint(isirreducible(f))",
    ),
    Dict(
        "input" => "Compute the radical of the ideal (x^2) in QQ[x].",
        "output" => "R, x = polynomial_ring(QQ, \"x\");\nI = ideal(R(x^2));\nprint(radical(I))",
    ),
    Dict(
        "input" => "Determine the Krull dimension of the polynomial ring QQ[x, y, z].",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"]);\nprint(dimension(R))",
    ),
    Dict(
        "input" => "Find the nilradical of the ring ZZ/12ZZ.",
        "output" => "R = QuotientRing(ZZ, 12);\nprint(nilradical(R))",
    ),
    Dict(
        "input" => "Check if the ring QQ[x]/(x^2 - 2) is a field.",
        "output" => "R, x = polynomial_ring(QQ, \"x\");\nI = ideal(R(x^2 - 2));\nQ = R / I;\nprint(isfield(Q))",
    ),
    Dict(
        "input" => "Compute the intersection of the ideals (x) and (y) in QQ[x, y].",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"]);\nI = ideal(R(x));\nJ = ideal(R(y));\nprint(intersection(I, J))",
    ),
    Dict(
        "input" => "Determine if the polynomial x*y - z^2 belongs to the ideal generated by x - z and y - z in QQ[x, y, z].",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"]);\nI = ideal(R(x - z), R(y - z));\nf = R(x*y - z^2);\nprint(in(f, I))",
    ),
    Dict(
        "input" => "Compute the product of the ideals (x, y) and (z) in QQ[x, y, z].",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"]);\nI = ideal(R(x), R(y));\nJ = ideal(R(z));\nprint(I * J)",
    ),
    Dict(
        "input" => "Find the irreducible components of the algebraic set defined by the polynomial x^2 - y^2 in RR[x, y].",
        "output" => "R, x, y = polynomial_ring(RR, [\"x\", \"y\"]);\nf = R(x^2 - y^2);\n# OSCAR might not directly give irreducible components of the *set*;\n# as easily as factorization of the polynomial.;\n# We'd likely factor the polynomial:;\nfactors = factor(f);\nprint(factors);\n# The components correspond to the factors x - y = 0 and x + y = 0.",
    ),
    Dict(
        "input" => "Compute the Groebner basis of the ideal (x^2 + y^2 - 1, x*y - 1) in QQ[x, y] with respect to the lexicographic order.",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"], order=\"lex\");\nI = ideal(R(x^2 + y^2 - 1), R(x*y - 1));\ngb = groebner_basis(I);\nprint(gb)",
    ),
    Dict(
        "input" => "Determine the dimension of the affine variety defined by the ideal (x^2 - y, y^2 - z) in CC[x, y, z].",
        "output" => "R, x, y, z = polynomial_ring(CC, [\"x\", \"y\", \"z\"]);\nI = ideal(R(x^2 - y), R(y^2 - z));\nV = variety(I);\nprint(dimension(V))",
    ),
    Dict(
        "input" => "Compute the primary decomposition of the ideal (x^2, x*y) in QQ[x, y].",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"]);\nI = ideal(R(x^2), R(x*y));\npd = primary_decomposition(I);\nprint(pd);\n# Expected output will be a list of primary ideals.",
    ),
    Dict(
        "input" => "Find the associated prime ideals of the ideal (x*y, x*z) in QQ[x, y, z].",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"]);\nI = ideal(R(x*y), R(x*z));\nap = associated_primes(I);\nprint(ap);\n# Expected output will be a list of prime ideals.",
    ),
    Dict(
        "input" => "Compute the primary decomposition of the ideal (x^2 - y^2, x^2 - z^2) in QQ[x, y, z].",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"]);\nI = ideal(R(x^2 - y^2), R(x^2 - z^2));\npd = primary_decomposition(I);\nprint(pd)",
    ),
    Dict(
        "input" => "Find the isolated and embedded prime ideals of the ideal (x^2, x*y^2) in QQ[x, y].",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"]);\nI = ideal(R(x^2), R(x*y^2));\nap = associated_primes(I);\n# OSCAR might not directly distinguish between isolated and embedded in the output;\n# of associated_primes. Further analysis might be needed based on the primary components.;\npd = primary_decomposition(I);\nprint(\"Primary Decomposition:\", pd);\nprint(\"Associated Primes:\", ap);\n# You might need to manually analyze the results to identify isolated/embedded.",
    ),
    Dict(
        "input" => "Compute the radical of each primary component in the primary decomposition of (x^3, x*y) in QQ[x, y].",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"]);\nI = ideal(R(x^3), R(x*y));\npd = primary_decomposition(I);\nradicals = [radical(P) for P in pd];\nprint(\"Primary Decomposition:\", pd);\nprint(\"Radicals:\", radicals)",
    ),
    Dict(
        "input" => "Consider the ideal (x*y*z). Find its primary decomposition in QQ[x, y, z].",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"]);\nI = ideal(R(x*y*z));\npd = primary_decomposition(I);\nprint(pd)",
    ),
    Dict(
        "input" => "Compute the primary decomposition of the ideal (x^2 + 1) in RR[x]. (Note: irreducible over RR, so the ideal is primary).",
        "output" => "R, x = polynomial_ring(RR, \"x\");\nI = ideal(R(x^2 + 1));\npd = primary_decomposition(I);\nprint(pd)",
    ),
    Dict(
        "input" => "Find the associated primes of the ideal (x^2 - 1, x - 1) in QQ[x].",
        "output" => "R, x = polynomial_ring(QQ, \"x\");\nI = ideal(R(x^2 - 1), R(x - 1));\nap = associated_primes(I);\nprint(ap)",
    ),
    Dict(
        "input" => "Compute the primary decomposition of the ideal (y^2, x*y - x^3) in QQ[x, y].",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"]);\nI = ideal(R(y^2), R(x*y - x^3));\npd = primary_decomposition(I);\nprint(pd)",
    ),
    Dict(
        "input" => "Find the isolated primes of the ideal (x*y, z*y) in QQ[x, y, z].",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"]);\nI = ideal(R(x*y), R(z*y));\nap = associated_primes(I);\n# Again, isolating isolated primes might require further analysis.;\nprint(\"Associated Primes:\", ap);\npd = primary_decomposition(I);\nprint(\"Primary Decomposition:\", pd)",
    ),
    Dict(
        "input" => "Compute the Groebner basis of the ideal (x^2 + y^2 - 1, x - y) in QQ[x, y] with respect to the lexicographic order.",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"], order=\"lex\");\nI = ideal(R(x^2 + y^2 - 1), R(x - y));\ngb = groebner_basis(I);\nprint(gb)",
    ),
    Dict(
        "input" => "Compute the reduced Groebner basis of the ideal (x^2 - y, y^2 - z, z^2 - x) in QQ[x, y, z] with respect to the degree reverse lexicographic order.",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"], order=\"degrevlex\");\nI = ideal(R(x^2 - y), R(y^2 - z), R(z^2 - x));\nrgb = reduced_groebner_basis(I);\nprint(rgb)",
    ),
    Dict(
        "input" => "Use the Groebner basis to check if the polynomial x^3 - 2*y^3 belongs to the ideal (x^2 - y, y^2 - 2*x) in QQ[x, y] with lexicographic order.",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"], order=\"lex\");\nI = ideal(R(x^2 - y), R(y^2 - 2*x));\nf = R(x^3 - 2*y^3);\ngb = groebner_basis(I);\nremainder = normal_form(f, gb);\nprint(remainder == 0)",
    ),
    Dict(
        "input" => "Find the Groebner basis of the ideal of the twisted cubic curve (t, t^2, t^3) in QQ[x, y, z] with lexicographic order (x > y > z).",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"], order=\"lex\");\nI = ideal(R(y - x^2), R(z - x^3));\ngb = groebner_basis(I);\nprint(gb)",
    ),
    Dict(
        "input" => "Compute the intersection of the ideals (x, y) and (y, z) in QQ[x, y, z] using Groebner bases.",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"], order=\"lex\");\nI = ideal(R(x), R(y));\nJ = ideal(R(y), R(z));\nt = R.gens()[0] * 0 + 1  # A dummy variable;\nS, t_var = R.add_variable(\"t\");\nI_lifted = S.ideal(S(x), S(y));\nJ_lifted = S.ideal(S(y), S(z));\nIK = I_lifted * S.ideal(S(1 - t)) + J_lifted * S.ideal(S(t));\ngb_IK = groebner_basis(IK, eliminate=[t_var]);\nintersection_ideal = gb_IK.contract(R);\nprint(intersection_ideal)",
    ),
    Dict(
        "input" => "Compute the elimination ideal of x from the ideal (x^2 - 1, y - 1) in QQ[x, y] using Groebner bases with lexicographic order (x > y).",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"], order=\"lex\");\nI = ideal(R(x^2 - 1), R(y - 1));\nelim_ideal = elimination_ideal(I, [x]);\nprint(elim_ideal)",
    ),
    Dict(
        "input" => "Find the Groebner basis of the ideal (x^3 - 2*x*y, x^2*y - 2*y^2 + x) in QQ[x, y] with degree lexicographic order.",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"], order=\"deglex\");\nI = ideal(R(x^3 - 2*x*y), R(x^2*y - 2*y^2 + x));\ngb = groebner_basis(I);\nprint(gb)",
    ),
    Dict(
        "input" => "Check if the ideal (x^2 - 1, y - 1) is radical using Groebner bases.",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"], order=\"lex\");\nI = ideal(R(x^2 - 1), R(y - 1));\ngb = groebner_basis(I);\n# Checking for radicality using GBs involves checking if the radical of the ideal;\n# generated by the GB is the same as the ideal itself. This can be complex to automate;\n# directly from the GB without further algorithms (e.g., using the Jacobian criterion in some cases).;\n# A simpler check for being radical for ideals of the form (f1, ..., fk) where fi are square-free;\n# and generate a radical ideal is not directly implemented as a simple GB property.;\n# This problem might be better suited for theoretical understanding or more advanced OSCAR functions.;\n# For now, we'll just compute the GB.;\nprint(gb);\n# Note: Determining radicality from the GB alone isn't trivial.",
    ),
    Dict(
        "input" => "Compute the Hilbert function of the ideal (x^2, y^2, z^2) in QQ[x, y, z] up to degree 5.",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"]);
I = ideal(R(x^2), R(y^2), R(z^2));
hilbert_function = [dim(QQ[x, y, z]_i / I_i) for i in 0:5];
print(hilbert_function)",
    ),
    Dict(
        "input" => "Compute the syzygy module of the polynomials (x, y) in QQ[x, y].",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"]);\nf = [R(x), R(y)];\nsyzygies = syzygy_module(f);\nprint(syzygies)"
    ),
    Dict(
        "input" => "Find the normal form of the polynomial x^2*y with respect to the ideal (x*y - 1, y^2 - 1) in QQ[x, y] with lexicographic order (x > y).",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"], order=\"lex\");\nI = ideal(R(x*y - 1), R(y^2 - 1));\nf = R(x^2*y);\nnf = normal_form(f, groebner_basis(I));\nprint(nf)"
    ),
    Dict(
        "input" => "Determine the dimension of the affine variety defined by the ideal (x^2 - y, y^2 - z) in CC[x, y, z].",
        "output" => "R, x, y, z = polynomial_ring(CC, [\"x\", \"y\", \"z\"]);\nI = ideal(R(x^2 - y), R(y^2 - z));\nV = variety(I);\nprint(dimension(V))"
    ),
    Dict(
        "input" => "Compute the primary decomposition of the ideal (x^2, x*y) in QQ[x, y].",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"]);\nI = ideal(R(x^2), R(x*y));\npd = primary_decomposition(I);\nprint(pd);\n# Expected output will be a list of primary ideals."
    ),
    Dict(
        "input" => "Find the associated prime ideals of the ideal (x*y, x*z) in QQ[x, y, z].",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"]);\nI = ideal(R(x*y), R(x*z));\nap = associated_primes(I);\nprint(ap);\n# Expected output will be a list of prime ideals."
    ),
    Dict(
        "input" => "Compute the primary decomposition of the ideal (x^2 - y^2, x^2 - z^2) in QQ[x, y, z].",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"]);\nI = ideal(R(x^2 - y^2), R(x^2 - z^2));\npd = primary_decomposition(I);\nprint(pd)"
    ),
    Dict(
        "input" => "Find the isolated and embedded prime ideals of the ideal (x^2, x*y^2) in QQ[x, y].",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"]);\nI = ideal(R(x^2), R(x*y^2));\nap = associated_primes(I);\n# OSCAR might not directly distinguish between isolated and embedded in the output;\n# of associated_primes. Further analysis might be needed based on the primary components.;\npd = primary_decomposition(I);\nprint(\"Primary Decomposition:\", pd);\nprint(\"Associated Primes:\", ap);\n# You might need to manually analyze the results to identify isolated/embedded."
    ),
    Dict(
        "input" => "Compute the radical of each primary component in the primary decomposition of (x^3, x*y) in QQ[x, y].",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"]);\nI = ideal(R(x^3), R(x*y));\npd = primary_decomposition(I);\nradicals = [radical(P) for P in pd];\nprint(\"Primary Decomposition:\", pd);\nprint(\"Radicals:\", radicals)"
    ),
    Dict(
        "input" => "Consider the ideal (x*y*z). Find its primary decomposition in QQ[x, y, z].",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"]);\nI = ideal(R(x*y*z));\npd = primary_decomposition(I);\nprint(pd)"
    ),
    Dict(
        "input" => "Compute the primary decomposition of the ideal (x^2 + 1) in RR[x]. (Note: irreducible over RR, so the ideal is primary).",
        "output" => "R, x = polynomial_ring(RR, \"x\");\nI = ideal(R(x^2 + 1));\npd = primary_decomposition(I);\nprint(pd)"
    ),
    Dict(
        "input" => "Find the associated primes of the ideal (x^2 - 1, x - 1) in QQ[x].",
        "output" => "R, x = polynomial_ring(QQ, \"x\");\nI = ideal(R(x^2 - 1), R(x - 1));\nap = associated_primes(I);\nprint(ap)"
    ),
    Dict(
        "input" => "Compute the primary decomposition of the ideal (y^2, x*y - x^3) in QQ[x, y].",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"]);\nI = ideal(R(y^2), R(x*y - x^3));\npd = primary_decomposition(I);\nprint(pd)"
    ),
    Dict(
        "input" => "Find the isolated primes of the ideal (x*y, z*y) in QQ[x, y, z].",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"]);\nI = ideal(R(x*y), R(z*y));\nap = associated_primes(I);\n# Again, isolating isolated primes might require further analysis.;\nprint(\"Associated Primes:\", ap);\npd = primary_decomposition(I);\nprint(\"Primary Decomposition:\", pd)"
    ),
    Dict(
        "input" => "Compute the Groebner basis of the ideal (x^2 + y^2 - 1, x - y) in QQ[x, y] with respect to the lexicographic order.",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"], order=\"lex\");\nI = ideal(R(x^2 + y^2 - 1), R(x - y));\ngb = groebner_basis(I);\nprint(gb)"
    ),
    Dict(
        "input" => "Compute the reduced Groebner basis of the ideal (x^2 - y, y^2 - z, z^2 - x) in QQ[x, y, z] with respect to the degree reverse lexicographic order.",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"], order=\"degrevlex\");\nI = ideal(R(x^2 - y), R(y^2 - z), R(z^2 - x));\nrgb = reduced_groebner_basis(I);\nprint(rgb)"
    ),
    Dict(
        "input" => "Use the Groebner basis to check if the polynomial x^3 - 2*y^3 belongs to the ideal (x^2 - y, y^2 - 2*x) in QQ[x, y] with lexicographic order.",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"], order=\"lex\");\nI = ideal(R(x^2 - y), R(y^2 - 2*x));\nf = R(x^3 - 2*y^3);\ngb = groebner_basis(I);\nremainder = normal_form(f, gb);\nprint(remainder == 0)"
    ),
    Dict(
        "input" => "Find the Groebner basis of the ideal of the twisted cubic curve (t, t^2, t^3) in QQ[x, y, z] with lexicographic order (x > y > z).",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"], order=\"lex\");\nI = ideal(R(y - x^2), R(z - x^3));\ngb = groebner_basis(I);\nprint(gb)"
    ),
    Dict(
        "input" => "Compute the intersection of the ideals (x, y) and (y, z) in QQ[x, y, z] using Groebner bases.",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"], order=\"lex\");\nI = ideal(R(x), R(y));\nJ = ideal(R(y), R(z));\nt = R.gens()[0] * 0 + 1  # A dummy variable;\nS, t_var = R.add_variable(\"t\");\nI_lifted = S.ideal(S(x), S(y));\nJ_lifted = S.ideal(S(y), S(z));\nIK = I_lifted * S.ideal(S(1 - t)) + J_lifted * S.ideal(S(t));\ngb_IK = groebner_basis(IK, eliminate=[t_var]);\nintersection_ideal = gb_IK.contract(R);\nprint(intersection_ideal)"
    ),
    Dict(
        "input" => "Compute the elimination ideal of x from the ideal (x^2 + y^2 - 1, x*y - 1) in QQ[x, y] using Groebner bases with lexicographic order (x > y).",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"], order=\"lex\");\nI = ideal(R(x^2 + y^2 - 1), R(x*y - 1));\nelim_ideal = elimination_ideal(I, [x]);\nprint(elim_ideal)"
    ),
    Dict(
        "input" => "Find the Groebner basis of the ideal (x^3 - 2*x*y, x^2*y - 2*y^2 + x) in QQ[x, y] with degree lexicographic order.",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"], order=\"deglex\");\nI = ideal(R(x^3 - 2*x*y), R(x^2*y - 2*y^2 + x));\ngb = groebner_basis(I);\nprint(gb)"
    ),
    Dict(
        "input" => "Check if the ideal (x^2 - 1, y - 1) is radical using Groebner bases.",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"], order=\"lex\");\nI = ideal(R(x^2 - 1), R(y - 1));\ngb = groebner_basis(I);\n# Checking for radicality using GBs involves checking if the radical of the ideal;\n# generated by the GB is the same as the ideal itself. This can be complex to automate;\n# directly from the GB without further algorithms (e.g., using the Jacobian criterion in some cases).;\n# A simpler check for being radical for ideals of the form (f1, ..., fk) where fi are square-free;\n# and generate a radical ideal is not directly implemented as a simple GB property.;\n# This problem might be better suited for theoretical understanding or more advanced OSCAR functions.;\n# For now, we'll just compute the GB.;\nprint(gb);\n# Note: Determining radicality from the GB alone isn't trivial."
    ),
    Dict(
        "input" => "Compute the syzygy module of the polynomials (x, y) in QQ[x, y].",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"]);\nf = [R(x), R(y)];\nsyzygies = syzygy_module(f);\nprint(syzygies)"
    ),
    Dict(
        "input" => "Find the normal form of the polynomial x^2*y with respect to the ideal (x*y - 1, y^2 - 1) in QQ[x, y] with lexicographic order (x > y).",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"], order=\"lex\");\nI = ideal(R(x*y - 1), R(y^2 - 1));\nf = R(x^2*y);\nnf = normal_form(f, groebner_basis(I));\nprint(nf)"
    ),
    Dict(
        "input" => "Compute the Groebner basis of the ideal (x^2 + y^2 - 1, x - y) in QQ[x, y] with respect to the lexicographic order.",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"], order=\"lex\");\nI = ideal(R(x^2 + y^2 - 1), R(x - y));\ngb = groebner_basis(I);\nprint(gb)"
    ),
    Dict(
        "input" => "Compute the reduced Groebner basis of the ideal (x^2 - y, y^2 - z, z^2 - x) in QQ[x, y, z] with respect to the degree reverse lexicographic order.",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"], order=\"degrevlex\");\nI = ideal(R(x^2 - y), R(y^2 - z), R(z^2 - x));\nrgb = reduced_groebner_basis(I);\nprint(rgb)"
    ),
    Dict(
        "input" => "Use the Groebner basis to check if the polynomial x^3 - 2*y^3 belongs to the ideal (x^2 - y, y^2 - 2*x) in QQ[x, y] with lexicographic order.",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"], order=\"lex\");\nI = ideal(R(x^2 - y), R(y^2 - 2*x));\nf = R(x^3 - 2*y^3);\ngb = groebner_basis(I);\nremainder = normal_form(f, gb);\nprint(remainder == 0)"
    ),
    Dict(
        "input" => "Find the Groebner basis of the ideal of the twisted cubic curve (t, t^2, t^3) in QQ[x, y, z] with lexicographic order (x > y > z).",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"], order=\"lex\");\nI = ideal(R(y - x^2), R(z - x^3));\ngb = groebner_basis(I);\nprint(gb)"
    ),
    Dict(
        "input" => "Compute the intersection of the ideals (x, y) and (y, z) in QQ[x, y, z] using Groebner bases.",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"], order=\"lex\");\nI = ideal(R(x), R(y));\nJ = ideal(R(y), R(z));\nt = R.gens()[0] * 0 + 1  # A dummy variable;\nS, t_var = R.add_variable(\"t\");\nI_lifted = S.ideal(S(x), S(y));\nJ_lifted = S.ideal(S(y), S(z));\nIK = I_lifted * S.ideal(S(1 - t)) + J_lifted * S.ideal(S(t));\ngb_IK = groebner_basis(IK, eliminate=[t_var]);\nintersection_ideal = gb_IK.contract(R);\nprint(intersection_ideal)"
    ),
    Dict(
        "input" => "Compute the elimination ideal of x from the ideal (x^2 + y^2 - 1, x*y - 1) in QQ[x, y] using Groebner bases with lexicographic order (x > y).",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"], order=\"lex\");\nI = ideal(R(x^2 + y^2 - 1), R(x*y - 1));\nelim_ideal = elimination_ideal(I, [x]);\nprint(elim_ideal)"
    ),
    Dict(
        "input" => "Find the Groebner basis of the ideal (x^3 - 2*x*y, x^2*y - 2*y^2 + x) in QQ[x, y] with degree lexicographic order.",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"], order=\"deglex\");\nI = ideal(R(x^3 - 2*x*y), R(x^2*y - 2*y^2 + x));\ngb = groebner_basis(I);\nprint(gb)"
    ),
    Dict(
        "input" => "Check if the ideal (x^2 - 1, y - 1) is radical using Groebner bases.",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"], order=\"lex\");\nI = ideal(R(x^2 - 1), R(y - 1));\ngb = groebner_basis(I);\n# Checking for radicality using GBs involves checking if the radical of the ideal;\n# generated by the GB is the same as the ideal itself. This can be complex to automate;\n# directly from the GB without further algorithms (e.g., using the Jacobian criterion in some cases).;\n# A simpler check for being radical for ideals of the form (f1, ..., fk) where fi are square-free;\n# and generate a radical ideal is not directly implemented as a simple GB property.;\n# This problem might be better suited for theoretical understanding or more advanced OSCAR functions.;\n# For now, we'll just compute the GB.;\nprint(gb);\n# Note: Determining radicality from the GB alone isn't trivial."
    ),
    Dict(
        "input" => "Compute the syzygy module of the polynomials (x, y) in QQ[x, y].",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"])f = [R(x), R(y)];\nsyzygies = syzygy_module(f);\nprint(syzygies)"
    ),
    Dict(
        "input" => "Find the normal form of the polynomial x^2*y with respect to the ideal (x*y - 1, y^2 - 1) in QQ[x, y] with lexicographic order (x > y).",
        "output" => "R, x, y = polynomial_ring(QQ, [\"x\", \"y\"], order=\"lex\");\nI = ideal(R(x*y - 1), R(y^2 - 1));\nf = R(x^2*y);\nnf = normal_form(f, groebner_basis(I));\nprint(nf)"
    ),
    Dict(
        "input" => "Compute the Hilbert function of the ideal (x^2, y^2, z^2) in QQ[x, y, z] up to degree 5.",
        "output" => "R, x, y, z = polynomial_ring(QQ, [\"x\", \"y\", \"z\"]);
I = ideal(R(x^2), R(y^2), R(z^2));
hilbert_function = [dim(QQ[x, y, z]_i / I_i) for i in 0:5];
print(hilbert_function)"
    )
]

end  # module SeedDictionary
