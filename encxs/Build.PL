#! /usr/bin/perl
use utf8;
use strict;
use warnings;
use Module::Build;
my $class = Module::Build -> subclass (code => <<'EOF');

sub find_ucm_files {shift->_find_file_by_type('ucm', 'ucm')}

sub process_ucm_files {
	my $self = shift;
	my $ref_ucm_files = $self->find_ucm_files;
	my @ucm_files = sort keys %$ref_ucm_files;
	my %spec;
	$spec{name} = $self->{properties}{module_name};
	$spec{module_name} = "Encode::$spec{name}";
	$spec{name_xs} = "$spec{name}.xs";
	$spec{name_table} = "$spec{name}_t";
	$spec{archdir} = File::Spec->catdir($self->blib, 'arch', 'auto', 'Encode', $spec{name});
	$spec{bs_file} = File::Spec->catfile($spec{archdir}, "$spec{name}.bs");
	$spec{lib_file} = File::Spec->catfile($spec{archdir}, "$spec{name}.".$self->{config}->get('dlext'));
	$spec{c_file} = "$spec{name}.c";
	$spec{c_file_table} = "$spec{name_table}.c";
	$spec{obj_file} = "$spec{name}".$self->{config}->get('obj_ext');
	$spec{obj_file_table} = "$spec{name_table}".$self->{config}->get('obj_ext');
	$spec{h_file_table} = "$spec{name_table}.h";
	$spec{exh_file_table} = "$spec{name_table}.exh";
# Create .xs file
	$self->add_to_cleanup($spec{name_xs});
	open(XS, '>', $spec{name_xs});
	print XS <<"END";
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#define U8 U8
#include "encode.h"
#include "$spec{h_file_table}"

static void
Encode_XSEncoding(pTHX_ encode_t *enc)
{
 dSP;
 HV *stash = gv_stashpv("Encode::XS", TRUE);
 SV *sv    = sv_bless(newRV_noinc(newSViv(PTR2IV(enc))),stash);
 int i = 0;
 PUSHMARK(sp);
 XPUSHs(sv);
 while (enc->name[i])
  {
   const char *name = enc->name[i++];
   XPUSHs(sv_2mortal(newSVpvn(name,strlen(name))));
  }
 PUTBACK;
 call_pv("Encode::define_encoding",G_DISCARD);
 SvREFCNT_dec(sv);
}

MODULE = Encode::$spec{name} PACKAGE = Encode::$spec{name}
PROTOTYPES: DISABLE
BOOT:
{
#include "$spec{exh_file_table}"
}
END
	close(XS);
# Find enc2xs and encode.h
	my ($enc2xs, $encode_h) = ();
	$path_separator = $self->config('path_sep');
	for my $d ($self->{config}->get('installbin'), $self->{config}->get('installsitebin'), $self->{config}->get('installvendorbin'), (split /$path_separator/o, $ENV{PATH})) {
		my $path = File::Spec->catfile($d, 'enc2xs');
		-r $path and $enc2xs = $path and last;
	}
	$enc2xs or die "enc2xs not found!";
	print "enc2xs is $enc2xs\n";
	my %encode_h = ();
	for my $d (@INC) {
		my $dir  = File::Spec->catfile($d,   "Encode");
		my $file = File::Spec->catfile($dir, "encode.h");
		-f $file and $encode_h{$dir} = -M $file;
	}
	%encode_h or die "encode.h not found!";
	# find the latest one
	($encode_h) = sort { $encode_h{$b} <=> $encode_h{$a} } keys %encode_h;
	push(@{$self->{properties}{include_dirs}}, $encode_h);
	print STDOUT "encode.h is at $encode_h\n";

# Compile UCM
#;	print "Compile `ucm' files\n";
	`perl $enc2xs -Q -o $spec{c_file_table} @ucm_files`;
	$self -> add_to_cleanup($spec{c_file_table});
	$self -> add_to_cleanup($spec{h_file_table});
	$self -> add_to_cleanup($spec{exh_file_table});

# XS -> O process_xs_files process_xs
#;	print "Compile `xs' to `c'\n";
	# .xs -> .c
	$self->add_to_cleanup($spec{c_file});
	$self->compile_xs($spec{name_xs}, outfile => $spec{c_file});

# .xs -> .bs
	$self->add_to_cleanup($spec{bs_file});
	require ExtUtils::Mkbootstrap;
	$self->log_info("ExtUtils::Mkbootstrap::Mkbootstrap('$spec{bs_file}')\n");
	ExtUtils::Mkbootstrap::Mkbootstrap($spec{bs_file});  # Original had $BSLOADLIBS - what's that?
	{my $fh = IO::File->new(">> $spec{bs_file}")}  # create
	utime((time)x2, $spec{bs_file});  # touch

#;	print "Compile `c' form `xs' to `object'\n";
	# .c -> .o
	my $v = $self->dist_version;
	$self->compile_c($spec{c_file},
		defines => {VERSION => qq{"$v"}, XS_VERSION => qq{"$v"}});
#
	undef $v;
# C -> O
#;	print "Compile `c' from enc2xs to `object'\n";
	$v = $self->dist_version;
	$self->compile_c($spec{c_file_table},
		defines => {VERSION => qq{"$v"}, XS_VERSION => qq{"$v"}});
# Linking link_c
#;	print "Linking\n";
	# archdir
	File::Path::mkpath($spec{archdir}, 0, oct(777)) unless -d $spec{archdir};
	$self->add_to_cleanup($spec{lib_file});
	$self->cbuilder->link(
		module_name => $spec{module_name},
		objects     => [$spec{obj_file}, $spec{obj_file_table}],
		lib_file    => $spec{lib_file},
		extra_linker_flags => $self->{prorepties}{extra_linker_flags});
#;	print "DONE\n";
	return 0;
}

EOF


my $build = $class -> new (
	dist_abstract => 'Utilities and encodings for EU4 and CK2 localisation',
	dist_author => 'terqüéz <gz0@ro.ru>',
	dist_name => 'Recodenc',
	dist_version => '0.0.1',
	license => 'gpl',
	module_name => 'Recodenc',
	needs_compiler => 1,
	# Зависимости
	build_requires => {
		'ExtUtils::CBuilder' => '0'
	},
	requires => {
		perl => '5.18.0',
		Cwd => '0',
		XSLoader => '0',
		'Getopt::Long' => '0',
		Encode => '0',
		'Encode::Locale' => '0',
		'File::Copy' => '0'
		},
#	recommends => {
#		IUP => '0.305'
#		},
	test_requires => {
		'Test::More' => '0'
		},
	# Файлы
	);
$build -> add_build_element('ucm');
$build -> create_build_script;
