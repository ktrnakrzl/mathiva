from sympy import symbols, solve, diff, integrate, simplify
from sympy.parsing.sympy_parser import parse_expr

def solve_equation(equation_str, variable="x"):
    """
    Solve an equation. Input: "x**2 - 4" or "x**2 - 4 = 0"
    """
    try:
        x = symbols(variable)
        
        # Handle "=" in equation
        if "=" in equation_str:
            left, right = equation_str.split("=")
            expr = parse_expr(left) - parse_expr(right)
        else:
            expr = parse_expr(equation_str)
        
        # Solve
        solutions = solve(expr, x)
        
        return {
            "expression": equation_str,
            "variable": variable,
            "solutions": [str(sol) for sol in solutions],
            "success": True
        }
    except Exception as e:
        return {
            "error": str(e),
            "success": False
        }

def get_derivative(expr_str, variable="x"):
    """Return the derivative of an expression."""
    try:
        x = symbols(variable)
        expr = parse_expr(expr_str)
        derivative = diff(expr, x)
        return {
            "expression": expr_str,
            "variable": variable,
            "derivative": str(derivative),
            "success": True
        }
    except Exception as e:
        return {
            "error": str(e),
            "success": False
        }

# Test
if __name__ == "__main__":
    print(solve_equation("x**2 - 4"))
    print(solve_equation("2*x + 3 = 7"))
    print(get_derivative("x**3 + 2*x**2"))

    
