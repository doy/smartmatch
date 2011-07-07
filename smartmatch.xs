#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "hook_op_check_smartmatch.h"

STATIC OP*
smartmatch_cb(pTHX_ OP *o, void *user_data)
{
    OP *left, *right, *cb_op, *list, *new;

    left = cBINOPo->op_first;
    right = left->op_sibling;

    o->op_flags &= ~OPf_KIDS;
    op_free(o);

    cb_op = newSVOP(OP_CONST, 0, newSVsv(user_data));
    list = newLISTOP(OP_LIST, 0, left, right);
    new = newUNOP(OP_ENTERSUB, OPf_STACKED,
                  op_append_elem(OP_LIST, list, cb_op));

    return new;
}

UV
hook_op_check_smartmatch(void *user_data)
{
    return hook_op_check(OP_SMARTMATCH, smartmatch_cb, user_data);
}

void *
hook_op_check_smartmatch_remove(UV id)
{
    return hook_op_check_remove(OP_SMARTMATCH, id);
}

MODULE = smartmatch  PACKAGE = smartmatch

PROTOTYPES: DISABLE

UV
register (cb)
    SV *cb;
    CODE:
        if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV) {
            croak("not a coderef");
        }

        RETVAL = hook_op_check_smartmatch(newSVsv(cb));
    OUTPUT:
        RETVAL

void
unregister (id)
    UV id;
    PREINIT:
    SV *cb;
    CODE:
        cb = hook_op_check_smartmatch_remove(id);
        if (cb) {
            SvREFCNT_dec(cb);
        }
