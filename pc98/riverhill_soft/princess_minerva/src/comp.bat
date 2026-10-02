set $DRIVER=minrva_m
nasm -f bin -l %$DRIVER%.LST -o %$DRIVER%.BIN %$DRIVER%.ASM
