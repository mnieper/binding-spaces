(import
  (rnrs)
  (binding-spaces)
  (example qq)
  (example greek-symbols))

(define omega 24)

(import-bindings greek-symbols)

(display (qq ((first (alpha beta gamma))
              (second (phi chi psi omega)))))
(newline)

(assert (eqv? omega 24))
