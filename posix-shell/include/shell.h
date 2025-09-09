#ifndef SHELL_H
#define SHELL_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>
#include <limits.h>
#include <stdbool.h>

#include "parser.h"
#include "intrinsics.h"
#include "execute.h"
#include "jobs.h"

#define HISTORY_FILE_NAME ".shell_history"

extern char SHELL_HOME[PATH_MAX];
extern char HISTORY_FILE_PATH[PATH_MAX];

void display_prompt();
void process_command_line(char *line);

#endif // SHELL_H