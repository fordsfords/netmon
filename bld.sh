#!/bin/sh
# bld.sh - not much to build; just doc TOC

# Update doc table of contents (see https://github.com/fordsfords/mdtoc).
if which mdtoc.pl >/dev/null; then mdtoc.pl -b "" README.md;
elif [ -x ../mdtoc/mdtoc.pl ]; then ../mdtoc/mdtoc.pl -b "" README.md;
else echo "FYI: mdtoc.pl not found; see https://github.com/fordsfords/mdtoc"
fi
