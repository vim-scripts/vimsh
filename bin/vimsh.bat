@echo off
rem
rem To use, execute:
rem
rem    ASSOC .vimsh=VimShellScript
rem    FTYPE VimShellScript=vimsh.bat "%1"
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
rem start in 'ex' mode, 'readonly', 'noswapfile'
vim -eRn -c "silent /^function Interpret/,/^endfunction/yank z | silent @z | bd | call Interpret() | :q" %0 %1
exit 0

The following function parses a '.vimsh' script file of the form:

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
NOTE: If your Vim script requests input, you have to press Enter the first
      time to get your prompt.  This is a DOS anomaly I haven't figured out
			(yet!).

function Interpret()
	set nomore
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
	execute 'silent :!echo MSDOS style vimsh interperter'
	let @b=''
	let newlinePos=match(@a,"\<NL>")
	while newlinePos != -1
		let echoline=strpart(@a,0,newlinePos)
		let @a=strpart(@a,newlinePos+1)
		let newlinePos=match(@a,"\<NL>")
		"DOS ECHO doesn't like empty echoes, it prints the command print status
		"of ECHO if there are no arguments to it.
		if echoline !~ '^\s*$'
			let @b=@b.'echo '.echoline.'&&'
		else
			let @b=@b.'echo.&&'
		endif
	endwhile
	let @b='silent :!'.@b.'echo '.@a
	execute @b
endfunction
