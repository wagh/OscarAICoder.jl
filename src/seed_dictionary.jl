# A dictionary mapping common English math statements to Oscar code (Julia)
const SEED_DICTIONARY = Dict(
    "Factor the polynomial x^2 - 5x + 6 over the integers." =>
        "R, x = PolynomialRing(ZZ, \"x\"); factor(x^2 - 5x + 6)",
    "Compute the determinant of the matrix [[1,2],[3,4]]." =>
        "A = Matrix(ZZ, 2, 2, [1,2,3,4]); det(A)",
    "Find the roots of the polynomial x^2 + x + 1 over the rationals." =>
        "R, x = PolynomialRing(QQ, \"x\"); roots(x^2 + x + 1)",
    "Create a finite field of order 7." =>
        "F = GF(7)",
    "Compute the gcd of 42 and 56." =>
        "gcd(42, 56)",
    "Expand the polynomial (x+1)^3." =>
        "R, x = PolynomialRing(ZZ, \"x\"); expand((x+1)^3)",
    "Compute the inverse of the matrix [[2,0],[0,2]]." =>
        "A = Matrix(QQ, 2, 2, [2,0,0,2]); inv(A)",
    "Solve the system x + y = 3, x - y = 1 over the integers." =>
        "A = Matrix(ZZ, 2, 2, [1,1,1,-1]); b = Vector(ZZ, [3,1]); A \\ b"
)
