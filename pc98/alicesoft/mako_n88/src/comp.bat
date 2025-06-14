set $DRIVER=n88mako
nasm -f bin -l %$DRIVER%.LST -o %$DRIVER%.BIN %$DRIVER%.ASM
