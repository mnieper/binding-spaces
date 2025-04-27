;;; "qq" stands for "Quine quotation"

(library (example qq)
  (export
    qq
    define-qq-symbol
    define-qq-export-set)
  (import
    (rnrs)
    (binding-spaces))

  (define-binding-space qq-space
    (lambda (x)
      (datum->syntax #'* x)))

  (define-syntax qq
    (make-binding-space-transformer
      (lambda (stx)
        (syntax-case stx ()
          [(_ tmpl)
           #`'#,(let f ([tmpl #'tmpl])
                  (syntax-case tmpl ()
                    [_ (identifier? tmpl) (resolve-binding-in qq-space tmpl tmpl)]
                    [(sub-tmpl ...)
                     #`(#,@(map f #'(sub-tmpl ...)))]
                    [_ (syntax-violation #f "invalid template" stx tmpl)]))]))))

  (define-syntax define-qq-symbol
    (lambda (stx)
      (syntax-case stx ()
        [(_ name meaning)
         #'(define-binding-in qq-space name meaning)])))

  (define-syntax define-qq-export-set
    (make-binding-space-transformer
      (lambda (stx)
        (syntax-case stx ()
          [(_ export-set-name qq-symbol ...)
           (for-all identifier? #'(export-set-name qq-symbol ...))
           (begin
             (for-each
               (lambda (qq-symbol)
                 (unless (resolve-binding-in qq-space qq-symbol)
                   (syntax-violation #f "attempt to export unbound identifier" stx qq-symbol)))
               #'(qq-symbol ...))
             #'(define-export-set export-set-name (qq-space qq-symbol ...)))])))))
