" Vim syntax file
" Language:     Perl 6
" Last Change:  Dec 12th 2008
" Contributors: Luke Palmer <fibonaci@babylonia.flatirons.org>
"               Moritz Lenz <moritz@faui2k3.org>
"               Hinrik Örn Sigurðsson <hinrik.sig@gmail.com>
"                
" This is a big undertaking. Perl 6 is the sort of language that only Perl
" can parse. But I'll do my best to get vim to.
"
" You can associate the extension ".pl" with the filetype "perl6" by setting
"     autocmd BufNewFile,BufRead *.pl setf perl6
" in your ~/.vimrc. But that will infringe on Perl 5, so you might want to
" put a modeline near the beginning or end of your Perl 6 files instead:
"     # vim: filetype=perl6

" TODO:
"   * Add more support for folding
"   * Add more syntax syncing hooks
"   * Highlight « :key<val> » correctly
"   * Overhaul Q// and its derivatives
"   * Overhaul regexes
"
" Impossible TODO?:
"   * Unspace
"   * Unicode
"   * Pod's :allow

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

" this should eventually be put in a $VIMRUNTIME/indent/perl6.vim file
setlocal autoindent expandtab smarttab shiftround shiftwidth=4 softtabstop=4

" this belongs in $VIMRUNTIME/ftplugin/perl6.vim
setlocal iskeyword=@,48-57,_,162-186,192-255

" Billions of keywords
" Don't use the "syn keyword" construct because that always has a higher
" priority than matches/regions, so the words can't be autoquoted with
" the "=>" and "p5=>" operators
syn match p6Attention      display "\k\@<!\%(ACHTUNG\|ATTN\|ATTENTION\|FIXME\)\k\@!" contained
syn match p6Attention      display "\k\@<!\%(NB\|TODO\|TBD\|WTF\|XXX\|NOTE\)\k\@!" contained
syn match p6DeclareRoutine display "\k\@<!\%(macro\|sub\|submethod\|method\|multi\|only\|rule\)\k\@!"
syn match p6DeclareRoutine display "\k\@<!\%(token\|regex\|category\)\k\@!"
syn match p6Module         display "\k\@<!\%(module\|class\|role\|use\|require\|package\|enum\)\k\@!"
syn match p6Module         display "\k\@<!\%(grammar\|subset\|self\)\k\@!"
syn match p6VarStorage     display "\k\@<!\%(let\|my\|our\|state\|temp\|has\|proto\|constant\)\k\@!"
syn match p6Repeat         display "\k\@<!\%(for\|loop\|repeat\|while\|until\|gather\)\k\@!"
syn match p6FlowControl    display "\k\@<!\%(take\|do\|when\|next\|last\|redo\|given\|return\|lastcall\)\k\@!"
syn match p6FlowControl    display "\k\@<!\%(default\|exit\|make\|continue\|break\|goto\|leave\|async\)\k\@!"
syn match p6FlowControl    display "\k\@<!\%(contend\|maybe\|defer\)\k\@!"
syn match p6TypeConstraint display "\k\@<!\%(is\|as\|but\|does\|can\|isa\|trusts\|of\|returns\|also\|handles\)\k\@!"
syn match p6ClosureTrait   display "\k\@<!\%(BEGIN\|CHECK\|INIT\|START\|FIRST\|ENTER\|LEAVE\|KEEP\)\k\@!"
syn match p6ClosureTrait   display "\k\@<!\%(UNDO\|NEXT\|LAST\|PRE\|POST\|END\|CATCH\|CONTROL\|TEMP\)\k\@!"
syn match p6Exception      display "\k\@<!\%(die\|fail\|try\|warn\)\k\@!"
syn match p6Property       display "\k\@<!\%(prec\|irs\|ofs\|ors\|export\|deep\|binary\|unary\)\k\@!"
syn match p6Property       display "\k\@<!\%(rw\|parsed\|cached\|readonly\|instead\|defequiv\|will\)\k\@!"
syn match p6Property       display "\k\@<!\%(ref\|copy\|inline\|tighter\|looser\|equiv\|assoc\|reparsed\)\k\@!"
syn match p6Type           display "\k\@<!\%(Object\|Any\|Junction\|Whatever\|Capture\|Match\)\k\@!"
syn match p6Type           display "\k\@<!\%(Signature\|Proxy\|Matcher\|Package\|Module\|Class\)\k\@!"
syn match p6Type           display "\k\@<!\%(Grammar\|Scalar\|Array\|Hash\|KeyHash\|KeySet\|KeyBag\)\k\@!"
syn match p6Type           display "\k\@<!\%(Pair\|List\|Seq\|Range\|Set\|Bag\|Mapping\|Void\|Undef\)\k\@!"
syn match p6Type           display "\k\@<!\%(Failure\|Exception\|Code\|Block\|Routine\|Sub\|Macro\)\k\@!"
syn match p6Type           display "\k\@<!\%(Method\|Submethod\|Regex\|Str\|Blob\|Char\|Byte\)\k\@!"
syn match p6Type           display "\k\@<!\%(Codepoint\|Grapheme\|StrPos\|StrLen\|Version\|Num\)\k\@!"
syn match p6Type           display "\k\@<!\%(Complex\|num\|complex\|Bit\|Bool\|bit\|bool\|True\|False\)\k\@!"
syn match p6Type           display "\k\@<!\%(Increasing\|Decreasing\|Ordered\|Callable\|AnyChar\)\k\@!"
syn match p6Type           display "\k\@<!\%(Positional\|Associative\|Ordering\|KeyExtractor\|Bool::False\)\k\@!"
syn match p6Type           display "\k\@<!\%(Comparator\|OrderingPair\|IO\|KitchenSink\|Bool::True\)\k\@!"
syn match p6Type           display "\k\@<!\%(Int\|int\|int1\|int2\|int4\|int8\|int16\|int32\|int64\)\k\@!"
syn match p6Type           display "\k\@<!\%(Rat\|rat\|rat1\|rat2\|rat4\|rat8\|rat16\|rat32\|rat64\)\k\@!"
syn match p6Type           display "\k\@<!\%(UInt\|uint\|uint1\|uint2\|uint4\|uint8\|uint16\)\k\@!"
syn match p6Type           display "\k\@<!\%(uint32\|uint64\|Buf\|buf\|buf1\|buf2\|buf4\|buf8\)\k\@!"
syn match p6Type           display "\k\@<!\%(buf16\|buf32\|buf64\)\k\@!"
syn match p6Type           display "\k\@<!\%(Order\%(::Same\|::Increase\|::Decrease\)\?\)\k\@!"
syn match p6Number         display "\k\@<!\%(NaN\|Inf\)\k\@!"
syn match p6Routine        display "\k\@<!\%(WHAT\|WHICH\|VAR\|eager\|hyper\|substr\|index\|rindex\)\k\@!"
syn match p6Routine        display "\k\@<!\%(grep\|map\|sort\|join\|split\|reduce\|min\|max\|reverse\)\k\@!"
syn match p6Routine        display "\k\@<!\%(truncate\|zip\|cat\|roundrobin\|classify\|first\|sum\)\k\@!"
syn match p6Routine        display "\k\@<!\%(keys\|values\|pairs\|defined\|delete\|exists\|elems\)\k\@!"
syn match p6Routine        display "\k\@<!\%(end\|kv\|arity\|assuming\|pick\|clone\|key\|new\)\k\@!"
syn match p6Routine        display "\k\@<!\%(any\|all\|none\|one\|wrap\|shape\|value\)\k\@!"
syn match p6Routine        display "\k\@<!\%(callsame\|callwith\|nextsame\|nextwith\|ACCEPTS\)\k\@!"
syn match p6Routine        display "\k\@<!\%(pop\|push\|shift\|splice\|unshift\|floor\|ceiling\)\k\@!"
syn match p6Routine        display "\k\@<!\%(abs\|exp\|log\|log10\|rand\|sign\|sqrt\|sin\|cos\|tan\)\k\@!"
syn match p6Routine        display "\k\@<!\%(round\|srand\|roots\|cis\|unpolar\|polar\|atan2\)\k\@!"
syn match p6Routine        display "\k\@<!\%(p5chop\|chop\|p5chomp\|chomp\|lc\|lcfirst\|uc\|ucfirst\)\k\@!"
syn match p6Routine        display "\k\@<!\%(capitalize\|normalize\|pack\|unpack\|quotemeta\|comb\)\k\@!"
syn match p6Routine        display "\k\@<!\%(samecase\|sameaccent\|chars\|nfd\|nfc\|nfkd\|nfkc\)\k\@!"
syn match p6Routine        display "\k\@<!\%(printf\|sprintf\|caller\|evalfile\|run\|runinstead\)\k\@!"
syn match p6Routine        display "\k\@<!\%(nothing\|want\|bless\|chr\|ord\|gmtime\)\k\@!"
syn match p6Routine        display "\k\@<!\%(localtime\|time\|gethost\|getpw\|chroot\|getlogin\)\k\@!"
syn match p6Routine        display "\k\@<!\%(kill\|fork\|wait\|perl\|graphs\|codes\|bytes\)\k\@!"
syn match p6Routine        display "\k\@<!\%(print\|open\|read\|write\|readline\|say\|seek\|close\)\k\@!"
syn match p6Routine        display "\k\@<!\%(opendir\|readdir\|slurp\|pos\|fmt\|vec\|link\|unlink\)\k\@!"
syn match p6Routine        display "\k\@<!\%(symlink\|uniq\|pair\|asin\|atan\|sec\|cosec\|connect\)\k\@!"
syn match p6Routine        display "\k\@<!\%(cotan\|asec\|acosec\|acotan\|sinh\|cosh\|tanh\|asinh\)\k\@!"
syn match p6Routine        display "\k\@<!\%(achosh\|atanh\|sech\|cosech\|cotanh\|sech\|acosech\)\k\@!"
syn match p6Routine        display "\k\@<!\%(acotanh\|plan\|ok\|dies_ok\|lives_ok\|skip\|todo\)\k\@!"
syn match p6Routine        display "\k\@<!\%(pass\|flunk\|force_todo\|use_ok\|isa_ok\|cmp_ok\)\k\@!"
syn match p6Routine        display "\k\@<!\%(diag\|is_deeply\|isnt\|like\|skip_rest\|unlike\)\k\@!"
syn match p6Routine        display "\k\@<!\%(nonce\|eval_dies_ok\|eval_lives_ok\|succ\|pred\|times\)\k\@!"
syn match p6Routine        display "\k\@<!\%(approx\|is_approx\|throws_ok\|version_lt\|signature\)\k\@!"
syn match p6Routine        display "\k\@<!\%(eval\|operator\|undef\|undefine\|sleep\|from\|to\)\k\@!"
syn match p6Routine        display "\k\@<!\%(infix\|postfix\|prefix\|circumfix\|postcircumfix\)\k\@!"
syn match p6Routine        display "\k\@<!\%(minmax\|lazy\|count\|nok_error\|unwrap\|getc\|pi\)\k\@!"
syn match p6Routine        display "\k\@<!\%(acos\|e\|context\|void\|quasi\|body\|each\|contains\)\k\@!"
syn match p6Operator       display "\k\@<!\%(x\|xx\|div\|mod\|also\|leg\|cmp\)\k\@!"
syn match p6Operator       display "\k\@<!\%(eq\|ne\|lt\|le\|gt\|ge\|eqv\|ff\|fff\|true\|not\)\k\@!"
syn match p6Operator       display "\k\@<!\%(Z\|X\|and\|andthen\|or\|xor\|orelse\|extra\)\k\@!"

" more operators
syn match p6Operator display "[-+/*~?|=^!%&,<>.;\\]\+"
syn match p6Operator display "\%(:\@<!::\@!\|::=\|\.::\)"
" these require whitespace on the left side
syn match p6Operator display "\%(\s\|^\)\@<=\%(xx=\|p5=>\)"
" "i" requires a digit to the left, and a no keyword char to the right
syn match p6Operator display "\d\@<=i\k\@!"
" reduce
syn match p6Operator display "\[\%(\*-\|\d\|[[:digit:];]\+]\|[^\]]*\%([@$%&]\+[^\]]\|[^\]]\+([^\]]*)\)\)\@![^\][:space:]]\+]"
" hyperoperators
syn match p6Operator display "X[^X[:space:]]\+X"
syn match p6Operator display "\%(>>\|»\)[^«»<>[:space:]]\+"
syn match p6Operator display "[^«»<>[:space:]]\+\%(«\|<<\)"
syn match p6Operator display "»[^«»<>[:space:]]\+«"
syn match p6Operator display ">>[^«»<>[:space:]]\+<<"

syn match p6Shebang     display "\%^#!.*"
syn match p6BlockLabel  display "\%(\s\|^\)\@<=\h\w*\s*::\@!\%(\s\|$\)\@="
syn match p6Conditional display "\%(if\|else\|elsif\|unless\)\%($\|\s\)\@="
syn match p6Number      display "\k\@<!-\?_\@!\%(\d\|__\@!\)\+_\@<!\%([eE]_\@!+\?\%(\d\|_\)\+\)\?_\@<!"
syn match p6Float       display "\k\@<!-\?_\@!\%(\d\|__\@!\)\+_\@<![eE]_\@!-\%(\d\|_\)\+"
syn match p6Float       display "\k\@<!-\?_\@<!\%(\d\|__\@!\)*_\@<!\.\@<!\._\@!\.\@!\a\@!\%(\d\|_\)\+_\@<!\%([eE]_\@!\%(\d\|_\)\+\)\?"
syn match p6Number      display "\<0o[0-7][0-7_]*"
syn match p6Number      display "\<0b[01][01_]*"
syn match p6Number      display "\<0x\x[[:xdigit:]_]*"
syn match p6Number      display "\<0d\d[[:digit:]_]*"

" try to distinguish the "is" function from the "is" trail auxiliary
syn match p6Routine     display "\%(\%(^\|{\)\s*\)\@<=is\k\@!"

" these Routine names are also Properties, if preceded by "is"
syn match p6Property    display "\%(is\s\+\)\@<=\%(signature\|context\)"

syn match p6Sigil        display "[$&%@]\+\%(::\|\%([.^*+?=!]\|:\@<!::\@!\)\|\%(\k\d\@<!\)\)\@=" nextgroup=p6Twigil,p6Variable,p6PackageScope

" this is the regex for an identifier, it will show up elsewhere as well
syn match p6Variable     display "\k\d\@<!\%(\k\|[-']\%(\k[-'[:digit:]]\@!\)\@=\)*" contained

syn match p6Twigil       display "\%([.^*+?=!]\|:\@<!::\@!\)\%(\k\d\@<!\)\@=" nextgroup=p6Variable contained
syn match p6PackageScope display "\%(\k\d\@<!\%(\k\|[-']\%(\k[-'[:digit:]]\@!\)\@=\)*\)\?::" nextgroup=p6PackageScope,p6Variable contained

" only allow identifiers as the first thing after "use" et al
syn match p6Package display "\%(\<\%(use\|module\|class\)\s\+\)\@<=\k\d\@<!\%(\k\|[-']\%(\k[-'[:digit:]]\@!\)\@=\)*"

" this is an operator, not a sigil
syn match p6Operator display "&&"

" the "!" in "$!" is a variable name, not an operator
syn match p6Variable display "\%([$@%&]\+\)\@<=!"

syn match p6CustomRoutine display "\%(\<\%(sub\|method\|submethod\|macro\|rule\|regex\|token\)\s\+\)\@<=\k\d\@<!\%(\k\|[-']\%(\k[-'[:digit:]]\@!\)\@=\)*"
syn match p6CustomRoutine display "\%(\<\%(multi\|proto\|only\)\s\+\)\@<=\%(\%(sub\|method\|submethod\|macro\)\>\)\@!\k\d\@<!\%(\k\|[-']\%(\k[-'[:digit:]]\@!\)\@=\)*"

" Contextualizers

syn match p6Context display "\%(\$\|@\|%\|@@\)\%(\s\|$\)\@="
syn match p6Context display "\<\%(item\|list\|slice\|hash\)\>"

syn region p6SigilContext
    \ matchgroup=p6Context
    \ start="\$("
    \ start="@("
    \ start="%("
    \ start="&("
    \ start="@@("
    \ skip="([^)]*)"
    \ end=")"
    \ transparent

syn region p6WordContext
    \ matchgroup=p6Context
    \ start="\<item\s*(\%(\s*[^)]\)\@="
    \ start="\<list\s*(\%(\s*[^)]\)\@="
    \ start="\<hash\s*(\%(\s*[^)]\)\@="
    \ start="\<slice\s*(\%(\s*[^)]\)\@="
    \ end=")"
    \ transparent

" the "$" placeholder in "$var1, $, var2 = @list"
syn match p6Placeholder display "\%(,\s*\)\@<=\$\%(\k\d\@<!\|\%([.^*+?=!]\|:\@<!::\@!\)\)\@!"
syn match p6Placeholder display "\$\%(\k\d\@<!\|\%([.^*+?=!]\|:\@<!::\@!\)\)\@!\%(,\s*\)\@="

" Comments

syn match p6Comment display "#.*" contains=p6Attention

syn region p6Comment
    \ matchgroup=p6Comment
    \ start="^\@<!#("
    \ skip="([^)]*)"
    \ end=")"
    \ matchgroup=p6Error
    \ start="^#("
    \ contains=p6Attention
syn region p6Comment
    \ matchgroup=p6Comment
    \ start="^\@<!#\["
    \ skip="\[[^\]]*]"
    \ end="]"
    \ matchgroup=p6Error
    \ start="^#\["
    \ contains=p6Attention
syn region p6Comment
    \ matchgroup=p6Comment
    \ start="^\@<!#{"
    \ skip="{[^}]*}"
    \ end="}"
    \ matchgroup=p6Error
    \ start="^#{"
    \ contains=p6Attention
syn region p6Comment
    \ matchgroup=p6Comment
    \ start="^\@<!#<"
    \ skip="<[^>]*>"
    \ end=">"
    \ matchgroup=p6Error
    \ start="^#<"
    \ contains=p6Attention
syn region p6Comment
    \ matchgroup=p6Comment
    \ start="^\@<!#«"
    \ skip="«[^»]*»"
    \ end="»"
    \ matchgroup=p6Error
    \ start="^#«"
    \ contains=p6Attention

" Interpolated strings

" { ... } closure in interpolated strings
syn region p6InterpClosure
    \ start="\\\@!{"
    \ skip="{[^}]*}"
    \ end="}"
    \ contained
    \ contains=TOP

syn cluster p6Interp
    \ add=p6Sigil
    \ add=p6InterpClosure
    \ add=p6SigilContext

" "string"
syn region p6InterpStringDoubleQuote
    \ matchgroup=p6Quote
    \ start=+"+
    \ skip=+\\\@<!\\"+
    \ end=+"+
    \ contains=@p6Interp
" «string»
syn region p6InterpStringDoubleAngle
    \ matchgroup=p6Quote
    \ start="«"
    \ skip="\\\@<!\\»"
    \ end="»"
    \ contains=@p6Interp
" <<string>>
syn region p6InterpStringAngles
    \ matchgroup=p6Quote
    \ start="<<"
    \ skip="\\\@<!\\>"
    \ end=">>"

" Punctuation-delimited interpolated strings
syn region p6InterpString
    \ matchgroup=p6Quote
    \ start="\<q[qwx]\(:\(!\?[[:alnum:]]\((\w\+)\)\?\)\+\)\?\s*\z([^[:alnum:]:#_ ]\)"
    \ skip="\\\z1"
    \ end="\z1"
    \ contains=@p6Interp
syn region p6InterpString
    \ matchgroup=p6Quote
    \ start="\<q[qwx]\(:\(!\?[[:alnum:]]\((\w\+)\)\?\)\+\)\?\s*{"
    \ skip="\\}"
    \ end="}"
    \ contains=@p6Interp
syn region p6InterpString
    \ matchgroup=p6Quote
    \ start="\<q[qwx]\(:\(!\?[[:alnum:]]\((\w\+)\)\?\)\+\)\?\s*("
    \ skip="\\)"
    \ end=")"
    \ contains=@p6Interp
syn region p6InterpString
    \ matchgroup=p6Quote
    \ start="\<q[qwx]\(:\(!\?[[:alnum:]]\((\w\+)\)\?\)\+\)\?\s*\["
    \ skip="\\]"
    \ end="]"
    \ contains=@p6Interp
syn region p6InterpString
    \ matchgroup=p6Quote
    \ start="\<q[qwx]\(:\(!\?[[:alnum:]]\((\w\+)\)\?\)\+\)\?\s*<"
    \ skip="\\>"
    \ end=">"
    \ contains=@p6Interp

" Literal strings

syn match p6EscapedSlash display "\\\@<!\\\\" contained
syn match p6EscapedQuote display "\\\@<!\\'"  contained
syn match p6EscapedAngle display "\\\@<!\\>"  contained

" 'string'
syn region p6LiteralStringQuote
    \ matchgroup=p6Quote
    \ start="'"
    \ skip="\\\@<!\\'"
    \ end="'"
    \ contains=p6EscapedSlash,p6EscapedQuote
" <string>
" FIXME: not sure how to distinguish this from the "less than" operator
" in all cases. For now, it only matches if:
" * There is whitespace missing on either side of the "<", since
"   people tend to put spaces around "less than"
" * It comes after "enum" or "for"
syn region p6LiteralStringAngle
    \ matchgroup=p6Quote
    \ start="\%([-+~!]\|\%(\%(enum\|for\)\s*\)\@<!\s\|<\)\@<!<[-=]\@!"
    \ start="\%([-+~!]\|<\)\@<!<\%(\s\|[-=]\)\@!"
    \ skip="\%(\\\@<!\\>\|<[^>]*>\)"
    \ end=">"
    \ contains=p6EscapedSlash,p6EscapedAngle

" $<rule>
syn region p6LiteralStringMatch
    \ matchgroup=p6Quote
    \ start="\$<\(.*>\)\@="
    \ end=">\@<!>"

" Punctuation-delimited literal strings
syn region p6LiteralString
    \ matchgroup=p6Quote
    \ start="\<q\(:\(!\?[[:alnum:]]\((\w\+)\)\?\)\+\)\?\s*\z([^[:alnum:]:#_ ]\)"
    \ skip="\\\z1"
    \ end="\z1"
syn region p6LiteralString
    \ matchgroup=p6Quote
    \ start="\<q\(:\(!\?[[:alnum:]]\((\w\+)\)\?\)\+\)\?\s*{"
    \ skip="\\}"
    \ end="}"
syn region p6LiteralString
    \ matchgroup=p6Quote
    \ start="\<q\(:\(!\?[[:alnum:]]\((\w\+)\)\?\)\+\)\?\s*("
    \ skip="\\)"
    \ end=")"
syn region p6LiteralString
    \ matchgroup=p6Quote
    \ start="\<q\(:\(!\?[[:alnum:]]\((\w\+)\)\?\)\+\)\?\s*\["
    \ skip="\\]"
    \ end="]"
syn region p6LiteralString
    \ matchgroup=p6Quote
    \ start="\<q\(:\(!\?[[:alnum:]]\((\w\+)\)\?\)\+\)\?\s*<"
    \ skip="\\>"
    \ end=">"

" :string
syn match p6LiteralString display "\%(:\@<!:!\?\)\@<=\w\+"

" => and p5=> autoquoting
syn match p6LiteralString display "\k\d\@<!\%(\k\|[-']\%(\k[-'[:digit:]]\@!\)\@=\)*\ze\s\+p5=>"
syn match p6LiteralString display "\k\d\@<!\%(\k\|[-']\%(\k[-'[:digit:]]\@!\)\@=\)*\ze\%(p5\)\@<!=>"
syn match p6LiteralString display "\k\d\@<!\%(\k\|[-']\%(\k[-'[:digit:]]\@!\)\@=\)*\ze\s\+=>"
syn match p6LiteralString display "\k\d\@<!\%(\k\|[-']\%(\k[-'[:digit:]]\@!\)\@=\)*p5\ze=>"

" =<> is an operator, not a quote
syn region p6Iterate
    \ matchgroup=p6Operator
    \ start="=<<\@!"
    \ skip="<[^>]>"
    \ end=">"
    \ contains=TOP

" Regexes

syn cluster p6Regexen
    \ add=@p6Interp
    \ add=p6Closure
    \ add=p6Comment
    \ add=p6CharClass
    \ add=p6RuleCall
    \ add=p6TestExpr
    \ add=p6RegexSpecial

" Standard /.../
syn region p6Regex
    \ matchgroup=p6Keyword
    \ start="\(\w\_s*\)\@<!/"
    \ start="\(\(\<split\|\<grep\)\s*\)\@<=/"
    \ skip="\\/"
    \ end="/"
    \ contains=@p6Regexen

" m:/.../
syn region p6Regex
    \ matchgroup=p6Keyword
    \ start="\<\(m\|mm\|rx\)\_s*\(\_s*:\_s*[[:alnum:]_()]\+\)*\_s*\z([^[:alnum:]_:(]\)"
    \ skip="\\\z1"
    \ end="\z1"
    \ contains=@p6Regexen

" m:[] m:{} and m:<>
syn region p6Regex
    \ matchgroup=p6Keyword
    \ start="\<\(m\|mm\|rx\)\_s*\(\_s*:\_s*[[:alnum:]_()]\+\)*\_s*\["
    \ skip="\\]"
    \ end="]"
    \ contains=@p6Regexen
syn region p6Regex
    \ matchgroup=p6Keyword
    \ start="\<\(m\|mm\|rx\)\_s*\(\_s*:\_s*[[:alnum:]_()]\+\)*\_s*{"
    \ skip="\\}"
    \ end="}"
    \ contains=@p6Regexen
syn region p6Regex
    \ matchgroup=p6Keyword
    \ start="\<\(m\|mm\|rx\)\_s*\(\_s*:\_s*[[:alnum:]_()]\+\)*\_s*<"hs=e
    \ skip="\\>"
    \ end=">"
    \ contains=@p6Regexen

" rule { }
syn region p6Regex
    \ start="rule\(\_s\+\w\+\)\{0,1}\_s*{"hs=e
    \ end="}"
    \ contains=@p6Regexen
"syn region p6Regex
"    \ start="\(rule\|token\|regex\)\(\_s\+\w\+\)\{0,1}\_s*{"hs=e
"    \ end="}"
"    \ contains=@p6Regexen

" Closure (FIXME: Really icky hack, also doesn't support :blah modifiers)
" However, don't do what you might _expect_ would work, because it won't.
" And no variant of it will, either.  I found this out through 4 hours from
" miniscule tweaking to complete redesign. This is the only way I've found!
"syn region p6Closure
"    \ start="\(\(rule\(\_s\+\w\+\)\{0,1}\|s\|rx\)\_s*\)\@<!{"
"    \ end="}"
"    \ matchgroup=p6Error
"    \ end="[\])]"
"    \ contains=TOP
"    \ fold
"syn region p6Closure
"    \ start="\(\(\(rule\|token\|regex\)\(\_s\+\w\+\)\{0,1}\|s\|rx\)\_s*\)\@<!{"
"    \ end="}"
"    \ matchgroup=p6Error
"    \ end="[\])]"
"    \ contains=TOP
"    \ fold

" s:///, tr:///,  and all variants
syn region p6Regex
    \ matchgroup=p6Keyword
    \ start="\<s\_s*\(\_s*:\_s*[[:alnum:]_()]\+\)*\_s*\z([^[:alnum:]_:(]\)"
    \ skip="\\\z1"
    \ end="\z1"me=e-1
    \ contains=@p6Regexen
    \ nextgroup=p6SubNonBracket
syn region p6Regex
    \ matchgroup=p6Keyword
    \ start="\<s\_s*\(\_s*:\_s*[[:alnum:]_()]\+\)*\_s*\["
    \ skip="\\]"
    \ end="]\_s*"
    \ contains=@p6Regexen
    \ nextgroup=p6SubBracket
syn region p6Regex
    \ matchgroup=p6Keyword
    \ start="\<s\_s*\(\_s*:\_s*[[:alnum:]_()]\+\)*\_s*{"
    \ skip="\\}"
    \ end="}\_s*"
    \ contains=@p6Regexen
    \ nextgroup=p6SubBracket
syn region p6Regex
    \ matchgroup=p6Keyword
    \ start="\<s\_s*\(\_s*:\_s*[[:alnum:]_()]\+\)*\_s*<"
    \ skip="\\>"
    \ end=">\_s*"
    \ contains=@p6Regexen
    \ nextgroup=p6SubBracket
syn region p6Regex
    \ matchgroup=p6Keyword
    \ start="\<tr\_s*\(\_s*:\_s*[[:alnum:]_()]\+\)*\_s*\z([^[:alnum:]_:(]\)"
    \ skip="\\\z1"
    \ end="\z1"me=e-1
    \ nextgroup=p6TransNonBracket

" This is kinda tricky. Since these are contained, they're "called" by the
" previous four groups. They just pick up the delimiter at the current location
" and behave like a string.
syn region p6SubNonBracket
    \ matchgroup=p6Keyword
    \ start="\z(\W\)"
    \ skip="\\\z1"
    \ end="\z1"
    \ contained
    \ contains=@p6Interp
syn region p6SubBracket
    \ matchgroup=p6Keyword
    \ start="\z(\W\)"
    \ skip="\\\z1"
    \ end="\z1"
    \ contained
    \ contains=@p6Interp
syn region p6SubBracket
    \ matchgroup=p6Keyword
    \ start="\["
    \ skip="\\]"
    \ end="]"
    \ contained
    \ contains=@p6Interp
syn region p6SubBracket
    \ matchgroup=p6Keyword
    \ start="{"
    \ skip="\\}"
    \ end="}"
    \ contained
    \ contains=@p6Interp
syn region p6SubBracket
    \ matchgroup=p6Keyword
    \ start="<"
    \ skip="\\>"
    \ end=">"
    \ contained
    \ contains=@p6Interp
syn region p6TransNonBracket
    \ matchgroup=p6Keyword
    \ start="\z(\W\)"
    \ skip="\\\z1"
    \ end="\z1"
    \ contained

syn match  p6RuleCall     contained "<\s*!\{0,1}\s*\w\+"hs=s+1
syn match  p6CharClass    contained "<\s*!\{0,1}\s*\[\]\{0,1}[^]]*\]\s*>"
syn match  p6CharClass    contained "<\s*!\{0,1}\s*-\{0,1}\(alpha\|digit\|sp\|ws\|null\|xdigit\|alnum\|space\|ascii\|cntrl\|graph\|lower\|print\|punct\|title\|upper\|word\|vspace\|hspace\)\s*>"
syn match  p6CharClass    contained "\\[HhVvNnTtEeRrFfWwSs]"
syn match  p6CharClass    contained "\\[xX]\(\[[0-9a-f;]\+\]\|\x\+\)"
syn match  p6CharClass    contained "\\0\(\[[0-7;]\+\]\|\o\+\)"
syn region p6CharClass
    \ start="\\[QqCc]\["
    \ skip="\\]"
    \ end="]"
    \ contained
syn match  p6RegexSpecial contained "\\\@<!:\{1,3\}"
syn match  p6RegexSpecial contained "<\s*\(cut\|commit\)\s*>"
"syn match p6RegexSpecial contained "\\\@<![+*|]"
syn match  p6RegexSpecial contained ":="
syn region p6CharClass
    \ start=+<\s*!\{0,1}\s*\z(['"]\)+
    \ skip="\\\z1"
    \ end="\z1\s*>"
    \ contained
"syn region p6TestExpr
"    \ start="<\s*!\{0,1}\s*("
"    \ end=")\s*>"
"    \ contained
"    \ contains=TOP
syn region p6TestExpr
    \ start="<\(?\|!\)?{"
    \ end="}\s*>"
    \ contained
    \ contains=TOP

" This is an operator, not a regex
syn match p6Operator "//"

" Pod

" Abbreviated blocks
syn region p6PodAbbrRegion
    \ matchgroup=p6PodCommand
    \ start="^=\ze\k\+"
    \ end="^\ze\%(\s*$\|=\k\)"
    \ contains=p6PodAbbrType
    \ keepend

syn region p6PodAbbrType
    \ matchgroup=p6PodType
    \ start="\k\+"
    \ end="^\ze\%(\s*$\|=\k\)"
    \ contained
    \ contains=p6PodName,p6PodAbbr

syn match p6PodName ".\+" contained contains=p6PodFormat

syn region p6PodAbbr
    \ start="^"
    \ end="^\ze\%(\s*$\|=\k\)"
    \ contained
    \ contains=@p6PodAmbient

" Directives
syn region p6PodDirectRegion
    \ matchgroup=p6PodCommand
    \ start="^=\%(config\|use\)\>"
    \ end="^\ze\%([^=]\|=\k\|$\)"
    \ contains=p6PodDirectArgRegion
    \ keepend

syn region p6PodDirectArgRegion
    \ matchgroup=p6PodType
    \ start="\S\+"
    \ end="^\ze\%([^=]\|=\k\|$\)"
    \ contained
    \ contains=p6PodDirectConfigRegion

syn region p6PodDirectConfigRegion
    \ start=""
    \ end="^\ze\%([^=]\|=\k\|$\)"
    \ contained
    \ contains=@p6PodConfig

" =encoding is a special directive
syn region p6PodDirectRegion
    \ matchgroup=p6PodCommand
    \ start="^=encoding\>"
    \ end="^\ze\%([^=]\|=\k\|$\)"
    \ contains=p6PodEncodingArgRegion
    \ keepend

syn region p6PodEncodingArgRegion
    \ matchgroup=p6PodName
    \ start="\S\+"
    \ end="^\ze\%([^=]\|=\k\|$\)"
    \ contained

" Paragraph blocks
syn region p6PodParaRegion
    \ matchgroup=p6PodCommand
    \ start="^=for\>"
    \ end="^\ze\%(\s*\|=\k\)"
    \ contains=p6PodParaTypeRegion

syn region p6PodParaTypeRegion
    \ matchgroup=p6PodType
    \ start="\S\+"
    \ end="^\ze\%(\s*$\|=\k\)"
    \ contained
    \ keepend
    \ contains=p6PodPara,p6PodParaConfigRegion

syn region p6PodParaConfigRegion
    \ start=""
    \ end="^\ze\%([^=]\|=\k\)"
    \ contained
    \ contains=@p6PodConfig

syn region p6PodPara
    \ start="^[^=]"
    \ end="^\ze\%(\s*$\|=\k\)"
    \ contained
    \ extend
    \ contains=@p6PodAmbient

" Delimited blocks
syn region p6PodDelimRegion
    \ matchgroup=p6PodCommand
    \ start="^=begin\>"
    \ end="^=end\>"
    \ contains=p6PodDelimTypeRegion

syn region p6PodDelimTypeRegion
    \ matchgroup=p6PodType
    \ start="\k\+"
    \ end="^\ze=end\>"
    \ contained
    \ contains=p6PodDelim,p6PodDelimConfigRegion

syn region p6PodDelimConfigRegion
    \ start=""
    \ end="^\ze\%([^=]\|=\k\|$\)"
    \ contained
    \ contains=@p6PodConfig

" Delimited code blocks
syn region p6PodDelimRegion
    \ matchgroup=p6PodCommand
    \ start="^=begin\>\%(\s*code\>\)\@="
    \ end="^=end\>"
    \ contains=p6PodDelimCodeTypeRegion

syn region p6PodDelimCodeTypeRegion
    \ matchgroup=p6PodType
    \ start="\k\+"
    \ end="^\ze=end\>"
    \ contained
    \ contains=p6PodDelimCode,p6PodDelimConfigRegion

syn cluster p6PodConfig
    \ add=p6PodConfigOperator
    \ add=p6PodExtraConfig

syn region p6Parens
    \ start="("
    \ end=")"
    \ contained
    \ contains=p6Number,p6LiteralStringQuote

syn match p6PodConfigOperator contained ":" nextgroup=p6PodConfigOption
syn match p6PodConfigOption   contained "[^[:space:](<]\+" nextgroup=p6Parens,p6LiteralStringAngle
syn match p6PodExtraConfig    contained "^="

syn region p6PodDelim
    \ start="^"
    \ end="^\ze=end\>"
    \ contained
    \ contains=@p6PodNested,@p6PodAmbient

syn region p6PodDelimCode
    \ start="^"
    \ end="^\ze=end\>"
    \ contained
    \ contains=@p6PodNested

syn region p6PodDelimEndRegion
    \ matchgroup=p6PodType
    \ start="\%(^=end\>\)\@<="
    \ end="\S\+"

" Special things one may find in Pod prose
syn cluster p6PodAmbient
    \ add=p6PodFormat
    \ add=p6PodImplicitCode

syn match p6PodImplicitCode contained "^\s.*"

" These may appear inside delimited blocks
syn cluster p6PodNested
    \ add=p6PodAbbrRegion
    \ add=p6PodDirectRegion
    \ add=p6PodParaRegion
    \ add=p6PodDelimRegion
    \ add=p6PodDelimEndRegion

" Pod formatting codes

syn region p6PodFormat
    \ matchgroup=p6PodFormatDelim
    \ start="\u<<\@!"
    \ skip="<[^>]*>"
    \ end=">"
    \ contained
    \ contains=p6PodFormat

syn region p6PodFormat
    \ matchgroup=p6PodFormatDelim
    \ start="\u<<"
    \ skip="<[^>]*>"
    \ end=">>"
    \ contained
    \ contains=p6PodFormat

syn region p6PodFormat
    \ matchgroup=p6PodFormatDelim
    \ start="\u««\@!"
    \ end="»"
    \ contained
    \ contains=p6PodFormat

" C<> and V<> don't allow nested formatting formatting codes

syn region p6PodFormat
    \ matchgroup=p6PodFormatDelim
    \ start="[CV]<<\@!"
    \ skip="<[^>]*>"
    \ end=">"
    \ contained

syn region p6PodFormat
    \ matchgroup=p6PodFormatDelim
    \ start="[CV]<<"
    \ skip="<[^>]*>"
    \ end=">>"
    \ contained

syn region p6PodFormat
    \ matchgroup=p6PodFormatDelim
    \ start="[CV]««\@!"
    \ end="»"
    \ contained

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_perl6_syntax_inits")
    if version < 508
        let did_perl6_syntax_inits = 1
        command -nargs=+ HiLink hi link <args>
    else
        command -nargs=+ HiLink hi def link <args>
    endif

    HiLink p6InterpString            p6String
    HiLink p6InterpStringDoubleQuote p6String
    HiLink p6InterpStringDoubleAngle p6String
    HiLink p6InterpStringAngles      p6String
    HiLink p6LiteralString           p6String
    HiLink p6LiteralStringQuote      p6String
    HiLink p6LiteralStringAngle      p6String
    HiLink p6LiteralStringMatch      p6String
    HiLink p6SubNonBracket           p6String
    HiLink p6SubBracket              p6String
    HiLink p6TransNonBracket         p6String
    HiLink p6EscapedSlash     p6StringSpecial
    HiLink p6EscapedQuote     p6StringSpecial
    HiLink p6EscapedAngle     p6StringSpecial
    HiLink p6CharClass        p6StringSpecial
    HiLink p6RegexSpecial     p6StringSpecial

    HiLink p6Property        Tag
    HiLink p6Attention       Todo
    HiLink p6Type            Type
    HiLink p6Error           Error
    HiLink p6BlockLabel      Label
    HiLink p6Float           Float
    HiLink p6Package         Normal
    HiLink p6PackageScope    Normal
    HiLink p6Number          Number
    HiLink p6String          String
    HiLink p6Regex           String
    HiLink p6Repeat          Repeat
    HiLink p6Keyword         Keyword
    HiLink p6Routine         Keyword
    HiLink p6Module          Keyword
    HiLink p6DeclareRoutine  Keyword
    HiLink p6VarStorage      Keyword
    HiLink p6FlowControl     Special
    HiLink p6Comment         Comment
    HiLink p6Shebang         PreProc
    HiLink p6ClosureTrait    PreProc
    HiLink p6CustomRoutine   Function
    HiLink p6Operator        Operator
    HiLink p6Twigil          Operator
    HiLink p6Context         Operator
    HiLink p6Quote           Delimiter
    HiLink p6TypeConstraint  PreCondit
    HiLink p6Exception       Exception
    HiLink p6Sigil           Identifier
    HiLink p6Variable        Identifier
    HiLink p6Placeholder     Identifier
    HiLink p6RuleCall        Identifier
    HiLink p6Conditional     Conditional
    HiLink p6StringSpecial   SpecialChar

    HiLink p6PodAbbr         p6Pod
    HiLink p6PodPara         p6Pod
    HiLink p6PodDelim        p6Pod
    HiLink p6PodDelimCode    p6PodCode
    HiLink p6PodImplicitCode p6PodCode
    HiLink p6PodExtraConfig  p6PodCommand

    HiLink p6PodType           Type
    HiLink p6PodConfigOption   String
    HiLink p6Pod               Comment
    HiLink p6PodFormat         Special
    HiLink p6PodConfigOperator Operator
    HiLink p6PodFormatDelim    Delimiter
    HiLink p6PodCommand        Statement
    HiLink p6PodName           Identifier
    HiLink p6PodCode           SpecialComment

    delcommand HiLink
endif

" Syncing to speed up processing
syn sync fromstart
syn sync maxlines=100
syn sync match p6SyncPod groupthere p6PodAbbrRegion     "^=\k\+\>"
syn sync match p6SyncPod groupthere p6PodDirectRegion   "^=\%(config\|use\|encoding\)\>"
syn sync match p6SyncPod groupthere p6PodParaRegion     "^=for\>"
syn sync match p6SyncPod groupthere p6PodDelimRegion    "^=begin\>"
syn sync match p6SyncPod groupthere p6PodDelimEndRegion "^=end\>"

setlocal foldmethod=syntax

let b:current_syntax = "perl6"
