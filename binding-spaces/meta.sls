#!r6rs
(library (binding-spaces meta)
  (export
    define-binding-space-property
    call-with-binding-space-resolver
    make-binding-space
    binding-space?
    binding-space-property-key
    binding-space-guard-procedure
    define-export-set-property
    call-with-export-set-resolver
    make-export
    export?
    export-property-key
    export-property
    export-symbol)
  (import
    (rnrs)
    (only (chezscheme)
      define-property))

  (define binding-space-key)

  (define-syntax define-binding-space-property
    (lambda (stx)
      (syntax-case stx ()
        [(_ name expr)
         (identifier? #'name)
         #'(define-property name binding-space-key
             (let ([binding-space expr])
               (assert (binding-space? binding-space))
               binding-space))])))

  (define call-with-binding-space-resolver
    (lambda (proc)
      (lambda (lookup)
        (define resolver
          (lambda (name)
            (assert (identifier? name))
            (guard (c [(syntax-violation? c) #f])
              (lookup name #'binding-space-key))))
        (let ([stx (proc resolver)])
          (if (procedure? stx)
              (stx lookup)
              stx)))))

  (define-record-type binding-space
    (nongenerative binding-space-b572035d-0e96-4c89-94bd-aa29b4c12f44)
    (sealed #t)
    (fields property-key guard-procedure)
    (protocol
      (lambda (p)
        (lambda (property-key guard-procedure)
          (assert (identifier? #'property-key))
          (assert (identifier? guard-procedure))
          (p property-key guard-procedure)))))

  (define export-set-key)

  (define-syntax define-export-set-property
    (lambda (stx)
      (syntax-case stx ()
        [(_ name expr)
         (identifier? #'name)
         #'(define-property name export-set-key
             (let ([export-set expr])
               (assert (and (list? export-set)
                            (for-all export? export-set)))
               export-set))])))

  (define call-with-export-set-resolver
    (lambda (proc)
      (lambda (lookup)
        (define resolver
          (lambda (name)
            (assert (identifier? name))
            (guard (c [(syntax-violation? c) #f])
              (lookup name #'export-set-key))))
        (let ([stx (proc resolver)])
          (if (procedure? stx)
              (stx lookup)
              stx)))))

  (define-record-type export
    (nongenerative export-be657545-82f7-4050-ab13-e630934f0ee5)
    (sealed #t)
    (fields property-key property symbol)
    (protocol
      (lambda (p)
        (lambda (property-key property symbol)
          (assert (identifier? property-key))
          (assert (identifier? property))
          (assert (symbol? symbol))
          (p property-key property symbol))))))
