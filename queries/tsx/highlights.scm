;; extends

; This is the ONLY thing you need in this file now.
; Neovim 0.12 will load its internal TSX rules first, 
; then layer this on top.
((jsx_attribute
  (property_identifier) @att_name
  (#eq? @att_name "className")
  [
    (string
      (string_fragment) @css_class_attr_value)
    (jsx_expression
      (template_string) @css_class_attr_value)
  ]
  (#set! @css_class_attr_value conceal "…")))

