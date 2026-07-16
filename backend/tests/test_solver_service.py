"""Tests for the hybrid OCR orchestration in solver_service.solve_image.

The rule under test: read locally (pix2tex) first, and only fall back to Gemini
when the local read doesn't yield a *solvable* equation. The OCR engines and the
solve step are mocked so no model/Ollama/network is touched -- what we're
verifying is the routing (which engine is used, when), not the OCR or the math.
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


def test_local_read_that_solves_skips_gemini(monkeypatch):
    calls = []
    _stub_engines(monkeypatch, pix2tex_out="2x+5=13", gemini_out="X", gemini_on=True, calls=calls)
    _stub_solver(monkeypatch, solvable_latex="2x+5=13")

    result = solver_service.solve_image(b"img")

    assert result["success"] is True
    assert result["latex"] == "2x+5=13"
    assert "gemini" not in calls  # local was good enough; no API call


def test_falls_back_to_gemini_when_local_read_does_not_solve(monkeypatch):
    calls = []
    _stub_engines(monkeypatch, pix2tex_out="garbled", gemini_out="2x+5=13", gemini_on=True, calls=calls)
    _stub_solver(monkeypatch, solvable_latex="2x+5=13")

    result = solver_service.solve_image(b"img")

    assert result["success"] is True
    assert result["latex"] == "2x+5=13"
    assert calls == ["pix2tex", "gemini"]  # tried local first, then fell back


def test_no_gemini_key_returns_local_failure(monkeypatch):
    calls = []
    _stub_engines(monkeypatch, pix2tex_out="garbled", gemini_out="X", gemini_on=False, calls=calls)
    _stub_solver(monkeypatch, solvable_latex="never")

    result = solver_service.solve_image(b"img")

    assert result["success"] is False
    assert result["latex"] == "garbled"
    assert calls == ["pix2tex"]  # no fallback attempted


def test_local_crash_still_falls_back_to_gemini(monkeypatch):
    calls = []

    def boom(_):
        calls.append("pix2tex")
        raise RuntimeError("model blew up")
    monkeypatch.setattr(ocr_service, "pix2tex_to_latex", boom)
    monkeypatch.setattr(ocr_service, "gemini_to_latex", lambda _: (calls.append("gemini"), "2x+5=13")[1])
    monkeypatch.setattr(ocr_service, "gemini_available", lambda: True)
    _stub_solver(monkeypatch, solvable_latex="2x+5=13")

    result = solver_service.solve_image(b"img")

    assert result["success"] is True
    assert result["latex"] == "2x+5=13"
    assert calls == ["pix2tex", "gemini"]
