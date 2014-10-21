# The start of a gimme5 replacement based on STD parsing.
# viv stands for roman numbers VIV (i.e. Perl 5 to 6)
use strict;
use 5.010;
use warnings;

use STD;
use utf8;
use YAML::XS;

my $OPT_pos = 1;
my $OPT_log = 0;

my @context;

sub USAGE {
	print <<'END';
viv [switches] filename
	where switches can be:
		--log	emit debugging info to standard error
END
	exit;
}

sub MAIN {
	USAGE() unless @_;
	while (@_) {
		last unless $_[0] =~ /^-/;
		my $switch = shift @_;
		if ( $switch eq '--log' or $switch eq '-l' ) {
			$OPT_log = 1;
		}
		elsif ( $switch eq '--help' ) {
			USAGE();
		}
	}
	my $r;
	if ( @_ and -f $_[0] ) {
		$r = STD->parsefile( $_[0], actions => 'Actions' )->{'_ast'};
	} else {
		die "no filename\n";
	}
	delete $r->{CORE};
	delete $r->{MATCH}{CORE};
	print fixpod( $r->ret( $r->emit_color(0) ) );

}

sub fixpod {
	my $text = shift;
	return $text unless $text =~ /\n/;
	my @text     = split( /^/, $text );
	my $in_begin = 0;
	my $in_for   = 0;
	for (@text) {
		$in_begin = $1 if /^=begin\s+(\w+)/;
		$in_for   = 1  if /^=for/;
		$in_for   = 0  if /^\s*$/;
		my $docomment = $in_begin || $in_for;
		$in_begin = 0 if /^=end\s+(\w+)/ and $1 eq $in_begin;
		s/^/# / if $docomment;
	}
	join( '', @text );
}

###################################################################

{

	package Actions;

	# Generic ast translation done via autoload

	our $AUTOLOAD;
	my $SEQ = 1;

	sub AUTOLOAD {
		my $self  = shift;
		my $match = shift;
		return if @_;    # not interested in tagged reductions
		return
		  if $match->{_ast}{_specific} and ref( $match->{_ast} ) =~ /^VAST/;
		my $r = hoistast($match);
		( my $class = $AUTOLOAD ) =~ s/^Actions/VAST/;
		$class =~ s/__S_\d\d\d/__S_/ and $r->{_specific} = 1;
		gen_class($class);
		bless $r, $class unless ref($r) =~ /^VAST/;
		$match->{'_ast'} = $r;
	}

	# propagate ->{'_ast'} nodes upward
	# (untransformed STD nodes in output indicate bugs)

	sub hoistast {
		my $node = shift;
		my $text = $node->Str;
		my %r;
		my @all;
		my @fake;
		for my $k ( keys %$node ) {

			#print STDERR $node->{_reduced}, " $k\n";
			my $v = $node->{$k};
			if ( $k eq 'O' ) {
				for my $key ( keys %$v ) {
					$r{$key} = $$v{$key};
				}
			}
			elsif ( $k eq 'PRE' ) {
			}
			elsif ( $k eq 'POST' ) {
			}
			elsif ( $k eq 'SIGIL' ) {
				$r{SIGIL} = $v;
			}
			elsif ( $k eq 'sym' ) {
				if ( ref $v ) {
					if ( ref($v) eq 'ARRAY' ) {
						$r{SYM} = ::Dump($v);
					}
					elsif ( ref($v) eq 'HASH' ) {
						$r{SYM} = ::Dump($v);
					}
					elsif ( $v->{_pos} ) {
						$r{SYM} = $v->Str;
					}
					else {
						$r{SYM} = $v->TEXT;
					}
				}
				else {
					$r{SYM} = $v;
				}
			}
			elsif ( $k eq '_arity' ) {
				$r{ARITY} = $v;
			}
			elsif ( $k eq '~CAPS' ) {

				# print "CAPS ref ". ref($v) . "\n";
				if ( ref $v ) {
					for (@$v) {
						next unless ref $_;    # XXX skip keys?
						push @all, $_->{'_ast'};
					}
				}
			}
			elsif ( $k eq '_from' ) {
				if ($OPT_pos) {
					$r{BEG} = $v;
					$r{END} = $node->{_pos};
				}
				if ( exists $::MEMOS[$v]{'ws'} ) {
					my $wsstart = $::MEMOS[$v]{'ws'};
					$r{WS} = $v - $wsstart
					  if defined $wsstart and $wsstart < $v;
				}
			}
			elsif ( $k =~ /^[a-zA-Z]/ ) {
				if ( $k eq 'noun' ) {    # trim off PRE and POST
					if ($OPT_pos) {
						$r{BEG} = $v->{_from};
						$r{END} = $v->{_pos};
					}
				}
				if ( ref($v) eq 'ARRAY' ) {
					my $zyg = [];
					for my $z (@$v) {
						if ( ref $z ) {
							if ( ref($z) eq 'ARRAY' ) {
								push @$zyg, $z;
								push @fake, @$z;
							}
							elsif ( exists $z->{'_ast'} ) {
								my $zy = $z->{'_ast'};
								push @fake, $zy;
								push @$zyg, $zy;
							}
						}
						else {
							push @$zyg, $z;
						}
					}
					$r{$k} = $zyg;

					#		    $r{zygs}{$k} = $SEQ++ if @$zyg and $k ne 'sym';
				}
				elsif ( ref $v ) {
					if ( exists $v->{'_ast'} ) {
						push @fake, $v->{'_ast'};
						$r{$k} = $v->{'_ast'};
					}
					else {
						$r{$k} = $v;
					}

					#		    $r{zygs}{$k} = $SEQ++;
					unless ( ref( $r{$k} ) =~ /^VAST/ ) {
						my $class = "VAST::$k";
						gen_class($class);
						bless $r{$k}, $class unless ref( $r{$k} ) =~ /^VAST/;
					}
				}
				else {
					$r{$k} = $v;
				}
			}
		}
		if ( @all == 1 and defined $all[0] ) {
			$r{'.'} = $all[0];
		}
		elsif (@all) {
			$r{'.'} = \@all;
		}
		elsif (@fake) {
			$r{'.'} = \@fake;
		}
		else {
			$r{TEXT} = $text;
		}
		\%r;
	}

	sub hoist {
		my $match = shift;

		my %r;
		my $v = $match->{O};
		if ($v) {
			for my $key ( keys %$v ) {
				$r{$key} = $$v{$key};
			}
		}
		if ( $match->{sym} ) {

			#    $r{sym} = $match->{sym};
		}
		if ( $match->{ADV} ) {
			$r{ADV} = $match->{ADV};
		}
	}

	sub CHAIN {
		my $self  = shift;
		my $match = shift;
		my $r     = hoistast($match);

		my $class = $match->{O}{kind} // $match->{sym} // 'termish';
		$class =~ s/^STD:://;
		$class =~ s/^/VAST::/;

		#	print STDERR ::Dump($r);
		gen_class($class);
		$r = bless $r, $class;
		$match->{'_ast'} = $r;
	}

	sub LIST {
		my $self  = shift;
		my $match = shift;
		my $r     = hoist($match);

		my @list   = @{ $match->{list} };
		my @delims = @{ $match->{delims} };
		my @all;
		while (@delims) {
			my $term = shift @list;
			push @all, $term->{_ast};
			my $infix = shift @delims;
			push @all, $infix->{_ast};
		}
		push @all, $list[0]->{_ast} if @list;
		pop @all while @all and not $all[-1]{END};
		$r->{BEG} = $all[0]{BEG};
		$r->{END} = $all[-1]{END} // $r->{BEG};
		$r->{'.'} = \@all;

		my $class = $match->{O}{kind} // $match->{sym} // 'termish';
		$class =~ s/^STD:://;
		$class =~ s/^/VAST::/;
		gen_class($class);
		$r = bless $r, $class;
		$match->{'_ast'} = $r;
	}

	sub POSTFIX {
		my $self  = shift;
		my $match = shift;
		my $r     = hoist($match);
		my $a     = $r->{'.'} = [ $match->{arg}->{_ast}, $match->{_ast} ];
		$r->{BEG} = $a->[0]->{BEG}  // $match->{_from};
		$r->{END} = $a->[-1]->{END} // $match->{_pos};

		my $class = $match->{O}{kind} // $match->{sym} // 'termish';
		$class =~ s/^STD:://;
		$class =~ s/^/VAST::/;
		gen_class($class);
		$r = bless $r, $class;
		$match->{'_ast'} = $r;
	}

	sub PREFIX {
		my $self  = shift;
		my $match = shift;
		my $r     = hoist($match);
		my $a     = $r->{'.'} = [ $match->{_ast}, $match->{arg}->{_ast} ];

		$r->{BEG} = $a->[0]->{BEG}  // $match->{_from};
		$r->{END} = $a->[-1]->{END} // $match->{_pos};

		my $class = $match->{O}{kind} // $match->{sym} // 'termish';
		$class =~ s/^STD:://;
		$class =~ s/^/VAST::/;
		gen_class($class);
		$r = bless $r, $class;
		$match->{'_ast'} = $r;
	}

	sub INFIX {
		my $self  = shift;
		my $match = shift;
		my $r     = hoist($match);
		my $a     = $r->{'.'} =
		  [ $match->{left}->{_ast}, $match->{_ast}, $match->{right}->{_ast} ];
		$r->{BEG} = $a->[0]->{BEG}  // $match->{_from};
		$r->{END} = $a->[-1]->{END} // $match->{_pos};

		my $class = $match->{O}{kind} // $match->{sym} // 'termish';
		$class =~ s/^STD:://;
		$class =~ s/^/VAST::/;
		gen_class($class);
		$r = bless $r, $class;
		$match->{'_ast'} = $r;
	}

	sub EXPR {
		return;
	}

	sub gen_class {
		my $class = shift;

		# say $class;
		no strict 'refs';
		if ( @{ $class . '::ISA' } ) {
			print STDERR "Existing class $class\n" if $OPT_log;
			return;
		}
		print STDERR "Creating class $class\n" if $OPT_log;
		@{ $class . '::ISA' } = 'VAST::Base';
	}

}

###################################################################

{

	package VAST::Base;

	sub ret {
		my $self = shift;
		my $val  = join '', @_;
		my @c    = map { ref $_ } @context;
		my $c    = "@c " . ref($self);
		$c =~ s/VAST:://g;
		print STDERR "$c returns $val\n" if $OPT_log;

		wantarray ? @_ : $val;
	}

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @text;
		$context[$lvl] = $self;

		# print STDERR "HERE " . ref($self) . "\n";
		if ( exists $self->{'.'} ) {
			my $last = $self->{BEG};
			my $all  = $self->{'.'};
			my @kids;
			for my $kid ( ref($all) eq 'ARRAY' ? @$all : $all ) {
				next unless $kid;
				if ( not defined $kid->{BEG} ) {
					$kid->{BEG} = $kid->{_from} // next;
					$kid->{END} = $kid->{_pos};
				}
				push @kids, $kid;
			}
			for my $kid ( sort { $a->{BEG} <=> $b->{BEG} } @kids ) {
				my $kb = $kid->{BEG};
				if ( $kb > $last ) {
					push @text, substr( $::ORIG, $last, $kb - $last );
				}
				if ( ref($kid) eq 'HASH' ) {
					print STDERR ::Dump($self);
				}
				push @text, scalar $kid->emit_color( $lvl + 1 );
				$last = $kid->{END};

			}
			my $se = $self->{END};
			if ( $se > $last ) {
				push @text, substr( $::ORIG, $last, $se - $last );
			}
		}
		else {

			# print STDERR "OOPS " . ref($self) . " $$self{TEXT}\n";
			push @text, $self->{TEXT};
		}
		
		splice( @context, $lvl );
		$self->ret(@text);
	}
	
	sub add_variable {
		my ( $self, $name, $scope ) = @_;
		$name =~ s/^\s+|\s+$//g;
		my $from = $self->{BEG};
		my $line = STD->lineof($from);
		print "declare variable: $name at line $line\n";
		push @{$self->{symbol_table}}, {
			name  => $name,
			from  => $from,
			to    => $self->{END},
			line  => $line,
			scope => $scope,
		}; 
	}

}

{ package VAST::TEXT; our @ISA = 'VAST::Base'; }

{

	package VAST::Additive;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		if ( $t[0] eq '*' ) {    # *-1
			$t[0] = '';
		}
		$self->ret(@t);
	}
}

{

	package VAST::ADVERB;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		my $adv  = pop @t;
		if ( $adv eq ':delete' or $adv eq ':exists' ) {
			$adv =~ s/^://;
			unshift( @t, $adv . ' ' );
			$t[-1] =~ s/\s+$//;
		}
		$self->ret(@t);
	}
}

{

	package VAST::apostrophe;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::arglist;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::args;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::assertion;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::assertion__S_Bang;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::assertion__S_Bra;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::assertion__S_Cur_Ly;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::assertion__S_DotDotDot;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::assertion__S_method;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::assertion__S_name;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::assertion__S_Question;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::atom;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Autoincrement;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::babble;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_Back;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_d;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_h;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_misc;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_n;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_s;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_stopper;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_t;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_v;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_w;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_x;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::before;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::block;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::blockoid;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		print "start block\n";
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		print "end block\n";
		$self->ret(@t);
	}
}

{

	package VAST::capterm;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::cclass_elem;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::circumfix;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::circumfix__S_Bra_Ket;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::circumfix__S_Cur_Ly;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::circumfix__S_Paren_Thesis;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::circumfix__S_sigil;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::codeblock;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::colonpair;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Comma;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::comp_unit;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		$context[$lvl] = $self;

		$self->{symbol_table} = ();

		my $r = $self->ret( $self->{statementlist}->emit_color( $lvl + 1 ) );
		splice( @context, $lvl );

		foreach my $symbol ( @{$self->{symbol_table}} ) {
			print $symbol->{name} . ' ' . 
				$symbol->{line} . ' ' . 
				$symbol->{scope} . "\n";
		}

		$r;
	}
}

{

	package VAST::Concatenation;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Conditional;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		for (@t) {
			s/\?\?/?/;
			s/!!/:/;
		}
		$self->ret(@t);
	}
}

{

	package VAST::CORE;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::declarator;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::default_value;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::deflongname;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::def_module_name;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::desigilname;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::dotty;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::dotty__S_Dot;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::dottyop;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::eat_terminator;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::escape;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::escape__S_At;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::escape__S_Back;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::escape__S_Dollar;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::EXPR;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::fatarrow;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::fulltypename;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::hexint;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::ident;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::identifier;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::index;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_and;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_BangEqual;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_ColonEqual;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$t[0] = '=';    # XXX oversimplified
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_Comma;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_DotDot;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_eq;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_Equal;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_EqualEqual;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_EqualGt;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_gt;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_Gt;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infixish;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_le;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_lt;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_Lt;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_LtEqual;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_Minus;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_ne;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_or;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_orelse;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_Plus;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_PlusAmp;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$t[0] = '&';
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_PlusVert;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$t[0] = '|';
		$self->ret(@t);
	}
}

{

	package VAST::infix_postfix_meta_operator;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix_postfix_meta_operator__S_Equal;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_QuestionQuestion_BangBang;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_SlashSlash;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_Star;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infixstopper;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_Tilde;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$t[0] = '.';
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_TildeTilde;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$t[0] = '=~';
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_TildeVert;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$t[0] = '|';
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_VertVert;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_x;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::integer;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Item_assignment;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Junctive_or;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::label;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::lambda;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$t[0] = 'sub';
		$self->ret(@t);
	}
}

{

	package VAST::left;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::List_assignment;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::litchar;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::longname;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Loose_and;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Loose_or;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Loose_unary;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Back;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Bra_Ket;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Caret;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_CaretCaret;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_ColonColon;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_ColonColonColon;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Cur_Ly;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Dollar;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_DollarDollar;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Dot;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Double_Double;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Lt_Gt;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_mod;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Nch;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Paren_Thesis;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_qw;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_sigwhite;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Single_Single;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_var;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::method_def;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @b    = $self->SUPER::emit_color( $lvl + 1 );
		my @e    = '';
		while (@b) {
			my $t = pop(@b);
			if ( $t =~ s/^\{// ) {
				$t = "{\n    my \$self = shift;\n" . pop(@b) . $t;
				unshift( @e, $t );
				last;
			}
			unshift( @e, $t );
		}
		$self->ret( @b, @e );
	}
}

{

	package VAST::Methodcall;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		if ( @t > 2 ) {
			my $first = shift @t;
			my $second = join '', @t;
			@t = ( $first, $second );
		}
		if ( $t[1] eq '.pos' ) { $t[1] = '.<_pos>'; }
		$t[1] =~ s/^(\.?)<(.*)>$/$1\{'$2'\}/;
		if ( $t[0] =~ /^[@%]/ ) {
			if ( $t[1] =~ s/^\.?([[{])/$1/ ) {
				if ( $t[1] =~ /,/ ) {
					substr( $t[0], 0, 1 ) = '@';
				}
				else {
					substr( $t[0], 0, 1 ) = '$';
				}

			}
		}
		elsif ( $t[0] =~ /^\$\w+$/ ) {
			$t[1] =~ s/^([[{])/.$1/;
		}
		elsif ( $t[0] =~ s/^&(\w+)/\$$1/ ) {
			$t[1] =~ s/^\(/->(/;
		}
		$t[1] =~ s/^\./->/;
		my $t = join( '', @t );
		$t =~ s/^(.*\S)\s*:(delete|exists)/$2 $1/;

		#	print STDERR ::Dump(\@t);
		$self->ret($t);
	}
}

{

	package VAST::methodop;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::modifier_expr;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::mod_internal;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::mod_internal__S_adv;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::mod_internal__S_ColonBangs;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::mod_internal__S_Coloni;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::mod_internal__S_Colonmy;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::mod_internal__S_Colons;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::module_name;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::module_name__S_normal;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::morename;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::multi_declarator;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::multi_declarator__S_multi;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::multi_declarator__S_null;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::multi_declarator__S_proto;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Multiplicative;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::multisig;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		pop(@t);
		shift(@t);
		$self->ret(@t);
	}
}

{

	package VAST::name;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::named_param;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Named_unary;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::nibbler;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::nofun;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Nonchaining;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::normspace;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;

		# print STDERR "HERE " . ref($self) . "\n";
		my $t = $self->SUPER::emit_color( $lvl + 1 );

		# print STDERR "$t in " . ref($context[$lvl-1]);
		$self->ret($t);
	}
}

{

	package VAST::noun__S_capterm;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_circumfix;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_colonpair;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_fatarrow;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_multi_declarator;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_package_declarator;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_regex_declarator;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_routine_declarator;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_scope_declarator;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_statement_prefix;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_term;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_value;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_variable;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		print "variable used: @t\n";
		$self->ret(@t);
	}
}

{

	package VAST::nulltermish;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::number;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::number__S_numish;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::numish;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::opener;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::package_declarator;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::package_declarator__S_class;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::package_declarator__S_grammar;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::package_declarator__S_role;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::package_def;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::parameter;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		my $t    = '    my ' . join( '', @t ) . " = shift;\n";
		$self->ret($t);
	}
}

{

	package VAST::param_sep;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::param_var;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::pblock;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::pod_comment;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::POST;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postcircumfix;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postcircumfix__S_Bra_Ket;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postcircumfix__S_Cur_Ly;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postcircumfix__S_Fre_Nch;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postcircumfix__S_Lt_Gt;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$t[0]  = "{'";
		$t[-1] = "'}";
		$self->ret(@t);
	}
}

{

	package VAST::postcircumfix__S_Paren_Thesis;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postfix;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postfix__S_MinusMinus;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postfix__S_PlusPlus;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postfix_prefix_meta_operator;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postfix_prefix_meta_operator__S_Nch;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postop;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::PRE;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::prefix;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::prefix__S_Bang;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::prefix__S_Minus;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::prefix__S_not;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::prefix__S_Plus;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$t[0] = '0+';
		$self->ret(@t);
	}
}

{

	package VAST::prefix__S_temp;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$t[0] = 'local';
		$self->ret(@t);
	}
}

{

	package VAST::quantified_atom;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quantifier;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quantifier__S_Plus;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quantifier__S_Question;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quantifier__S_Star;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quantifier__S_StarStar;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quantmod;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quibble;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quote;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$t[0] =~ s/</qw</;

		#	print STDERR ::Dump(\@t);
		$self->ret(@t);
	}
}

{

	package VAST::quote__S_Double_Double;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quote__S_Fre_Nch;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quote__S_Lt_Gt;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quotepair;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quote__S_s;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quote__S_Single_Single;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quote__S_Slash_Slash;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::regex_block;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::regex_declarator;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::regex_declarator__S_regex;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::regex_declarator__S_rule;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::regex_declarator__S_token;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::regex_def;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Replication;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::right;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::routine_declarator;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::routine_declarator__S_method;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self    = shift;
		my $lvl     = shift;
		my $comment = substr( $::ORIG, $self->{BEG}, 100 );
		$comment =~ s/\s*\{.*//s;
		my $t = join '', $self->SUPER::emit_color( $lvl + 1 );
		$t =~ s/method/sub/;
		$self->ret("## $comment\n$t");
	}
}

{

	package VAST::rxinfix;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::rxinfix__S_Tilde;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::rxinfix__S_Vert;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::rxinfix__S_VertVert;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::scoped;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::scope_declarator;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::scope_declarator__S_constant;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->add_variable( $t[1], 'constant' );
		$self->ret(@t);
	}
}

{

	package VAST::scope_declarator__S_has;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::scope_declarator__S_my;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->add_variable( $t[1], 'my' );
		$self->ret(@t);
	}
}

{

	package VAST::scope_declarator__S_our;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->add_variable( $t[1], 'our' );
		$self->ret(@t);
	}
}

{

	package VAST::semiarglist;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::semilist;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::sibble;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::sigil;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::sigil__S_Amp;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::sigil__S_At;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::sigil__S_Dollar;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::sigil__S_Percent;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::sign;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::signature;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::spacey;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::special_variable;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::special_variable__S_Dollar_a2_;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$t[0] = '$C';
		$self->ret(@t);
	}
}

{

	package VAST::special_variable__S_DollarSlash;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$t[0] = '$M';
		$self->ret(@t);
	}
}

{

	package VAST::statement;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_control;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_control__S_default;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_control__S_for;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_control__S_given;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_control__S_if;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_control__S_loop;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		my $t    = join( '', @t );
		$t =~ s/^loop(\s+\()/for$1/;
		$t =~ s/^loop/for (;;)/;
		$self->ret($t);
	}
}

{

	package VAST::statement_control__S_when;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_control__S_while;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statementlist;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_mod_cond;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_mod_cond__S_if;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_mod_cond__S_unless;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_mod_loop;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_mod_loop__S_for;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_mod_loop__S_while;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_prefix;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_prefix__S_do;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_prefix__S_try;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::stdstopper;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::stopper;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::sublongname;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::subshortname;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Symbolic_unary;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::term__S_identifier;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		if ( $t[0] eq 'item' ) {
			$t[0] = '\\';
			$t[1] =~ s/^\s+//;
		}
		$self->ret(@t);
	}
}

{

	package VAST::terminator;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret('');
	}
}

{ package VAST::terminator__S_BangBang; our @ISA = 'VAST::terminator'; }

{ package VAST::terminator__S_for; our @ISA = 'VAST::terminator'; }

{ package VAST::terminator__S_if; our @ISA = 'VAST::terminator'; }

{ package VAST::terminator__S_Ket; our @ISA = 'VAST::terminator'; }

{ package VAST::terminator__S_Ly; our @ISA = 'VAST::terminator'; }

{ package VAST::terminator__S_Semi; our @ISA = 'VAST::terminator'; }

{ package VAST::terminator__S_Thesis; our @ISA = 'VAST::terminator'; }

{ package VAST::terminator__S_unless; our @ISA = 'VAST::terminator'; }

{ package VAST::terminator__S_while; our @ISA = 'VAST::terminator'; }

{ package VAST::terminator__S_when; our @ISA = 'VAST::terminator'; }

{

	package VAST::termish;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::term;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::term__S_name;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::term__S_self;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$t[0] = '$self';
		$self->ret(@t);
	}
}

{

	package VAST::term__S_Star;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::term__S_undef;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Tight_or;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::trait;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::trait_auxiliary;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::trait_auxiliary__S_does;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::trait_auxiliary__S_is;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::twigil;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::twigil__S_Dot;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$t[0] = 'self->';    # XXX
		$self->ret(@t);
	}
}

{

	package VAST::twigil__S_Star;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$t[0] = '::';
		$self->ret(@t);
	}
}

{

	package VAST::type_constraint;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::typename;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret('');
	}
}

{

	package VAST::unitstopper;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::unspacey;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::unv;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::val;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::value;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::value__S_number;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::value__S_quote;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::variable;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::variable_declarator;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::vws;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::ws;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::xblock;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$t[0] = '(' . $t[0] . ')';
		$t[0] =~ s/(\s+)\)$/)$1/;
		$self->ret(@t);
	}
}

{

	package VAST::XXX;
	our @ISA = 'VAST::Base';

	sub emit_color {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_color( $lvl + 1 );
		$self->ret(@t);
	}
}

if ( $0 eq __FILE__ ) {
	::MAIN(@ARGV);
}
