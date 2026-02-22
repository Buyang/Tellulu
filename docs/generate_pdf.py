#!/usr/bin/env python3
"""Convert technical_design.md to a professional PDF using fpdf2 (pure Python)."""

import re
from fpdf import FPDF

INPUT_FILE = "/Users/buyang/.gemini/antigravity/playground/tellulu/tellulu/docs/technical_design.md"
OUTPUT_FILE = "/Users/buyang/Desktop/Tellulu_Technical_Design.pdf"

# Color palette
NAVY = (22, 33, 62)        # #16213e
ACCENT = (159, 160, 206)   # #9FA0CE
DARK_BLUE = (44, 62, 107)  # #2c3e6b
BODY = (26, 26, 46)        # #1a1a2e
LIGHT_BG = (244, 245, 251) # #f4f5fb
TABLE_HDR = (44, 62, 107)  # #2c3e6b
TABLE_ALT = (248, 249, 252)# #f8f9fc
GRAY = (120, 120, 140)
CODE_BG = (240, 242, 248)
CODE_BLOCK_BG = (30, 30, 46)
CODE_BLOCK_FG = (205, 214, 244)
HR_COLOR = (216, 218, 232)


class TelluluPDF(FPDF):
    def __init__(self):
        super().__init__(format='letter')
        self.set_auto_page_break(auto=True, margin=25)

    def header(self):
        if self.page_no() > 1:
            self.set_font('Helvetica', 'I', 8)
            self.set_text_color(*GRAY)
            self.cell(0, 6, 'Tellulu - Technical Design Document', align='C')
            self.ln(4)

    def footer(self):
        self.set_y(-15)
        self.set_font('Helvetica', '', 9)
        self.set_text_color(*GRAY)
        self.cell(0, 10, f'{self.page_no()}', align='C')

    def chapter_title(self, text, level=1):
        if level == 1:
            self.set_font('Helvetica', 'B', 24)
            self.set_text_color(*NAVY)
            self.multi_cell(0, 11, text)
            # Accent underline
            self.set_draw_color(*ACCENT)
            self.set_line_width(1.2)
            self.line(self.l_margin, self.get_y() + 2, self.w - self.r_margin, self.get_y() + 2)
            self.ln(8)
        elif level == 2:
            self.ln(6)
            self.set_font('Helvetica', 'B', 15)
            self.set_text_color(*NAVY)
            self.multi_cell(0, 8, text)
            self.set_draw_color(220, 220, 230)
            self.set_line_width(0.5)
            self.line(self.l_margin, self.get_y() + 1, self.w - self.r_margin, self.get_y() + 1)
            self.ln(5)
        elif level == 3:
            self.ln(4)
            self.set_font('Helvetica', 'B', 12)
            self.set_text_color(*DARK_BLUE)
            self.multi_cell(0, 7, text)
            self.ln(2)
        elif level == 4:
            self.ln(2)
            self.set_font('Helvetica', 'B', 10.5)
            self.set_text_color(74, 85, 104)
            self.multi_cell(0, 6, text)
            self.ln(2)

    def body_text(self, text):
        self.set_font('Helvetica', '', 10)
        self.set_text_color(*BODY)
        # Handle inline formatting
        self.multi_cell(0, 5.5, text)
        self.ln(2)

    def bullet_item(self, text, indent=0):
        x = self.l_margin + 4 + indent
        self.set_x(x)
        self.set_font('Helvetica', '', 10)
        self.set_text_color(*BODY)
        bullet = '-  '
        w = self.w - self.r_margin - x
        self.multi_cell(w, 5.5, bullet + text)
        self.ln(1)

    def numbered_item(self, num, text, indent=0):
        x = self.l_margin + 4 + indent
        self.set_x(x)
        self.set_font('Helvetica', '', 10)
        self.set_text_color(*BODY)
        prefix = f'{num}.  '
        w = self.w - self.r_margin - x
        self.multi_cell(w, 5.5, prefix + text)
        self.ln(1)

    def blockquote(self, text):
        self.ln(3)
        x = self.l_margin
        y = self.get_y()
        # Background
        self.set_fill_color(*LIGHT_BG)
        self.rect(x, y, self.w - self.l_margin - self.r_margin, 16, 'F')
        # Left accent bar
        self.set_fill_color(*ACCENT)
        self.rect(x, y, 2.5, 16, 'F')
        # Text
        self.set_xy(x + 8, y + 3)
        self.set_font('Helvetica', 'I', 9.5)
        self.set_text_color(*DARK_BLUE)
        self.multi_cell(self.w - self.l_margin - self.r_margin - 12, 5, text)
        self.ln(5)

    def code_block(self, text):
        self.ln(2)
        x = self.l_margin
        y = self.get_y()
        lines = text.split('\n')
        height = max(len(lines) * 4.5 + 8, 12)
        # Check page break
        if y + height > self.h - 25:
            self.add_page()
            y = self.get_y()
        # Background
        self.set_fill_color(*CODE_BLOCK_BG)
        self.rect(x, y, self.w - self.l_margin - self.r_margin, height, 'F')
        # Text
        self.set_xy(x + 5, y + 4)
        self.set_font('Courier', '', 8)
        self.set_text_color(*CODE_BLOCK_FG)
        for line in lines:
            self.set_x(x + 5)
            self.cell(0, 4.5, line)
            self.ln(4.5)
        self.ln(4)

    def add_table(self, headers, rows):
        self.ln(3)
        # Calculate column widths
        available = self.w - self.l_margin - self.r_margin
        n_cols = len(headers)
        col_widths = [available / n_cols] * n_cols

        # Adjust: first column slightly narrower if many columns
        if n_cols >= 4:
            col_widths = []
            total = available
            first_w = min(20, total * 0.08)
            rest = (total - first_w) / (n_cols - 1)
            col_widths = [first_w] + [rest] * (n_cols - 1)
        elif n_cols == 3:
            col_widths = [available * 0.25, available * 0.45, available * 0.30]

        # Header row
        self.set_font('Helvetica', 'B', 8.5)
        self.set_fill_color(*TABLE_HDR)
        self.set_text_color(255, 255, 255)
        for i, h in enumerate(headers):
            self.cell(col_widths[i], 7, h.strip(), border=0, fill=True)
        self.ln()

        # Data rows
        self.set_font('Helvetica', '', 8.5)
        for r_idx, row in enumerate(rows):
            # Alternate row color
            if r_idx % 2 == 1:
                self.set_fill_color(*TABLE_ALT)
                fill = True
            else:
                self.set_fill_color(255, 255, 255)
                fill = True

            self.set_text_color(*BODY)
            max_lines = 1
            # Calculate rows needed
            cells = []
            for i, cell_text in enumerate(row):
                ct = cell_text.strip()
                ct = re.sub(r'`([^`]+)`', r'\1', ct)  # Strip backticks
                cells.append(ct)
                lines_needed = max(1, len(ct) // int(col_widths[i] / 2) + 1)
                max_lines = max(max_lines, lines_needed)

            row_h = max(6, max_lines * 5)

            # Check page break
            if self.get_y() + row_h > self.h - 25:
                self.add_page()
                # Re-draw header
                self.set_font('Helvetica', 'B', 8.5)
                self.set_fill_color(*TABLE_HDR)
                self.set_text_color(255, 255, 255)
                for i, h in enumerate(headers):
                    self.cell(col_widths[i], 7, h.strip(), border=0, fill=True)
                self.ln()
                self.set_font('Helvetica', '', 8.5)
                self.set_text_color(*BODY)

            x_start = self.get_x()
            y_start = self.get_y()

            # Draw fill
            if fill:
                self.rect(x_start, y_start, available, row_h, 'F')

            for i, ct in enumerate(cells):
                self.set_xy(x_start + sum(col_widths[:i]), y_start)
                self.multi_cell(col_widths[i], 5, ct, border=0)

            self.set_y(y_start + row_h)

        self.ln(4)

    def hr(self):
        self.ln(5)
        self.set_draw_color(*HR_COLOR)
        self.set_line_width(0.5)
        self.line(self.l_margin, self.get_y(), self.w - self.r_margin, self.get_y())
        self.ln(5)


def strip_non_latin1(text):
    """Remove characters outside latin-1 range (emoji, special Unicode)."""
    result = []
    for ch in text:
        try:
            ch.encode('latin-1')
            result.append(ch)
        except UnicodeEncodeError:
            # Replace common Unicode with ASCII equivalents
            replacements = {
                '\u2014': '-', '\u2013': '-', '\u2018': "'", '\u2019': "'",
                '\u201c': '"', '\u201d': '"', '\u2022': '-', '\u2192': '->',
                '\u2026': '...', '\u2713': '[x]', '\u2717': '[ ]',
            }
            result.append(replacements.get(ch, ''))
    return ''.join(result)


def clean_inline(text):
    """Strip inline markdown formatting for plain text output."""
    text = re.sub(r'\*\*([^*]+)\*\*', r'\1', text)  # bold
    text = re.sub(r'\*([^*]+)\*', r'\1', text)       # italic
    text = re.sub(r'`([^`]+)`', r'\1', text)         # code
    text = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', text)  # links
    text = text.replace('&', '&')
    text = strip_non_latin1(text)
    return text.strip()


def parse_and_render(pdf, md_text):
    """Parse markdown and render to PDF."""
    lines = md_text.split('\n')
    i = 0
    in_code_block = False
    code_buffer = []
    in_table = False
    table_headers = []
    table_rows = []
    blockquote_buffer = []

    while i < len(lines):
        line = lines[i]

        # Code blocks
        if line.strip().startswith('```'):
            if in_code_block:
                pdf.code_block('\n'.join(code_buffer))
                code_buffer = []
                in_code_block = False
            else:
                # Flush table if pending
                if in_table:
                    pdf.add_table(table_headers, table_rows)
                    in_table = False
                    table_headers = []
                    table_rows = []
                in_code_block = True
            i += 1
            continue

        if in_code_block:
            code_buffer.append(line)
            i += 1
            continue

        # Skip empty lines
        if not line.strip():
            # Flush blockquote
            if blockquote_buffer:
                pdf.blockquote(' '.join(blockquote_buffer))
                blockquote_buffer = []
            # Flush table
            if in_table:
                pdf.add_table(table_headers, table_rows)
                in_table = False
                table_headers = []
                table_rows = []
            i += 1
            continue

        # Blockquotes
        if line.strip().startswith('>'):
            content = re.sub(r'^>\s*', '', line.strip())
            content = clean_inline(content)
            if content:
                blockquote_buffer.append(content)
            i += 1
            continue
        elif blockquote_buffer:
            pdf.blockquote(' '.join(blockquote_buffer))
            blockquote_buffer = []

        # Tables
        if '|' in line and not line.strip().startswith('#'):
            cells = [c.strip() for c in line.split('|')]
            cells = [c for c in cells if c]  # Remove empty
            
            # Check if separator row
            if all(re.match(r'^[-:]+$', c) for c in cells):
                i += 1
                continue
            
            if not in_table:
                in_table = True
                table_headers = [clean_inline(c) for c in cells]
            else:
                table_rows.append([clean_inline(c) for c in cells])
            i += 1
            continue
        elif in_table:
            pdf.add_table(table_headers, table_rows)
            in_table = False
            table_headers = []
            table_rows = []

        # Horizontal rules
        if re.match(r'^-{3,}$', line.strip()):
            pdf.hr()
            i += 1
            continue

        # Headers
        h_match = re.match(r'^(#{1,4})\s+(.+)', line)
        if h_match:
            level = len(h_match.group(1))
            title = clean_inline(h_match.group(2))
            pdf.chapter_title(title, level)
            i += 1
            continue

        # Numbered lists
        num_match = re.match(r'^(\s*)\d+\.\s+(.+)', line)
        if num_match:
            indent = len(num_match.group(1))
            num = re.match(r'(\d+)', line.strip()).group(1)
            text = clean_inline(num_match.group(2))
            pdf.numbered_item(num, text, indent)
            i += 1
            continue

        # Bullet lists
        bullet_match = re.match(r'^(\s*)[-*]\s+(.+)', line)
        if bullet_match:
            indent = len(bullet_match.group(1))
            text = clean_inline(bullet_match.group(2))
            # Handle checkbox syntax
            text = re.sub(r'^\[[ x/]\]\s*', '', text)
            pdf.bullet_item(text, indent // 2 * 4)
            i += 1
            continue

        # Regular paragraph text
        text = clean_inline(line)
        if text:
            pdf.body_text(text)
        i += 1

    # Flush remaining
    if blockquote_buffer:
        pdf.blockquote(' '.join(blockquote_buffer))
    if in_table:
        pdf.add_table(table_headers, table_rows)


def main():
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        md_text = f.read()

    pdf = TelluluPDF()
    pdf.set_margin(20)
    pdf.add_page()

    parse_and_render(pdf, md_text)

    pdf.output(OUTPUT_FILE)
    print(f"✅ PDF generated: {OUTPUT_FILE}")


if __name__ == '__main__':
    main()
