# Binding Spaces

This specification defines the concept of *binding spaces*. Every identifier binding exists in some binding space. The identifier bindings described in the RnRS (variables, keywords, pattern variables, record names) exist in the default binding space. An identifier can have bindings in different binding spaces simultaneously. An identifier can only be bound in a non-default binding space if it has a binding in the default binding space.

## Syntax

    define-binding-space <identifier> [<guard-expression>]

The `define-binding-space` form is a definition, binding `<identifier>` to a newly created binding space. If `<guard-expression>` is present, it is evaluated at expand-time and associated with the binding space.  It is an assertion valuation if it doesn't evaluate to a procedure.

    define-binding-in <binding-space> <identifier> <expression>

The `define-binding-in` form is a definition.  The `<expression>` is evaluated at expand-time and `<identifier>` is bound to its value in the binding space named by `<binding-space>`. It is a syntax violation if `<binding-space>` does not name a binding space. If a guard procedure is associated with `<binding-space>`, the result of evaluating `<expression>` is first mapped by the procedure to obtain the final value. A binding in the default binding space for `<identifier>` is created if `<identifier>` was previously unbound.

    resolve-binding-in <binding-space> <identifier-expression>

The `resolve-binding` expression evaluates the `<identifier-expression>` to obtain an identifier and returns the binding of the identifier in `<binding-space>` or #f if there is no such binding. It is an assertion violation if `<identifier-expression>` does not evaluate to an identifier. It is a syntax violation if `<binding-space>` does not name a binding-space. It is an assertion violation to invoke `resolve-binding-in` outside the dynamic extent of a macro invocation calling a binding space transformer procedure (see `make-binding-space-transformer` below).

    define-export-set <identifier> (<binding-space> <exported-identifier> ...)

The `define-export-set` form is a definition, binding `<identifier>` to a newly created *export set*. The `<exported-identifier>`s must be bound in the `<binding-space>`. Their bindings are recorded under their symbolic names in the export set.

    import-bindings <export-set> ...

The `import-bindings` form is a definition, binding, for each `<export-set>` the recorded bindings as if by `define-binding-in`. The lexical context of the bound identifiers is the lexical context of the `<export-set>` identifier.

## Procedures

    make-binding-space-transformer PROCEDURE

Turns the transformer procedure `PROCEDURE` in a binding space transformer procedure.
