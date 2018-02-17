set DRIVER=pacmn_98
nasmw -f bin -l %DRIVER%.lst -o %DRIVER%.com %DRIVER%.asm
set DRIVER=pacmnf_98
nasmw -f bin -l %DRIVER%.lst -o %DRIVER%.com %DRIVER%.asm
