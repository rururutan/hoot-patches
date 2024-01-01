set DRIVER=hinv_98
nasm -f bin -l %DRIVER%.lst -o %DRIVER%.com %DRIVER%.asm

set DRIVER=pinv_98
nasm -f bin -l %DRIVER%.lst -o %DRIVER%.com %DRIVER%.asm

set DRIVER=ninv_98
nasm -f bin -l %DRIVER%.lst -o %DRIVER%.com %DRIVER%.asm

set DRIVER=hmenu_98
nasm -f bin -l %DRIVER%.lst -o %DRIVER%.com %DRIVER%.asm
