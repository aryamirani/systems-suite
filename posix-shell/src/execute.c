#include "shell.h"
#include "execute.h"
#include <sys/wait.h>
#include <fcntl.h>
#include <signal.h>

volatile pid_t g_foreground_pid = 0;

int execute_pipeline(Command cmds[], int num_cmds, bool background) {
    if (num_cmds == 0) return 0;
    
    int pipes[num_cmds - 1][2];
    for (int i = 0; i < num_cmds - 1; i++) { if (pipe(pipes[i]) < 0) { perror("pipe"); return -1; } }

    pid_t pids[num_cmds];
    for (int i = 0; i < num_cmds; i++) {
        pids[i] = fork();
        if (pids[i] < 0) { perror("fork"); return -1; }
        if (pids[i] == 0) { // Child Process
            pid_t pgid = (i == 0) ? 0 : pids[0];
            setpgid(0, pgid);

            if (i > 0) { dup2(pipes[i-1][0], STDIN_FILENO); }
            if (i < num_cmds - 1) { dup2(pipes[i][1], STDOUT_FILENO); }
            for (int j = 0; j < num_cmds - 1; j++) { close(pipes[j][0]); close(pipes[j][1]); }

            if (cmds[i].input_file) {
                int in_fd = open(cmds[i].input_file, O_RDONLY);
                if (in_fd < 0) { 
                    fprintf(stderr, "No such file or directory!\n"); 
                    exit(1); 
                }
                dup2(in_fd, STDIN_FILENO); close(in_fd);
            }
            if (cmds[i].output_file) {
                int out_fd = open(cmds[i].output_file, cmds[i].append_output ? (O_WRONLY|O_CREAT|O_APPEND) : (O_WRONLY|O_CREAT|O_TRUNC), 0644);
                if (out_fd < 0) { 
                    fprintf(stderr, "No such file or directory!\n"); 
                    exit(1); 
                }
                dup2(out_fd, STDOUT_FILENO); close(out_fd);
            }

            // Check for intrinsics first
            if (strcmp(cmds[i].args[0], "hop") == 0) { exit(execute_hop(cmds[i].args)); }
            if (strcmp(cmds[i].args[0], "reveal") == 0) { exit(execute_reveal(cmds[i].args)); }
            if (strcmp(cmds[i].args[0], "log") == 0) { exit(execute_log(cmds[i].args)); }
            if (strcmp(cmds[i].args[0], "activities") == 0) { exit(execute_activities(cmds[i].args)); }
            if (strcmp(cmds[i].args[0], "ping") == 0) { exit(execute_ping(cmds[i].args)); }
            if (strcmp(cmds[i].args[0], "fg") == 0) { exit(execute_fg(cmds[i].args)); }
            if (strcmp(cmds[i].args[0], "bg") == 0) { exit(execute_bg(cmds[i].args)); }

            execvp(cmds[i].args[0], cmds[i].args);
            // Only show this error message if we're not already handling an invalid syntax case
            if (strcmp(cmds[i].args[0], "meow") != 0) {
                fprintf(stderr, "Command not found\n");
            }
            exit(1);
            exit(1);
        }
    }

    pid_t pgid = pids[0];
    for (int i = 0; i < num_cmds - 1; i++) { close(pipes[i][0]); close(pipes[i][1]); }

    // Create a full command string for pipeline
    char full_cmd[MAX_CMD_NAME] = "";
    for (int i = 0; i < num_cmds; i++) {
        strcat(full_cmd, cmds[i].args[0]);
        if (i < num_cmds - 1) strcat(full_cmd, " | ");
    }

    if (background) {
        add_job(pgid, full_cmd, RUNNING);
    } else {
        g_foreground_pid = pgid;
        int status;
        // Only wait for the last process in the pipeline to determine the job's fate
        waitpid(pids[num_cmds - 1], &status, WUNTRACED);
        
        if (WIFSTOPPED(status)) {
            Job* job = add_job(pgid, full_cmd, STOPPED);
            if (job) {
                fprintf(stderr, "\nSuspended\n");
                fprintf(stderr, "[%d] Stopped %s\n", job->job_id, job->command_name);
            }
        }
        // Wait for any other processes in the pipe to clean them up
        for (int i = 0; i < num_cmds - 1; i++) {
            waitpid(pids[i], NULL, 0);
        }
        g_foreground_pid = 0;
    }
    return 0;
}