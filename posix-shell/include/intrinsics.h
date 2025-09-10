#ifndef INTRINSICS_H
#define INTRINSICS_H

int execute_hop(char **args);
int execute_reveal(char **args);
int execute_log(char **args);
int execute_activities(char **args);
int execute_ping(char **args);
int execute_fg(char **args);
int execute_bg(char **args);

void add_to_history(const char *command);

#endif // INTRINSICS_H