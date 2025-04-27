(library (example greek-symbols)
  (export greek-symbols)
  (import
    (rnrs)
    (example qq))

  (define-qq-symbol phi 'φ)
  (define-qq-symbol chi 'χ)
  (define-qq-symbol psi 'ψ)
  (define-qq-symbol omega 'ω)

  (define-qq-export-set greek-symbols
    phi chi psi omega))
