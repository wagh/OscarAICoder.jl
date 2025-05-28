module Constants

# Global constants
const SEED_DICTIONARY = [
    Dict(
        "input" => "Define a polynomial ring R with variables x0, x1, x2, and x3 over the rational numbers QQ.",
        "output" => "R, (x0, x1, x2, x3) = polynomial_ring(QQ, [\"x0\", \"x1\", \"x2\", \"x3\"])",
    ),
    Dict(
        "input" => "Define a matrix A with integer entries.",
        "output" => "A = matrix(ZZ, 3, 3, [1 2 3; 4 5 6; 7 8 9])"
    ),
    Dict(
        "input" => "Compute the determinant of matrix A.",
        "output" => "det(A)"
    ),
    Dict(
        "input" => "Find the eigenvalues of matrix A.",
        "output" => "eigenvalues(A)"
    ),
    Dict(
        "input" => "Define a polynomial f with coefficients in QQ.",
        "output" => "f = QQ[x]([1, 2, 3])"
    ),
    Dict(
        "input" => "Factor the polynomial x^2 - 5x + 6 over the integers.",
        "output" => "factor(x^2 - 5*x + 6)"
    ),
    Dict(
        "input" => "Find the roots of the polynomial x^2 - 5x + 6.",
        "output" => "roots(x^2 - 5*x + 6)"
    ),
    Dict(
        "input" => "Compute the gcd of two polynomials f and g.",
        "output" => "gcd(f, g)"
    ),
    Dict(
        "input" => "Define a finite field with 7 elements.",
        "output" => "F = GF(7)"
    ),
    Dict(
        "input" => "Define a polynomial ring over the finite field F.",
        "output" => "R = F[x]"
    )
]

export SEED_DICTIONARY

end # module Constants
