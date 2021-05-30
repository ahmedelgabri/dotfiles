(import_statement) @muted_imports
; (named_imports) @muted_imports
(import_statement (import_clause) @muted_imports)
(import_statement source: (string) @muted_imports_info)
(import_statement (import_clause (namespace_import) @muted_imports))
(import_clause (identifier) @muted_imports_info)
(namespace_import (identifier) @muted_imports_info)
(import_clause (named_imports) @muted_imports_info)
(import_clause (named_imports (import_specifier)) @muted_imports)
(import_specifier name: (identifier) @muted_imports_info)
