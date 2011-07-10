#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "hook_op_check_smartmatch.h"

#ifndef op_append_elem
#define op_append_elem(a,b,c)	Perl_op_append_elem(aTHX_ a,b,c)
OP *
Perl_op_append_elem(pTHX_ I32 type, OP *first, OP *last)
{
    if (!first)
	return last;

    if (!last)
	return first;

    if (first->op_type != (unsigned)type
	|| (type == OP_LIST && (first->op_flags & OPf_PARENS)))
    {
	return newLISTOP(type, 0, first, last);
    }

    if (first->op_flags & OPf_KIDS)
	((LISTOP*)first)->op_last->op_sibling = last;
    else {
	first->op_flags |= OPf_KIDS;
	((LISTOP*)first)->op_first = last;
    }
    ((LISTOP*)first)->op_last = last;
    return first;
}
#endif

STATIC OP*
smartmatch_cb(pTHX_ OP *o, void *user_data)
{
    OP *left, *right, *cb_op, *list, *new;
    SV **cb;

    cb = hv_fetchs(GvHV(PL_hintgv), "smartmatch_cb", 0);
    if (!cb) {
        return o;
    }

    left = cBINOPo->op_first;
    right = left->op_sibling;

    o->op_flags &= ~OPf_KIDS;
    op_free(o);

/* array slices used to parse incorrectly (perl RT#77468),
 * fix (hack) this up */
#if PERL_VERSION < 14
    if (left->op_type == OP_ASLICE) {
        OP *sib;
        sib = left->op_sibling;
        left->op_flags &= ~OPf_WANT_SCALAR;
        left->op_flags |= OPf_WANT_LIST
                        | OPf_PARENS
                        | OPf_REF
                        | OPf_MOD
                        | OPf_STACKED
                        | OPf_SPECIAL;
        left->op_sibling = NULL;
        left = newLISTOP(OP_ANONLIST,
                         OPf_WANT_SCALAR|OPf_SPECIAL,
                         newOP(OP_PUSHMARK, 0),
                         left);
        left->op_sibling = sib;
    }
    if (right->op_type == OP_ASLICE) {
        OP *sib;
        sib = right->op_sibling;
        right->op_flags &= ~OPf_WANT_SCALAR;
        right->op_flags |= OPf_WANT_LIST
                         | OPf_PARENS
                         | OPf_REF
                         | OPf_MOD
                         | OPf_STACKED
                         | OPf_SPECIAL;
        right->op_sibling = NULL;
        right = newLISTOP(OP_ANONLIST,
                          OPf_WANT_SCALAR|OPf_SPECIAL,
                          newOP(OP_PUSHMARK, 0),
                          right);
        right->op_sibling = sib;
        left->op_sibling = right;
    }
#endif

    cb_op = newCVREF(0, newSVOP(OP_CONST, 0, newSVsv(*cb)));
    list = newLISTOP(OP_LIST, 0, left, right);
    new = newUNOP(OP_ENTERSUB, OPf_STACKED,
                  op_append_elem(OP_LIST, list, cb_op));

    return new;
}

UV
hook_op_check_smartmatch()
{
    return hook_op_check(OP_SMARTMATCH, smartmatch_cb, NULL);
}

MODULE = smartmatch  PACKAGE = smartmatch

PROTOTYPES: DISABLE

BOOT:
    hook_op_check_smartmatch();

void
register (cb)
    SV *cb;
    CODE:
        if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV) {
            croak("not a coderef");
        }

        PL_hints |= HINT_LOCALIZE_HH;
        gv_HVadd(PL_hintgv);

        SvREFCNT_inc(cb);
        if (!hv_stores(GvHV(PL_hintgv), "smartmatch_cb", cb)) {
            SvREFCNT_dec(cb);
            croak("couldn't store the callback");
        }

void
unregister ()
    CODE:
        PL_hints |= HINT_LOCALIZE_HH;
        gv_HVadd(PL_hintgv);

        hv_delete(GvHV(PL_hintgv), "smartmatch_cb", 13, G_DISCARD);
