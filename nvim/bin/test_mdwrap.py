#!/usr/bin/env python3
"""Tests for mdwrap."""

import importlib.util
import os
import sys
import unittest

# Import mdwrap as a module despite having no .py extension
_here = os.path.dirname(os.path.abspath(__file__))
_path = os.path.join(_here, "mdwrap")
_loader = importlib.machinery.SourceFileLoader("mdwrap", _path)
_spec = importlib.util.spec_from_loader("mdwrap", _loader, origin=_path)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
mdwrap = _mod.mdwrap


class TestProseWrapping(unittest.TestCase):
    """Prose paragraphs should be wrapped at the given width."""

    def test_long_paragraph_wraps(self):
        text = (
            "This is a long paragraph that should be wrapped at eighty "
            "characters to fit the line length requirement properly."
        )
        result = mdwrap(text, width=80)
        for line in result.splitlines():
            self.assertLessEqual(len(line), 80)

    def test_short_paragraph_unchanged(self):
        text = "Short line."
        self.assertEqual(mdwrap(text, width=80), "Short line.")

    def test_multiple_prose_lines_joined(self):
        text = "Line one\nstill the same\nparagraph here."
        result = mdwrap(text, width=80)
        self.assertEqual(result, "Line one still the same paragraph here.")

    def test_paragraphs_separated_by_blank_line(self):
        text = "First paragraph.\n\nSecond paragraph."
        result = mdwrap(text, width=80)
        self.assertEqual(result, "First paragraph.\n\nSecond paragraph.")

    def test_custom_width(self):
        text = "Word " * 20
        result = mdwrap(text.strip(), width=40)
        for line in result.splitlines():
            self.assertLessEqual(len(line), 40)

    def test_no_break_long_words(self):
        url = "https://example.com/very/long/path/that/exceeds/the/width"
        result = mdwrap(url, width=30)
        self.assertIn(url, result)


class TestTablesPreserved(unittest.TestCase):
    """Tables must pass through completely unchanged."""

    def test_simple_table(self):
        table = (
            "| A | B |\n"
            "|---|---|\n"
            "| 1 | 2 |"
        )
        self.assertEqual(mdwrap(table, width=80), table)

    def test_table_with_uneven_spacing(self):
        table = "| short | data | here |\n|--|--|--|\n| x | y | z |"
        self.assertEqual(mdwrap(table, width=80), table)

    def test_indented_table(self):
        table = "  | A | B |\n  |---|---|\n  | 1 | 2 |"
        self.assertEqual(mdwrap(table, width=80), table)

    def test_table_between_prose(self):
        text = (
            "Paragraph before the table.\n"
            "\n"
            "| H1 | H2 |\n"
            "|----|----|\n"
            "| a  | b  |\n"
            "\n"
            "Paragraph after the table."
        )
        result = mdwrap(text, width=80)
        self.assertIn("| H1 | H2 |", result)
        self.assertIn("| a  | b  |", result)


class TestCodeBlocksPreserved(unittest.TestCase):
    """Code blocks must pass through unchanged, including long lines."""

    def test_backtick_fence(self):
        text = "```\nlong line " + "x" * 200 + "\n```"
        self.assertEqual(mdwrap(text, width=80), text)

    def test_tilde_fence(self):
        text = "~~~\ncode here\n~~~"
        self.assertEqual(mdwrap(text, width=80), text)

    def test_fenced_with_language(self):
        text = "```python\nprint('hello')\n```"
        self.assertEqual(mdwrap(text, width=80), text)

    def test_prose_after_code_block_wraps(self):
        text = (
            "```\ncode\n```\n\n"
            "This prose after a code block should be wrapped properly "
            "when it exceeds the configured width limit."
        )
        result = mdwrap(text, width=60)
        code_lines = result.split("```\n\n")[1].splitlines()
        for line in code_lines:
            self.assertLessEqual(len(line), 60)


class TestHeadingsPreserved(unittest.TestCase):
    """Headings must not be wrapped or joined with prose."""

    def test_headings_unchanged(self):
        for level in range(1, 7):
            heading = "#" * level + " Heading text"
            self.assertEqual(mdwrap(heading, width=80), heading)

    def test_heading_not_joined_with_prose(self):
        text = "# Title\n\nSome prose here."
        result = mdwrap(text, width=80)
        self.assertEqual(result, "# Title\n\nSome prose here.")


class TestListsPreserved(unittest.TestCase):
    """List items must pass through unchanged."""

    def test_unordered_dash(self):
        text = "- Item one\n- Item two"
        self.assertEqual(mdwrap(text, width=80), text)

    def test_unordered_asterisk(self):
        text = "* Item one\n* Item two"
        self.assertEqual(mdwrap(text, width=80), text)

    def test_unordered_plus(self):
        text = "+ Item one\n+ Item two"
        self.assertEqual(mdwrap(text, width=80), text)

    def test_ordered_dot(self):
        text = "1. First\n2. Second"
        self.assertEqual(mdwrap(text, width=80), text)

    def test_ordered_paren(self):
        text = "1) First\n2) Second"
        self.assertEqual(mdwrap(text, width=80), text)


class TestBlockquotesPreserved(unittest.TestCase):
    """Blockquotes must pass through unchanged."""

    def test_simple_blockquote(self):
        text = "> This is a quote.\n> Second line."
        self.assertEqual(mdwrap(text, width=80), text)

    def test_nested_blockquote(self):
        text = "> > Nested quote."
        self.assertEqual(mdwrap(text, width=80), text)


class TestHTMLPreserved(unittest.TestCase):
    """HTML lines must pass through unchanged."""

    def test_html_tag(self):
        text = "<details>\n<summary>Click</summary>\n</details>"
        self.assertEqual(mdwrap(text, width=80), text)


class TestLinkReferencesPreserved(unittest.TestCase):
    """Link reference definitions must pass through unchanged."""

    def test_link_ref(self):
        text = "[1]: https://example.com"
        self.assertEqual(mdwrap(text, width=80), text)


class TestTrailingNewline(unittest.TestCase):
    """Trailing newline in input should be preserved."""

    def test_trailing_newline_preserved(self):
        text = "Some text.\n"
        result = mdwrap(text, width=80)
        self.assertTrue(result.endswith("\n"))

    def test_no_trailing_newline(self):
        text = "Some text."
        result = mdwrap(text, width=80)
        self.assertFalse(result.endswith("\n"))


if __name__ == "__main__":
    unittest.main()
