#ifndef JOBS_H
#define JOBS_H

#include <sys/types.h>
#include <stdbool.h>

#define MAX_JOBS 64
#define MAX_CMD_NAME 1024

typedef enum {
    RUNNING,
    STOPPED
} JobState;

typedef struct {
    pid_t pgid; // Use Process Group ID for job control
    char command_name[MAX_CMD_NAME];
    JobState state;
    int job_id; // The 1-based job number
} Job;

void initialize_jobs();
Job* add_job(pid_t pgid, const char* command_name, JobState state);
void reap_background_jobs();
void print_jobs();
void kill_all_jobs();
Job* get_job_by_jid(int jid);
Job* get_most_recent_job();
void remove_job_by_pgid(pid_t pgid);

#endif // JOBS_H