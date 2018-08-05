.orig   x3000
main
        and     r0, r0, #0  ; x3000: assert r0 = 0
        add     r1, r0, #10 ; x3001: assert r1 = 10
        add     r2, r1, x-F ; x3002: assert r2 = -5

CONST   .fill   xDEAD
CONSTI  .FILL   CONST
.end
