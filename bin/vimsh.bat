@echo off
rem Vim script command line interpreter for MSDOS
rem Language:    vim script
rem Maintainer:  Dave Silvia <dsilvia@mchsi.com>
rem Date:        8/27/2004
rem
rem Version 1.1
rem   Added:
rem     -  Command line arguments
rem
rem To use, execute:
rem
rem    ASSOC .vimsh=VimShellScript
rem    FTYPE VimShellScript=vimsh.bat "%1" %*
rem
rem To eliminate the need to type the extension:
rem
rem    set PATHEXT=%PATHEXT%;.vimsh
rem
rem in autoexec or for WindowXP
rem
rem    Control Panel->System->Advanced-Environment Variables->System variables
rem
rem and
rem
rem    Edit PATHEXT
rem
rem
set SCRIPT=%1
set SCRIPTARGV=%*
# start in 'ex' mode, 'readonly', 'noswapfile'
vim -eRn -c "silent /^function SetUp/,/^endfunction/yank z | silent @z | silent call SetUp() | :q" %0
set SCRIPT=
set SCRIPTARGV=
exit 0

The following functions parse a '.vimsh' script file of the form:

  #!/usr/local/bin/vimsh
	<Vim script code>
	.
	.
	.
	<Vim script code>

It executes the code, capturing the output for Vim internals, and then
echoes the output to the shell.

NOTE: ':!' shell escape commands can be used providing they are not imbedded
      in Vim script constructs such as loops, functions, etc.  This breaks
			the code flow and causes vimsh to hang.

NOTE: DO NOT PLACE ANY CODE/COMMENTS/ETC. AFTER HERE!
function SetUp()
	let scriptName=substitute($SCRIPT,'"','','g')
	let scriptArgv=substitute($SCRIPTARGV,'"','','g')
	let InterpBegin=search('^function Interpret','W')
	/^function Interpret/,$yank z
	silent @z
	bw
	execute 'DoArgs '.scriptArgv
	execute 'silent ex '.scriptName
	set noswapfile nomore readonly
	call Interpret()
endfunction

function Interpret()
	let @a=''
	silent 2,$yank z
	let colonBangPos=match(@z,':!')
	while colonBangPos != -1
		let idx=colonBangPos
		while @z[idx] != "\<NL>" && idx > 0
			let idx=idx-1
		endwhile
		let @e=strpart(@z,0,idx)
		let @z=strpart(@z,idx+1)
		if @e != ''
			let @e="function! ATe()\<NL>".@e."\<NL>endfunction\<NL>"
			silent @e
			redir @A
			call ATe()
			redir END
		endif
		let newlinePos=match(@z,"\<NL>")
		if newlinePos != -1
			let @e=strpart(@z,0,newlinePos)
			let @z=strpart(@z,newlinePos+1)
		else
			let @e=@z
			let @z=''
		endif
		@e
		let colonBangPos=match(@z,':!')
	endwhile
	if @z != ''
		let @z="function! ATz()\<NL>".@z."\<NL>endfunction\<NL>"
		silent @z
		redir @A
		call ATz()
		redir END
	endif
	bw!
	if exists("g:Ret")
		let @a=g:Ret
	endif
	let tmpFile=fnamemodify(expand("~/.vimsh.out"),":p")
	call delete(tmpFile)
	execute 'silent ex +set\ noswapfile '.tmpFile
	silent put a
	silent :w!
	silent bw!
	execute 'silent :!type "'.tmpFile.'"'
endfunction

command -nargs=* DoArgs call DoArgs(<f-args>)
function DoArgs(...)
	let g:0=(a:0)-1
	let thisArgNo=1
	while thisArgNo < a:0
		let g:{thisArgNo}=a:{thisArgNo+1}
		let thisArgNo=thisArgNo+1
	endwhile
endfunction
