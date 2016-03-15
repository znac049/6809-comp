
	
;--------------------------------------------------------------------------------
; bb - FAT16 boot block
;
bb		struct
		endstruct

;--------------------------------------------------------------------------------
; dirent - FAT16 directory entry
;
dirent		struct
name		rmb	8
ext		rmb	3
attrib		rmb	1
reserved	rmb	1
creation	rmb	5
accessed	rmb	2
reserved2	rmb	2
lastwrite	rmb	4
cluster		rmb	2
size		rmb	4
		endstruct

