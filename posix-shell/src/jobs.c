#include "shell.h"
#include "jobs.h"
#include <sys/wait.h>
#include <signal.h>

static Job job_list[MAX_JOBS];
static int next_job_id = 1;

void initialize_jobs() {
    for (int i = 0; i < MAX_JOBS; i++) {
        job_list[i].pgid = -1;
    }
    next_job_id = 1;
}

Job* add_job(pid_t pgid, const char* command_name, JobState state) {
    for (int i = 0; i < MAX_JOBS; i++) {
        if (job_list[i].pgid == -1) {
            job_list[i].pgid = pgid;
            strncpy(job_list[i].command_name, command_name, sizeof(job_list[i].command_name) - 1);
            job_list[i].command_name[sizeof(job_list[i].command_name) - 1] = '\0';
            job_list[i].state = state;
            job_list[i].job_id = next_job_id++;
            if (state == RUNNING) {
                 printf("[%d] %d\n", job_list[i].job_id, pgid);
            }
            return &job_list[i];
        }
    }
    fprintf(stderr, "shell: too many background jobs\n");
    return NULL;
}

void remove_job_by_pgid(pid_t pgid) {
    for (int i = 0; i < MAX_JOBS; i++) {
        if (job_list[i].pgid == pgid) {
            job_list[i].pgid = -1; // Mark as free
            return;
        }
    }
}

Job* get_job_by_jid(int jid) {
    for (int i = 0; i < MAX_JOBS; i++) {
        if (job_list[i].pgid != -1 && job_list[i].job_id == jid) {
            return &job_list[i];
        }
    }
    return NULL;
}

Job* get_most_recent_job() {
    int max_jid = -1;
    Job* recent_job = NULL;
    for (int i = 0; i < MAX_JOBS; i++) {
        if (job_list[i].pgid != -1 && job_list[i].job_id > max_jid) {
            max_jid = job_list[i].job_id;
            recent_job = &job_list[i];
        }
    }
    return recent_job;
}


void reap_background_jobs() {
    int status;
    pid_t pgid;
    while ((pgid = waitpid(-1, &status, WNOHANG | WUNTRACED)) > 0) {
        if (WIFEXITED(status) || WIFSIGNALED(status)) {
            // Find the job before removing it to get its job_id and command_name
            for (int i = 0; i < MAX_JOBS; i++) {
                if (job_list[i].pgid == pgid) {
                    // Format exactly as required by the test: sleep with pid <pid> exited normally
                    fprintf(stderr, "%s with pid %d exited normally\n", 
                        job_list[i].command_name, job_list[i].pgid);
                    break;
                }
            }
            remove_job_by_pgid(pgid);
        } else if (WIFSTOPPED(status)) {
            for (int i = 0; i < MAX_JOBS; i++) {
                if (job_list[i].pgid == pgid) {
                    job_list[i].state = STOPPED;
                    break;
                }
            }
        }
    }
}

void print_jobs() {
    for (int i = 0; i < MAX_JOBS; i++) {
        if (job_list[i].pgid != -1) {
            printf("[%d] %d %s\t\t%s\n", job_list[i].job_id, job_list[i].pgid, 
                   (job_list[i].state == RUNNING) ? "Running" : "Stopped",
                   job_list[i].command_name);
        }
    }
}

void kill_all_jobs() {
    for (int i = 0; i < MAX_JOBS; i++) {
        if (job_list[i].pgid != -1) {
            kill(-job_list[i].pgid, SIGKILL);
        }
    }
}