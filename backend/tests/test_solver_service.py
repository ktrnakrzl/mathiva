"""Tests for the hybrid OCR orchestration in solver_service.solve_image.

The rule under test: read with Gemini (cloud) first, since it handles real
photos and handwriting, and only fall back to the local pix2tex model when
Gemini is unavailable (no key / offline) or its read doesn't yield a *solvable*
equation. The OCR engines and the solve step are mocked so no model/Ollama/
network is touched -- what we're verifying is the routing (which engine is used,
when), not the OCR or the math.
"""

from app.services import ocr_service, solver_service


def _stub_engines(monkeypatch, pix2tex_out, gemini_out, gemini_on, calls):
    def pix(_):
        calls.append("pix2tex")
        return pix2tex_out

    def gem(_):
        calls.append("gemini")
        return gemini_out

    monkeypatch.setattr(ocr_service, "pix2tex_to_latex", pix)
    monkeypatch.setattr(ocr_service, "gemini_to_latex", gem)
    monkeypatch.setattr(ocr_service, "gemini_available", lambda: gemini_on)


def _stub_solver(monkeypatch, solvable_latex):
    # Solve succeeds only for the LaTeX we declare "good"; everything else fails.
    def fake_solve(latex):
        if latex == solvable_latex:
            return {"success": True, "answer": "x = 4", "problem": latex}
        return {"success": False, "error": "unreadable"}

    monkeypatch.setattr(solver_service, "solve_problem_from_latex", fake_solve)


def test_gemini_read_that_solves_skips_pix2tex(monkeypatch):
    calls = []
    _stub_engines(monkeypatch, pix2tex_out="X", gemini_out="2x+5=13", gemini_on=True, calls=calls)
    _stub_solver(monkeypatch, solvable_latex="2x+5=13")

    result = solver_service.solve_image(b"img")

    assert result["success"] is True
    assert result["latex"] == "2x+5=13"
    assert calls == ["gemini"]  # cloud read solved; the local model never ran


def test_falls_back_to_pix2tex_when_gemini_does_not_solve(monkeypatch):
    calls = []
    _stub_engines(monkeypatch, pix2tex_out="2x+5=13", gemini_out="garbled", gemini_on=True, calls=calls)
    _stub_solver(monkeypatch, solvable_latex="2x+5=13")

    result = solver_service.solve_image(b"img")

    assert result["success"] is True
    assert result["latex"] == "2x+5=13"
    assert calls == ["gemini", "pix2tex"]  # tried cloud first, then local fallback


def test_no_gemini_key_uses_pix2tex_offline(monkeypatch):
    calls = []
    _stub_engines(monkeypatch, pix2tex_out="2x+5=13", gemini_out="X", gemini_on=False, calls=calls)
    _stub_solver(monkeypatch, solvable_latex="2x+5=13")

    result = solver_service.solve_image(b"img")

    assert result["success"] is True
    assert result["latex"] == "2x+5=13"
    assert calls == ["pix2tex"]  # no key -> Gemini skipped, local engine solves


def test_gemini_error_falls_back_to_pix2tex(monkeypatch):
    calls = []

    def boom(_):
        calls.append("gemini")
        raise ocr_service.OCRServiceError("gemini unreachable")

    monkeypatch.setattr(ocr_service, "gemini_to_latex", boom)
    monkeypatch.setattr(
        ocr_service, "pix2tex_to_latex",
        lambda _: (calls.append("pix2tex"), "2x+5=13")[1],
    )
    monkeypatch.setattr(ocr_service, "gemini_available", lambda: True)
    _stub_solver(monkeypatch, solvable_latex="2x+5=13")

    result = solver_service.solve_image(b"img")

    assert result["success"] is True
    assert result["latex"] == "2x+5=13"
    assert calls == ["gemini", "pix2tex"]


def test_both_engines_fail_returns_unreadable(monkeypatch):
    calls = []
    _stub_engines(monkeypatch, pix2tex_out="garbled", gemini_out="also junk", gemini_on=True, calls=calls)
    _stub_solver(monkeypatch, solvable_latex="never")

    result = solver_service.solve_image(b"img")

    assert result["success"] is False
    assert calls == ["gemini", "pix2tex"]  # both tried, both failed


def test_disable_pix2tex_returns_gemini_failure_without_local_fallback(monkeypatch):
    calls = []
    _stub_engines(monkeypatch, pix2tex_out="2x+5=13", gemini_out="garbled", gemini_on=True, calls=calls)
    _stub_solver(monkeypatch, solvable_latex="2x+5=13")
    monkeypatch.setattr(solver_service.settings, "disable_pix2tex", True)

    result = solver_service.solve_image(b"img")

    assert result["success"] is False
    assert result["latex"] == "garbled"
    assert calls == ["gemini"]
