(import
  (rnrs)
  (binding-spaces))

(define-binding-space foo-space
  (lambda (x)
    (unless (procedure? x)
      (assertion-violation 'define-binding-in "foo-space only allows procedure bindings" x))
    x))

(define-binding-in foo-space bar
  (lambda (x)
    #`'#,(datum->syntax #'* x)))

(define-syntax quux
  (make-binding-space-transformer
    (lambda (stx)
      (syntax-case stx ()
        [(_ a)
         ((resolve-binding-in foo-space #'a (lambda (x) "not bound"))
          "Hello")]))))

(display (quux bar))
(newline)

(define-export-set my-export-set (foo-space bar))
(let ([bar 10])
  (display (quux bar))
  (newline)
  (let* ()
    (import-bindings my-export-set)
    (display (quux bar))
    (newline)))
