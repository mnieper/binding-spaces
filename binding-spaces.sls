#!r6rs
(library (binding-spaces)
  (export
    define-binding-space
    define-binding-in
    resolve-binding-in
    make-binding-space-transformer
    define-export-set
    import-bindings
    )
  (import
    (rnrs)
    (binding-spaces meta)
    (rename
      (only (chezscheme)
        meta
        define-property
        parameterize
        make-thread-parameter
        quote-syntax)
      (define-property cs:define-property)))

  (define-syntax define-property
    (lambda (stx)
      (syntax-case stx ()
        [(_ name key expr)
         (and (identifier? #'name) (identifier? #'key))
         (lambda (lookup)
           #`(begin
               #,@(if (guard (c [(syntax-violation? c) #f])
                        (lookup #'name #'key)
                        #t)
                      #'()
                      #'((define-syntax name
                           (lambda (stx)
                             (syntax-violation 'name "invalid syntax" stx)))))
               (cs:define-property name key expr)))])))

  (define-syntax define-binding-space
    (lambda (stx)
      (syntax-case stx ()
        [(_ name guard-expr)
         (identifier? #'name)
         #'(begin
             (define-syntax name
               (lambda (stx)
                 (syntax-violation 'name "invalid syntax" stx)))
             (define property-key)
             (meta define guard-procedure
               (let ([guard guard-expr])
                 (unless (procedure? guard)
                   (assertion-violation
                     'define-binding-space "invalid guard procedure" guard))
                 guard))
             (define-binding-space-property name
               (make-binding-space #'property-key #'guard-procedure)))]
        [(_ name)
         (identifier? #'name)
         #'(define-binding-space name (lambda (x) x))])))

  (define-syntax define-binding-in
    (lambda (stx)
      (syntax-case stx ()
        [(_ binding-space-name name expr)
         (and (identifier? #'name) (identifier? #'binding-space))
         (call-with-binding-space-resolver
           (lambda (resolve)
             (let ([binding-space (resolve #'binding-space-name)])
               (unless binding-space
                 (syntax-violation
                   'define-binding-in "invalid binding space" stx #'binding-space-name))
               (with-syntax ([property-key (binding-space-property-key binding-space)]
                             [guard-procedure (binding-space-guard-procedure binding-space)])
                 #'(begin
                     (define-property property * (guard-procedure expr))
                     (define-property name property-key #'property))))))])))

  (define current-resolver (make-thread-parameter #f))

  (define resolve
    (lambda (what binding-space-name id default)
      (let ([resolver (current-resolver)])
        (unless resolver
          (assertion-violation 'resolve-binding-in
            "invoked outside the dynamic extent of a binding transformer call"))
        (resolver what binding-space-name id default))))

  (define make-binding-space-transformer
    (lambda (transformer-proc)
      (unless (procedure? transformer-proc)
        (assertion-violation
          'make-binding-transformer "invalid transformer procedure" transformer-proc))
      (lambda (stx)
        (call-with-binding-space-resolver
          (lambda (binding-space-resolver)
            (lambda (lookup)
              (define resolver
                (lambda (what binding-space-name id default)
                  (let ([binding-space (binding-space-resolver binding-space-name)])
                    (unless (binding-space? binding-space)
                      (syntax-violation 'resolve-binding-in "invalid binding space"
                        what binding-space-name))
                    (guard (c [(syntax-violation? c) #f])
                      (cond
                        [(lookup id (binding-space-property-key binding-space)) =>
                         (lambda (property-id)
                           (lookup property-id #'*))]
                        [else default])))))
              (parameterize ([current-resolver resolver])
                (let ([stx (transformer-proc stx)])
                  (if (procedure? stx)
                      (stx lookup)
                      stx)))))))))

  (define-syntax resolve-binding-in
    (lambda (stx)
      (syntax-case stx ()
        [(_ binding-space-name id-expr default-expr)
         (identifier? #'binding-space-name)
         (with-syntax ([stx stx])
           #'(resolve (quote-syntax stx) (quote-syntax binding-space-name) id-expr default-expr))]
        [(_ binding-space-name id-expr)
         (identifier? #'binding-space-name)
         #'(resolve-binding-in binding-space-name id-expr #f)])))

  (define-syntax define-export-set
    (lambda (stx)
      (call-with-binding-space-resolver
        (lambda (binding-space-resolver)
          (lambda (lookup)
            (syntax-case stx ()
              [(_ name (binding-space-name exported-id ...) ...)
               (for-all identifier? #'(name binding-space-name ... exported-id ... ...))
               (with-syntax
                   ([((property-key property export-name) ...)
                       (let f ([binding-space-name* #'(binding-space-name ...)]
                               [exported-id** #'((exported-id ...) ...)])
                         (if (null? binding-space-name*)
                             '()
                             (let ([binding-space-name (car binding-space-name*)]
                                   [binding-space-name* (cdr binding-space-name*)]
                                   [exported-id* (car exported-id**)]
                                   [exported-id** (cdr exported-id**)])
                               (let g ([exported-id* exported-id*])
                                 (if (null? exported-id*)
                                     (f binding-space-name* exported-id**)
                                     (let ([exported-id (car exported-id*)]
                                           [exported-id* (cdr exported-id*)])
                                       (let ([binding-space (binding-space-resolver binding-space-name)])
                                         (unless binding-space
                                           (syntax-violation
                                             'define-export-set "invalid binding space name" stx binding-space-name))
                                         (let ([property-key (binding-space-property-key binding-space)])
                                           (cond
                                             [(guard (c [(syntax-violation? c) #f])
                                                (lookup exported-id property-key))
                                              => (lambda (property)
                                                   (cons (list property-key property exported-id)
                                                     (g exported-id*)))]
                                             [else
                                               (syntax-violation 'define-export-set
                                                 "identifier has no binding in binding space" stx exported-id)])))))))))])
                 #'(begin
                     (define-syntax name
                       (lambda (stx)
                         (syntax-violation 'name "invalid syntax" stx)))
                     (define-export-set-property name
                       (list (make-export #'property-key #'property 'export-name) ...))))]))))))

  (define-syntax import-bindings
    (lambda (stx)
      (call-with-export-set-resolver
        (lambda (export-set-resolver)
          (syntax-case stx ()
            [(import-bindings export-set-name ...)
             (for-all identifier? #'(export-set-name ...))
             (let ([export-sets
                     (map
                       (lambda (export-set-name)
                         (let ([export-set (export-set-resolver export-set-name)])
                           (unless export-set
                             (syntax-violation 'import-bindings "invalid export set" stx export-set-name))
                           export-set))
                       #'(export-set-name ...))])
               (with-syntax
                   ([(((import-id property-key property) ...) ...)
                     (map
                       (lambda (export-set)
                         (map
                           (lambda (export-set-name export)
                             (list (datum->syntax export-set-name (export-symbol export))
                               (export-property-key export) (export-property export)))
                           #'(export-set-name ...) export-set))
                       export-sets)])
                 #'(begin
                     (define-property import-id property-key #'property)
                     ... ...)))]))))))
