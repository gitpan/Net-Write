/*
 * $Id: Write.xs,v 1.1 2006/03/15 01:55:26 gomor Exp $
 *
 * AUTHOR
 *
 * Patrice <GomoR> Auffret
 *
 * COPYRIGHT AND LICENSE
 *
 * Copyright (c) 2006, Patrice <GomoR> Auffret
 *
 * You may distribute this module under the terms of the Artistic license.
 * See Copying file in the source distribution archive.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "libnetwrite.h"

static int
not_here(char *s)
{
   croak("%s not implemented on this architecture", s);
   return -1;
}

static double
constant(char *name, int len, int arg)
{
   errno = EINVAL;
   return 0;
}

MODULE = Net::Write      PACKAGE = Net::Write

PROTOTYPES: DISABLE

double
constant(sv,arg)
   PREINIT:
      STRLEN   len;
   INPUT:
      SV      *sv
      char    *s = SvPV(sv, len);
      int      arg
   CODE:
      RETVAL = constant(s,len,arg);
   OUTPUT:
      RETVAL

int
netwrite_open(arg0)
   char * arg0
