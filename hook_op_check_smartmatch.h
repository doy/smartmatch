#ifndef __HOOK_OP_CHECK_SMARTMATCH_H__
#define __HOOK_OP_CHECK_SMARTMATCH_H__

#include "perl.h"
#include "hook_op_check.h"

UV hook_op_check_smartmatch(void *user_data);
void *hook_op_check_smartmatch_remove(UV id);

#endif
