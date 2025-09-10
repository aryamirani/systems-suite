#ifndef EXECUTE_H
#define EXECUTE_H

#include <stdbool.h>

#define MAX_ARGS 64
#define MAX_PIPED_CMDS 16

typedef struct {
    char *args[MAX_ARGS];
    char *input_file;
    char *output_file;
    bool append_output;
} Command;

int execute_pipeline(Command cmds[], int num_cmds, bool background);

#endif // EXECUTE_H