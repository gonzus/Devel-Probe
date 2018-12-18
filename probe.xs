#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

static Perl_ppaddr_t nextstate_orig = 0;
static int enabled = 0;
static HV* probes = 0;

static void probe_install(pTHX);
static OP*  probe_nextstate(pTHX);

static void probe_install(pTHX)
{
    if (PL_ppaddr[OP_NEXTSTATE] == probe_nextstate) {
        croak("probe_install called twice");
    }

    nextstate_orig = PL_ppaddr[OP_NEXTSTATE];
    PL_ppaddr[OP_NEXTSTATE] = probe_nextstate;
    fprintf(stderr, "probe_install: nextstate_orig is [%p]\n", nextstate_orig);
}

static OP* probe_nextstate(pTHX)
{
    Perl_ppaddr_t orig_pp = nextstate_orig;
    OP* ret = orig_pp(aTHX);

    do {
        if (!enabled) {
            // fprintf(stderr, "NOT enabled\n");
            break;
        }

        const char* file = CopFILE(PL_curcop);
        SV** rlines = hv_fetch(probes, file, strlen(file), 0);
        if (!rlines || !*rlines) {
            // fprintf(stderr, "NOT probing file [%s]\n", file);
            break;
        }

        HV* lines = (HV*) SvRV(*rlines);
        int line = CopLINE(PL_curcop);
        char kstr[20];
        U32 klen = sprintf(kstr, "%d", line);
        SV** probe = hv_fetch(lines, kstr, klen, 0);
        if (!probe || !*probe) {
            // fprintf(stderr, "NOT probing line [%s:%d]\n", file, line);
            break;
        }

        /* do our own nefarious thing... */
        fprintf(stderr, "PROBE [%s] [%d]\n", file, line);
    } while (0);

    return ret;
}

MODULE = Devel::Probe        PACKAGE = Devel::Probe
PROTOTYPES: DISABLE

#################################################################

void
install(HV* options)
PREINIT:
    HV* lines;
    const char* kstr;
    U32 klen;
CODE:
    probe_install(aTHX);
    probes = newHV();

    lines = newHV();
    kstr = "1";
    klen = strlen(kstr);
    hv_store(lines, kstr, klen, &PL_sv_yes, 0);
    kstr = "16";
    klen = strlen(kstr);
    hv_store(lines, kstr, klen, &PL_sv_yes, 0);

    kstr = "t/001-simple.t";
    klen = strlen(kstr);
    hv_store(probes, kstr, klen, newRV((SV*) lines), 0);

    enabled = 1;
    fprintf(stderr, "GONZO: installed\n");
