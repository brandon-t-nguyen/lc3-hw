.orig   x3000
        ld  r0, cnt
        ld  r1, val

        and r2, r2, #0
loop
        add r2, r2, r1
        add r0, r0, #-1
        brp loop

        not r3, r2

cnt     .fill   #10
val     .fill   #5
.end
