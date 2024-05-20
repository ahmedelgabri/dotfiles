; extends

; https://github.com/ribru17/.dotfiles/blob/ef879053616bb6dbb3d8c97f417973de119ac7fc/.config/nvim/queries/markdown/

; NOTE: It would be nice to prevent conceals in table cells (because they can
; mess up pipe alignment) but this is currently impossible since there is no way
; to detect if other inline conceals are within table cells because detection is
; split among the parsers.
; Bullet points
([
  (list_marker_minus)
  (list_marker_plus)
  (list_marker_star)
] @markup.list
  (#offset-first-n! @markup.list 1)
  (#set! conceal "•"))

(list
  (list_item
    (list
      (list_item
        ([
          (list_marker_minus)
          (list_marker_plus)
          (list_marker_star)
        ] @markup.list
          (#offset-first-n! @markup.list 1)
          (#set! conceal "◦"))))))

(list
  (list_item
    (list
      (list_item
        (list
          (list_item
            ([
              (list_marker_minus)
              (list_marker_plus)
              (list_marker_star)
            ] @markup.list
              (#offset-first-n! @markup.list 1)
              (#set! conceal "▪"))))))))

(list
  (list_item
    (list
      (list_item
        (list
          (list_item
            (list
              (list_item
                ([
                  (list_marker_minus)
                  (list_marker_plus)
                  (list_marker_star)
                ] @markup.list
                  (#offset-first-n! @markup.list 1)
                  (#set! conceal "▫"))))))))))

(list
  (list_item
    (list
      (list_item
        (list
          (list_item
            (list
              (list_item
                (list
                  (list_item
                    ([
                      (list_marker_minus)
                      (list_marker_plus)
                      (list_marker_star)
                    ] @markup.list
                      (#offset-first-n! @markup.list 1)
                      (#set! conceal "🠢"))))))))))))

; Checkbox list items
((task_list_marker_unchecked) @markup.list.unchecked
  (#set! conceal " ")) ; Alts:✗ ✘ 🗷 ❌☐

((task_list_marker_checked) @markup.list.checked
  (#set! conceal "󰄵 ")) ; Alts:✓ ✔ 🗹 ✅☑

(list_item
  (task_list_marker_checked)
  (_) @comment.syntax)

; Tables
(pipe_table_header
  "|" @punctuation.special
  (#set! conceal "┃"))

(pipe_table_delimiter_row
  "|" @punctuation.special
  (#set! conceal "┃"))

(pipe_table_delimiter_cell
  "-" @punctuation.special
  (#set! conceal "━"))

((pipe_table_align_left) @punctuation.special
  (#set! conceal "┣"))

((pipe_table_align_right) @punctuation.special
  (#set! conceal "┫"))

(pipe_table_row
  "|" @punctuation.special
  (#set! conceal "┃"))

; Block quotes
((block_quote_marker) @punctuation.special
  (#offset! @punctuation.special 0 0 0 -1)
  (#set! conceal "▐"))

((block_continuation) @punctuation.special
  (#lua-match? @punctuation.special "^>")
  (#offset-first-n! @punctuation.special 1)
  (#set! conceal "▐"))

; Thematic breaks
((thematic_break) @punctuation.special
  (#offset! @punctuation.special 0 2 0 0)
  (#set! conceal "━"))

((thematic_break) @punctuation.special
  (#offset! @punctuation.special 0 1 0 0)
  (#set! conceal "━"))

((thematic_break) @punctuation.special
  (#set! conceal "━"))

; Headers
((atx_h1_marker) @markup.heading.1
  (#set! conceal "𝟭"))

((atx_h2_marker) @markup.heading.2
  (#set! conceal "𝟮"))

((atx_h3_marker) @markup.heading.3
  (#set! conceal "𝟯"))

((atx_h4_marker) @markup.heading.4
  (#set! conceal "𝟰"))

((atx_h5_marker) @markup.heading.5
  (#set! conceal "𝟱"))

((atx_h6_marker) @markup.heading.6
  (#set! conceal "𝟲"))

; Ease fenced code block conceals a bit
((fenced_code_block_delimiter) @conceal
  (#set! conceal "~"))

; Awesome fenced code block language conceals using Nerd icons
(fenced_code_block
  (info_string
    (language) @label)
  (#ft-conceal! @label))

; Spell checking for table content
(pipe_table_header
  (pipe_table_cell) @nospell)

(pipe_table_row
  (pipe_table_cell) @spell)
