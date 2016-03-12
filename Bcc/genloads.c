/* genloads.c - generate loads of registers and memory for bcc */

/* Copyright (C) 1992 Bruce Evans */

#include "bcc.h"
#include "byteord.h"
#include "condcode.h"
#include "gencode.h"
#include "reg.h"
#include "sc.h"
#include "scan.h"
#include "sizes.h"
#include "type.h"

FORWARD void badaddress P((void));
FORWARD void blockpush P((struct symstruct *source));
FORWARD void loadadr P((struct symstruct *source, store_pt targreg));
FORWARD void loadlongindirect P((struct symstruct *source, store_pt targreg));
FORWARD void outnamoffset P((struct symstruct *adr));
FORWARD void outnnadr P((struct symstruct *adr));
FORWARD fastin_pt pushpull P((store_pt reglist, bool_pt pushflag));

PUBLIC void addoffset(source)
struct symstruct *source;
{
    if (source->offset.offi != 0)
    {
	addconst(source->offset.offi, source->storage);
	source->offset.offi = 0;
    }
}

PUBLIC void address(source)
struct symstruct *source;
{
    if (source->indcount == 0)
	bugerror("taking address of non-lvalue");
    else
    {
	if (source->type->constructor & (ARRAY | FUNCTION))
	    bugerror("botched indirect array or function");
	else if (--source->indcount == 0 && source->storage == GLOBAL &&
		 !(source->flags & LABELLED) && *source->name.namep == 0)
	    source->storage = CONSTANT;
	source->type = pointype(source->type);
    }
}

PRIVATE void badaddress()
{
    bugerror("bad address");
}

PRIVATE void blockpush(source)
struct symstruct *source;
{
    struct symstruct *length;
    offset_T spmark;
    uoffset_T typesize;

    typesize = source->type->typesize;
    length = constsym((value_t) typesize);
    length->type = uitype;
    address(source);
    modstk(spmark = sp - (offset_T) typesize);
#ifdef STACKREG
    regtransfer(STACKREG, DREG);
#else
    regtransfer(LOCAL, DREG);
#endif
    push(length);
    push(source);
    pushreg(DREG);
    call("_memcpy");
    outnl();
    modstk(spmark);
    indirec(source);
}

PUBLIC void exchange(source, target)
struct symstruct *source;
struct symstruct *target;
{
    store_t tempreg;

    regexchange(source->storage, target->storage);
    tempreg = target->storage;
    target->storage = source->storage;
    source->storage = tempreg;
}

/*-----------------------------------------------------------------------------
	getindexreg()
	returns the "best" available index register
-----------------------------------------------------------------------------*/

PUBLIC store_pt getindexreg()
{
    if (!(reguse & INDREG0))
	return INDREG0;
    if (!(reguse & INDREG1))
	return INDREG1;
    if (!(reguse & INDREG2))
	return INDREG2;
#if NOTFINISHED
#endif
    bugerror("out of index regs");
    return 0;
}

/*-----------------------------------------------------------------------------
	indexadr(index leaf, pointer leaf)
	is used by the index and add and subtract (pointer) routines
	it handles expressions like
		pointer + index
		&array[index]
	the target becomes register direct with offset
	(except for index = 0, when nothing is changed)
	constant indexes are optimised by leaving them as offsets
	register direct pointers are optimised by leaving the offset alone
	(except for PC register direct, since there is no LEAX D,PC)
-----------------------------------------------------------------------------*/

PUBLIC void indexadr(source, target)
struct symstruct *source;
struct symstruct *target;
{
    bool_t canABX;
    uoffset_T size;
    store_pt sourcereg;
    struct typestruct *targtype;
    store_pt targreg;

    if (!(target->type->constructor & (ARRAY | POINTER)))
    {
	bugerror("cannot index");
	return;
    }
    size = target->type->nexttype->typesize;
    if (source->storage == CONSTANT)
    {
	if (source->offset.offv != 0)
	{
	    if (target->indcount != 0)
		loadany(target);
	    target->offset.offi += source->offset.offv * size;
	}
	return;
    }
    if (target->storage & ALLDATREGS)
	push(target);
    if ((store_t) (sourcereg = target->storage) & ~reguse & allindregs)
	targreg = sourcereg;
    else
	targreg = getindexreg();
    if ((store_t) sourcereg == GLOBAL && target->indcount == 0 &&
	!(source->type->scalar & CHAR) && source->storage != DREG)
	load(source, targreg);
    else
	load(source, DREG);

    softop(MULOP, constsym((value_t) size), source);

/*-----------------------------------------------------------------------------
	do some calculations in advance to decide if index can be done with ABX
-----------------------------------------------------------------------------*/

    if ((store_t) targreg == XREG && source->type->scalar & CHAR &&
	size < CANABXCUTOFF)
	canABX = TRUE;
    else
    {
	canABX = FALSE;
	softop(MULOP, constsym((value_t) size), source);
    }


/*-----------------------------------------------------------------------------
	deal with constant target - constant becomes offset, result in DREG
-----------------------------------------------------------------------------*/

    if (target->storage == CONSTANT)
    {
	target->storage = DREG;
	return;
    }

/*-----------------------------------------------------------------------------
	load target if it is indirect or GLOBAL or canABX so D or B can be added
	otherwise, it is register direct (maybe S register, maybe with offset)
	and the offset can be left after adding DREG
-----------------------------------------------------------------------------*/

    if (canABX || (store_t) sourcereg == GLOBAL)
    {
	load(target, targreg);
	sourcereg = targreg;
    }
    else if (target->indcount != 0)
    {
	targtype = target->type;
	target->type = itype;
	add(source, target);
	target->type = targtype;
	return;
    }
    if (canABX)
	while (size--)
	    outABX();
    else
    {
	outlea();
	outregname(targreg);
	outtab();
	outregname(DREG);
	outncregname(sourcereg);
    }
    if ((store_t) sourcereg == LOCAL)
#ifdef FRAMEPOINTER
	target->offset.offi -= framep;
#else
	target->offset.offi -= sp;
#endif
    target->storage = targreg;
}

PUBLIC void indirec(source)
struct symstruct *source;
{
    if (!(source->type->constructor & (ARRAY | POINTER)))
	bugerror("illegal indirection");
    else if (source->indcount == (indn_t) - 1)
	limiterror("too many indirections (256)");
    else
    {
	if (source->storage & ALLDATREGS)
	    transfer(source, getindexreg());
	if (!((source->type = source->type->nexttype)->constructor &
	      (ARRAY | FUNCTION)))
	    ++source->indcount;
	if (source->storage == CONSTANT)
	    source->storage = GLOBAL;
    }
}

/*-----------------------------------------------------------------------------
	load(source leaf, target register)
	loads the specified register without changing any others (except CC)
	if the type is long or float, DREG is paired with the target register
	the result has no offset
-----------------------------------------------------------------------------*/

PUBLIC void load(source, targreg)
struct symstruct *source;
store_pt targreg;
{
    if (source->type->scalar & DLONG)
    {
	if (source->storage == CONSTANT)
	    loadreg(source, targreg);
	else if (source->indcount == 0)
	{
#if DYNAMIC_LONG_ORDER
	    if (!long_big_endian)
#endif
#if DYNAMIC_LONG_ORDER || LONG_BIG_ENDIAN == 0
	    {
		if ((store_t) targreg == DREG)
		    source->storage = DREG;
	    }
#endif
	    if (source->storage != (store_t) targreg)
		transfer(source, targreg);
	    if (source->offset.offi != 0)
		bugerror("loading direct long with offset not implemented");
	}
	else
	    loadlongindirect(source, targreg);
    }
    else if (source->type->scalar & DOUBLE)
    {
	if (source->storage == targreg && source->indcount == 0)
	    return;
	if (source->storage == CONSTANT)
	{
	    {
	       int regs, i, off=1;
	       loadconst(((unsigned short *) source->offset.offd)[0], DREG);
	       regs = (targreg&~DREG);
	       for(i=1; i; i<<=1)
	       {
		  if( regs&i )
	              loadconst(
		         ((unsigned short *) source->offset.offd)[off++],
		         i);
	       }
	    }
	}
	else
	{
	    push(source);
	    poplist(targreg | DREG);	/* actually it's the full reg list */
	}
	source->storage = targreg;	/* XXX - multi for non-386 */
	source->indcount = 0;
	source->flags = 0;
	if (source->level == OFFKLUDGELEVEL)
	    source->level = EXPRLEVEL;
	source->offset.offi = 0;
    }
    else if (source->type->scalar & FLOAT && source->storage == CONSTANT)
    {
	float val;

	val = *source->offset.offd;
	{
	   loadconst(((unsigned short *) &val)[0], DREG);
	   loadconst(((unsigned short *) &val)[1], targreg&~DREG);
	}
    }
    else if (source->type->scalar & FLOAT)
    {
	/* Treat a float just like a long ... */
	if (source->indcount == 0)
	{
	    if (source->storage != (store_t) targreg)
		transfer(source, targreg);
	    if (source->offset.offi != 0)
		bugerror("loading direct float with offset not implemented");
	}
	else
	    loadlongindirect(source, targreg);
    }
    else if (source->indcount == 0 && source->storage != CONSTANT)
	loadadr(source, targreg);
    else if (source->type->scalar ||
	     source->type->constructor & (ARRAY | POINTER))
	loadreg(source, targreg);
    else
	bugerror("attempting to load non-scalar non-pointer");
}

PRIVATE void loadadr(source, targreg)
struct symstruct *source;
store_pt targreg;
{
    if ((store_t) targreg & ALLDATREGS)
    {
	if (source->storage == GLOBAL)
	{
	  pushreg(INDREG0);
	  loadreg(source, INDREG0);
	  transfer(source, DREG);
	  recovlist(INDREG0);
	}
	if (source->storage == LOCAL)
#ifdef FRAMEPOINTER
	    source->offset.offi -= framep;
#else
	    source->offset.offi -= sp;
#endif
	if (source->type->scalar & CHAR)
	    targreg = BREG;
	if (source->storage != (store_t) targreg)
	    transfer(source, targreg);
	addoffset(source);
    }
    else if (source->storage & ALLDATREGS)
    {
	addoffset(source);
	transfer(source, targreg);
    }
    else if (source->storage != (store_t) targreg ||
	     source->offset.offi != 0 || source->level == OFFKLUDGELEVEL)
	loadreg(source, targreg);
}

PUBLIC void loadany(source)
struct symstruct *source;
{
    if (source->indcount != 0 || source->offset.offi != 0 || /* kludge u cmp */
	source->level == OFFKLUDGELEVEL || !(source->storage & allregs))
    {
	if (source->type->scalar & RSCALAR)
	    load(source, doubleregs & ~DREG);
	else if ((source->storage == CONSTANT &&
		  !(source->type->scalar & DLONG))
		 || source->type->scalar & CHAR)
	    load(source, DREG);
	else if (source->storage & ~reguse & allregs)
	    load(source, source->storage);
	else if (((reguse & allindregs) == allindregs ||
		  ((!(source->type->constructor & (ARRAY | POINTER)) &&
		  source->indcount != 0) &&
		 !(source->type->scalar & DLONG))))
	    load(source, DREG);
	else
	    load(source, getindexreg());
    }
}

PRIVATE void loadlongindirect(source, targreg)
struct symstruct *source;
store_pt targreg;
{
    sc_t flags;
    offset_T offset;
    store_t reg;
    struct typestruct *type;

    if (source->level == OFFKLUDGELEVEL)
	addoffset(source);	/* else kludge is lost and offsets big */
    flags = source->flags;
    offset = source->offset.offi;
    reg = source->storage;
    type = source->type;
    source->type = itype;
    loadreg(source, DREG);
    source->flags = flags;
    source->storage = reg;
    source->indcount = 1;
    source->offset.offi = offset + accregsize;
    loadreg(source, targreg);
    source->type = type;
}

PUBLIC void loadreg(source, targreg)
struct symstruct *source;
store_pt targreg;
{
    offset_T longhigh;
    offset_T longlow;

    if (source->storage == CONSTANT)
    {
	if (source->type->scalar & CHAR && (store_t) targreg & ALLDATREGS)
	    targreg = BREG;
	longlow = (offset_T) source->offset.offv;
	if (source->type->scalar & DLONG)
	{
	    longlow &= (offset_T) intmaskto;
	    longhigh = (offset_T) (source->offset.offv >> INT16BITSTO)
		       & (offset_T) intmaskto;
	    if ((store_t) targreg != LONGREG2)	/* loading the whole long */
	    {
#if DYNAMIC_LONG_ORDER
		if (long_big_endian)
#endif
#if DYNAMIC_LONG_ORDER || LONG_BIG_ENDIAN
		    loadconst(longhigh, DREG);
#endif
#if DYNAMIC_LONG_ORDER
		else
#endif
#if DYNAMIC_LONG_ORDER || LONG_BIG_ENDIAN == 0
		{
		    loadconst(longlow, DREG);
		    longlow = longhigh;
		}
#endif
	    }
	}
	loadconst(longlow, targreg);
	source->storage = targreg;
	source->offset.offi = 0;
    }
    else
    {
      if (source->indcount == 0)
	outlea();
      else
	{
	  outload();
	  if ((store_t) targreg == YREG)
	    bumplc();
	}
      movereg(source, targreg);
    }
}

PUBLIC void makelessindirect(source)
struct symstruct *source;
{
    store_pt lreg;

    if (!((store_t) (lreg = source->storage) & ~reguse & allindregs))
	lreg = getindexreg();
    while (source->indcount > MAXINDIRECT)
	loadreg(source, lreg);
#if MAXINDIRECT > 1
    if (source->indcount == MAXINDIRECT &&
	(source->type->typesize > maxregsize ||
	 source->type->constructor & FUNCTION))
    {
	source->indcount = 1;
	loadreg(source, lreg);
	source->indcount = 1;
    }
#endif
}

PUBLIC void movereg(source, targreg)
struct symstruct *source;
store_pt targreg;
{
    if ((store_t) targreg & ALLDATREGS && source->type->scalar & CHAR)
	targreg = BREG;
	outregname(targreg);
    if (source->storage == CONSTANT)
	adjlc((offset_T) source->offset.offv, targreg);
    outadr(source);
    source->storage = targreg;	/* in register for further use */
    source->flags = 0;
    if (source->level == OFFKLUDGELEVEL)
	source->level = EXPRLEVEL;
    source->offset.offi = 0;	/* indcount was adjusted by outadr */
}

PUBLIC void onstack(target)
register struct symstruct *target;
{
    target->storage = LOCAL;
    target->flags = TEMP;
    if (target->level == OFFKLUDGELEVEL)
	target->level = EXPRLEVEL;
    target->indcount = 1;
    target->offset.offi = sp;
}

PUBLIC void outadr(adr)
struct symstruct *adr;
{
    outnnadr(adr);
    outnl();
}

PUBLIC void outcregname(reg)
store_pt reg;
{
    outcomma();
    outregname(reg);
}

PRIVATE void outnamoffset(adr)
struct symstruct *adr;
{
    if (adr->flags & LABELLED)
	outlabel(adr->name.label);
    else
	outccname(adr->name.namep);
    if (adr->offset.offi != 0)
    {
	if (adr->offset.offi > 0)
	    outplus();
	outshex(adr->offset.offi);
    }
    bumplc2();
}

/* print comma, then register name, then newline */

PUBLIC void outncregname(reg)
store_pt reg;
{
    outcomma();
    outnregname(reg);
}

PRIVATE void outnnadr(adr)
struct symstruct *adr;
{
    bool_t indflag;

    indflag = FALSE;
    outtab();
    if (adr->indcount >= MAXINDIRECT && (adr->indcount & 1) == 0)
    {
	indflag = TRUE;		/* indirection means double indirect */
	outindleft();
    }
    switch (adr->storage)
    {
    case CONSTANT:
	outimmadr((offset_T) adr->offset.offv);
	break;
    case INDREG0:
    case INDREG1:
    case INDREG2:
	if (adr->level == OFFKLUDGELEVEL)
	{
                outimmed();
	    outnamoffset(adr);
        }
	else if (adr->offset.offi != 0)
	    outoffset(adr->offset.offi);
	if (indflag && adr->offset.offi != 0 && is5bitoffset(adr->offset.offi))
	    bumplc();
	outcregname(adr->storage);
	break;
    case LOCAL:
	if (adr->flags == TEMP && adr->offset.offi == sp &&
	    adr->indcount == 1)
	{
	    outcregname(LOCAL);
	    outplus();
	    ++sp;
	    if (adr->type->typesize != 1)
	    {
		outplus();
		++sp;
	    }
	    break;
	}
	outoffset(adr->offset.offi - sp);
	if (indflag && adr->offset.offi != sp &&
	    is5bitoffset(adr->offset.offi - sp))
	    bumplc();
	outcregname(LOCAL);
	break;
    case GLOBAL:
	if (adr->flags & LABELLED)
	    outlabel(adr->name.label);
	else if (*adr->name.namep == 0)	/* constant address */
	{
	    outhex((uoffset_T) adr->offset.offi);
	    break;
	}
	else
	    outccname(adr->name.namep);
	if (adr->offset.offi != 0)
	{
	    if (adr->offset.offi > 0)
		outplus();
	    outshex(adr->offset.offi);
	}

	outcregname(GLOBAL);
	bumplc2();

	break;
    default:
	outnl();
	badaddress();
	break;
    }
    if (indflag)
    {
	outindright();
	adr->indcount -= MAXINDIRECT;
    }
    else if (adr->indcount != 0)
	--adr->indcount;
}

/* print register name, then newline */

PUBLIC void outnregname(reg)
store_pt reg;
{
    outregname(reg);
    outnl();
}

/* print register name */

PUBLIC void outregname(reg)
store_pt reg;
{
    switch ((store_t) reg)
    {
    case BREG:
	outstr(acclostr);
	break;
    case DREG:
	outstr(accumstr);
	break;
    case GLOBAL:
	outstr("PC");
	break;
    case INDREG0:
	outstr(ireg0str);
	regfuse |= INDREG0;
	break;
    case INDREG1:
	outstr(ireg1str);
	regfuse |= INDREG1;
	break;
    case INDREG2:
	outstr(ireg2str);
	regfuse |= INDREG2;
	break;
    case LOCAL:
	outstr(localregstr);
	break;
#ifdef STACKREG
    case STACKREG:
	outstr(stackregstr);
	break;
#endif
#ifdef DATREG1
    case DATREG1:
	outstr(dreg1str);
	break;
#endif
#ifdef DATREG1B
    case DATREG1B:
	outstr(dreg1bstr);
	break;
#endif
#ifdef DATREG2
    case DATREG2:
	outstr(dreg2str);
	break;
#endif
    default:
	{ int i;
	   if (reg)
	      for(i=1; i; i<<=1)
	      {
	         if( reg&i )
		 {
		    outregname(i);
		    outstr(" ");
		 }
	      }
	   else
              outstr(badregstr);
	}
	break;
    }
}

/*-----------------------------------------------------------------------------
	pointat(target leaf)
	point OPREG at target
	target must be singly indirect or float or double
-----------------------------------------------------------------------------*/

PUBLIC void pointat(target)
struct symstruct *target;
{
    if (target->type->scalar & RSCALAR)
	(void) f_indirect(target);
    address(target);
    load(target, OPREG);
    target->type = target->type->nexttype;
}

PUBLIC void poplist(reglist)
store_pt reglist;
{
    if (reglist)
	sp += pushpull(reglist, FALSE);
}

PUBLIC void push(source)
struct symstruct *source;
{
    store_t reg;
    scalar_t sscalar;

    if (source->type->constructor & STRUCTU)
    {
	if (source->flags != TEMP)	/* TEMP must be from last function */
	    blockpush(source);
    }
    else if ((sscalar = source->type->scalar) & RSCALAR)
    {
	if (!f_indirect(source))
	{
	    saveopreg();
	    fpush(source);
	    restoreopreg();
	}
    }
    else
    {
	reg = source->storage;
	loadany(source);
	if (sscalar & DLONG)
	    pushlist(DREG | source->storage);
	else if (sscalar & CHAR)
	    pushchar();
	else
	    pushreg(source->storage);
	if (source->flags != REGVAR)
	    reguse &= ~(reg | source->storage);
    }
    onstack(source);
}

PUBLIC void pushlist(reglist)
store_pt reglist;
{
    if ((store_t) reglist)
	sp -= pushpull(reglist, TRUE);
}

PRIVATE fastin_pt pushpull(reglist, pushflag)
store_pt reglist;
bool_pt pushflag;
{
    store_pt lastregbit;
    void (*ppfunc) P((void));
    char *regptr;

    int separator;		/* promoted char for output */

    fastin_t bytespushed;
    store_pt regbit;

    if ((bool_t) pushflag)
    {
	ppfunc = outpshs;
	regbit = 1 << 7;
	regptr = regpushlist;
	lastregbit = 1;
    }
    else
    {
	ppfunc = outpuls;
	regbit = 1;
	regptr = regpulllist;
	lastregbit = 1 << 7;
    }
    regbit = 1;
    regptr = regpulllist;
    lastregbit = 1 << 7;
    separator = OPSEPARATOR;
    (*ppfunc) ();
    bytespushed = 0;
    while (TRUE)
    {
	if (regbit & reglist)
	{
	    outbyte(separator);
	    do
		outbyte(*regptr++);
	    while (*regptr >= MINREGCHAR);
	    bytespushed += *regptr++ - '0';
	    separator = OPERANDSEPARATOR;
	}
	else
	    do
		;
	    while (*regptr++ >= MINREGCHAR);
	if (regbit == lastregbit)
	    break;
	regbit <<= 1;
    }
    outnl();
    return bytespushed;
}

PUBLIC void pushreg(reg)
store_pt reg;
{
    outpshs();
    outtab();
    outnregname(reg);
    sp -= pshregsize;
}

PUBLIC void storereg(sourcereg, target)
store_pt sourcereg;
struct symstruct *target;
{
    store_pt targreg;

    if (target->indcount == 0)
    {
	if (target->offset.offi != 0 || target->level == OFFKLUDGELEVEL ||
	    !(target->storage & allregs) || target->storage & CHARREGS)
	    bugerror("bad register store");
	else if ((store_t) (targreg = target->storage) != (store_t) sourcereg)
	{
	    target->storage = sourcereg;
	    loadadr(target, targreg);	/* do LEA or TFR */
	}
    }
    else
    {
	outstore();
	if ((store_t) sourcereg == YREG)
	    bumplc();
	outregname(sourcereg);
	outadr(target);
    }
}

/*-----------------------------------------------------------------------------
	struc(element leaf, structure leaf)
	evaluates the expression
		structure.element
-----------------------------------------------------------------------------*/

PUBLIC void struc(source, target)
struct symstruct *source;
struct symstruct *target;
{
    address(target);
    if (source->offset.offi != 0 || source->level == OFFKLUDGELEVEL)
    {
	if (target->indcount != 0 || target->level == OFFKLUDGELEVEL)
	    load(target, getindexreg());
	target->offset.offi += source->offset.offi;
    }
    if (source->indcount == 0)
	target->type = source->type;
    else
    {
	target->type = pointype(source->type);	/* lost by = */
	indirec(target);
    }
}

PUBLIC void transfer(source, targreg)
struct symstruct *source;
store_pt targreg;
{
    regtransfer(source->storage, targreg);
    source->storage = targreg;
}
