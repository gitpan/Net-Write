/*
 * $Id: libnetwrite.c,v 1.6 2006/10/29 13:26:53 gomor Exp $
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
 * See LICENSE.Artistic file in the source distribution archive.
 */

#if defined (__FreeBSD__) || defined (__OpenBSD__) || defined (__NetBSD__)

#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>

#include <fcntl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <net/bpf.h>
#include <sys/ioctl.h>

int
netwrite_open(char *interface)
{
   int  fd;
   int  r;
   int  i;
   char buf[1024];
   struct ifreq ifr;
   const int build_eth_hdr = 1;

   /* open first available bpf */
   for (i=0 ; i<255 ; i++) {
      char dev[sizeof "/dev/bpfxxx"];
      memset(dev, '\0', sizeof dev);
      snprintf(dev, sizeof dev - 1, "/dev/bpf%d", i);
      fd = open(dev, O_RDWR);
      if (fd == -1 && errno != EBUSY) {
         memset(buf, '\0', sizeof buf);
         snprintf(buf, sizeof buf - 1, "%s: open: %s: %s: %s\n",
            __FUNCTION__, interface, dev, strerror (errno));
         fprintf(stderr, "%s", buf);
         return(0);
      }
      else if (fd == -1 && errno == EBUSY)
         continue;
      else
         break;
   }
   if (fd == -1) {
      memset(buf, '\0', sizeof buf);
      snprintf(buf, sizeof buf - 1, "%s: %s: can't open any bpf\n",
         __FUNCTION__, interface);
      fprintf(stderr, "%s", buf);
      return(0);
   }

   memset(&ifr, '\0', sizeof ifr);
   strncpy(ifr.ifr_name, interface, sizeof ifr.ifr_name - 1);

   /* Attach network interface */
   r = ioctl(fd, BIOCSETIF, (caddr_t) &ifr);
   if (r == -1) {
      memset(buf, '\0', sizeof buf);
      snprintf(buf, sizeof buf - 1, "%s: ioctl(BIOCSETIF): %s: %s\n",
         __FUNCTION__, interface, strerror (errno));
      fprintf(stderr, "%s", buf);
      return(0);
   }

   /* Enable Ethernet headers construction */
   r = ioctl(fd, BIOCSHDRCMPLT, &build_eth_hdr);
   if (r == -1) {
      memset(buf, '\0', sizeof buf);
      snprintf(buf, sizeof buf - 1, "%s: ioctl(BIOCSHDRCMPLT): %s: %s\n",
         __FUNCTION__, interface, strerror (errno));
      fprintf(stderr, "%s", buf);
      return(0);
   }

   return(fd);
}
/* end FreeBSD, OpenBSD, NetBSD */
#elif defined(__linux__)

#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/socket.h>
#include <net/if.h>
#include <linux/if_ether.h>
#include <linux/sockios.h>

int
netwrite_open(char *interface)
{
   int  r;
   int  fd;
   char buf[1024];
   struct ifreq ifr;

   fd = socket(PF_INET, SOCK_PACKET, htons(ETH_P_ALL));
   if (fd < 0) {
      memset(buf, '\0', sizeof buf);
      snprintf(buf, sizeof buf - 1, "%s: socket: %s: %s\n",
         __FUNCTION__, interface, strerror (errno));
      fprintf(stderr, "%s", buf);
      return(0);
   }

   memset(&ifr, '\0', sizeof ifr);
   strncpy(ifr.ifr_name, interface, sizeof ifr.ifr_name - 1);
   r = ioctl(fd, SIOCGIFHWADDR, &ifr);
   if (r < 0) {
      memset(buf, '\0', sizeof buf);
      snprintf(buf, sizeof buf - 1, "%s: ioctl(SIOCGIFHWADDR): %s: %s\n",
         __FUNCTION__, interface, strerror (errno));
      fprintf(stderr, "%s", buf);
      return(0);
   }

   return(fd);
}
/* end Linux */
#elif defined(__sun__) || defined(_SOLARIS_)

// http://sunsite.bilkent.edu.tr/pub/sun-info/sun-faq/Docs/snit-to-dlpi.txt

#include <sys/types.h>
#include <sys/stropts.h>
#include <sys/dlpi.h>
#include <sys/signal.h>
#include <fcntl.h>
#include <stdio.h>

#include <sys/ethernet.h>

#define MAXDLBUF   4096
#define MAXDLADDR  4096

syserr(char *msg)
{
   fprintf(stderr, "%s\n", msg);
}

_dlphysaddrreq (fd, addrtype)
int	fd;
u_long	addrtype;
{
	dl_phys_addr_req_t  phys_addr_req;
	struct  strbuf  ctl;
	int	flags;

	phys_addr_req.dl_primitive = DL_PHYS_ADDR_REQ;
	phys_addr_req.dl_addr_type = addrtype;

	ctl.maxlen = 0;
	ctl.len = sizeof (phys_addr_req);
	ctl.buf = (char *) &phys_addr_req;

	flags = 0;
	if (putmsg (fd, &ctl, (struct strbuf*) NULL, flags) < 0)
		syserr ("dlphysaddrreq: putmsg");
}

_dlphysaddrack (fd, bufp)
int	fd;
char	*bufp;
{
	union  DL_primitives*dlp;
	struct  strbuf  ctl;
	int	flags;

	ctl.maxlen = MAXDLBUF;
	ctl.len = 0;
	ctl.buf = bufp;

	strgetmsg (fd, &ctl, (struct strbuf*) NULL,
		&flags, "dlphysaddrack");

	dlp = (union DL_primitives *) ctl.buf;

	expecting (DL_PHYS_ADDR_ACK, dlp);

	if (flags != RS_HIPRI)
		err ("dlphysaddrack: DL_OK_ACK was not M_PCPROTO");

	if (ctl.len < sizeof (dl_phys_addr_ack_t))
		err ("dlphysaddrack: short response ctl.len: %d", ctl.len);
}

_dlattachreq (fd, ppa)
int	fd;
u_long	ppa;
{
	dl_attach_req_t  attach_req;
	struct  strbuf  ctl;
	int	flags;

	attach_req.dl_primitive = DL_ATTACH_REQ;
	attach_req.dl_ppa = ppa;

	ctl.maxlen = 0;
	ctl.len = sizeof (attach_req);
	ctl.buf = (char *) &attach_req;

	flags = 0;

	if (putmsg (fd, &ctl, (struct strbuf*) NULL, flags) < 0)
		syserr ("dlattachreq: putmsg");
}

_dlbindreq (fd, sap, max_conind, service_mode, conn_mgmt, xidtest)
int	fd;
u_long	sap;
u_long	max_conind;
u_long	service_mode;
u_long	conn_mgmt;
u_long	xidtest;
{
	dl_bind_req_t  bind_req;
	struct  strbuf  ctl;
	int	flags;

	bind_req.dl_primitive = DL_BIND_REQ;
	bind_req.dl_sap = sap;
	bind_req.dl_max_conind = max_conind;
	bind_req.dl_service_mode = service_mode;
	bind_req.dl_conn_mgmt = conn_mgmt;
	bind_req.dl_xidtest_flg = xidtest;

	ctl.maxlen = 0;
	ctl.len = sizeof (bind_req);
	ctl.buf = (char *) &bind_req;

	flags = 0;

	if (putmsg (fd, &ctl, (struct strbuf*) NULL, flags) < 0)
		syserr ("dlbindreq: putmsg");
}

_dlbindack (fd, bufp)
int	fd;
char	*bufp;
{
	union  DL_primitives*dlp;
	struct  strbuf  ctl;
	int	flags;

	ctl.maxlen = MAXDLBUF;
	ctl.len = 0;
	ctl.buf = bufp;

	strgetmsg (fd, &ctl, (struct strbuf*) NULL, &flags, "dlbindack");

	dlp = (union DL_primitives *) ctl.buf;

	expecting (DL_BIND_ACK, dlp);

	if (flags != RS_HIPRI)
		err ("dlbindack: DL_OK_ACK was not M_PCPROTO");

	if (ctl.len < sizeof (dl_bind_ack_t))
		err ("dlbindack: short response ctl.len: %d", ctl.len);
}

_dlokack (fd, bufp)
int	fd;
char	*bufp;
{
	union  DL_primitives*dlp;
	struct  strbuf  ctl;
	int	flags;

	ctl.maxlen = MAXDLBUF;
	ctl.len = 0;
	ctl.buf = bufp;

	strgetmsg (fd, &ctl, (struct strbuf*) NULL, &flags, "dlokack");

	dlp = (union DL_primitives *) ctl.buf;

	expecting (DL_OK_ACK, dlp);

	if (ctl.len < sizeof (dl_ok_ack_t))
		err ("dlokack: response ctl.len too short: %d", ctl.len);

	if (flags != RS_HIPRI)
		err ("dlokack: DL_OK_ACK was not M_PCPROTO");

	if (ctl.len < sizeof (dl_ok_ack_t))
		err ("dlokack: short response ctl.len: %d", ctl.len);
}

char xmitbuf[MAXDLBUF];

int
netwrite_open(char *dev)
{
	long	buf[MAXDLBUF];			/* aligned on long */
	union	DL_primitives*dlp;
	char	*device;

int	ppa, fd, localsap, sapval, n, size, physlen, saplen, sap;
	u_char  phys[MAXDLADDR], addr[MAXDLADDR];

        struct ether_header *ehp;

	dlp = (union DL_primitives*) buf;

	device = "pcn";
	ppa = 0;
	sap = 0;

	/* Open the device. */

	if ((fd = open (device, O_RDWR)) < 0)
		syserr (device);

	/* Attach. */

	_dlattachreq (fd, ppa);
	_dlokack (fd, buf);

	/* Bind. */

	_dlbindreq (fd, sap, 0, DL_CLDLS, 0, 0);
	_dlbindack (fd, buf);



	/* Get our current physical address. */

	//dlphysaddrreq (fd, DL_CURR_PHYS_ADDR);
	//dlphysaddrack (fd, buf);

	//dlp = (union DL_primitives*) buf;

	/* Create raw Ethernet header. */

	ehp = (struct ether_header*) xmitbuf;
	memcpy (&ehp->ether_dhost, phys, ETHERADDRL);
	memcpy (&ehp->ether_shost,
		OFFADDR (dlp, dlp->physaddr_ack.dl_addr_offset), ETHERADDRL);
	ehp->ether_type = (u_short) sapval;

	/* Put file descriptor in "raw mode". */

	if (strioctl (fd, DLIOCRAW, -1, 0, 0) < 0)
		syserr ("ioctl DLIOCRAW");

	/* Transmit it as an M_DATA msg. */

	if (write (fd, xmitbuf, size) < 0)
		syserr ("write");

   return(fd);
}

/* end SunOS */
#else

#include <stdio.h>

int
netwrite_open(char *dev)
{
   fprintf(stderr, "%s: not implemented yet for this platform\n", __FUNCTION__);
   return(0);
}

#endif
