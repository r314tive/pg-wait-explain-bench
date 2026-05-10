#include "postgres.h"

#include "fmgr.h"
#include "miscadmin.h"
#include "utils/wait_event.h"

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(bench_wait_loop);

Datum
bench_wait_loop(PG_FUNCTION_ARGS)
{
	int32		nloops = PG_GETARG_INT32(0);

	if (nloops < 0)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("loop count must not be negative")));

	for (int32 i = 0; i < nloops; i++)
	{
		pgstat_report_wait_start(WAIT_EVENT_PG_SLEEP);
		pgstat_report_wait_end();

		if ((i & 0x3ffff) == 0)
			CHECK_FOR_INTERRUPTS();
	}

	PG_RETURN_INT32(nloops);
}
