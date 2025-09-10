#include "parser.h"
#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>

// Returns true if string is NULL or only whitespace
bool is_empty(const char *s) {
    if (s == NULL) return true;
    while (*s != '\0') {
        if (!isspace((unsigned char)*s)) return false;
        s++;
    }
    return true;
}

// Trims leading/trailing whitespace (modifies string)
char* trim_whitespace(char *str) {
    char *end;
    while(isspace((unsigned char)*str)) str++;
    if(*str == 0) return str;
    end = str + strlen(str) - 1;
    while(end > str && isspace((unsigned char)*end)) end--;
    *(end+1) = 0;
    return str;
}

// Validates shell input for syntax errors
bool parse_input(char *input) {
    char *input_copy = strdup(input);
    if (input_copy == NULL) {
        perror("strdup");
        return false;
    }

    // Handle trailing '&' - create a separate copy for ampersand check
    char* amp_check_copy = strdup(input_copy);
    char* trimmed_input_for_amp_check = trim_whitespace(amp_check_copy);
    
    if (strlen(trimmed_input_for_amp_check) > 0 && trimmed_input_for_amp_check[strlen(trimmed_input_for_amp_check) - 1] == '&') {
        trimmed_input_for_amp_check[strlen(trimmed_input_for_amp_check) - 1] = '\0';
        if (is_empty(trimmed_input_for_amp_check)) {
            free(input_copy);
            free(amp_check_copy);
            return false;
        }
    }
    free(amp_check_copy);

    char *saveptr_cmd_group;
    char *cmd_group_str = strtok_r(input_copy, ";", &saveptr_cmd_group);

    if (cmd_group_str == NULL && !is_empty(input_copy)) {
        free(input_copy);
        return false;
    }
    
    while (cmd_group_str != NULL) {
        char* trimmed_group = trim_whitespace(cmd_group_str);

        if (is_empty(trimmed_group)) {
            char *next_check = strtok_r(NULL, ";", &saveptr_cmd_group);
            if (next_check != NULL && !is_empty(next_check)) {
                free(input_copy);
                return false;
            }
            break;
        }

        // No leading/trailing pipes allowed
        if (trimmed_group[0] == '|' || trimmed_group[strlen(trimmed_group) - 1] == '|') {
            free(input_copy);
            return false;
        }

        char *pipe_check_copy = strdup(trimmed_group);
        char *saveptr_atomic;
        char *atomic_str = strtok_r(pipe_check_copy, "|", &saveptr_atomic);
        
        while(atomic_str != NULL) {
            if (is_empty(atomic_str)) {
                free(input_copy);
                free(pipe_check_copy);
                return false;
            }
            atomic_str = strtok_r(NULL, "|", &saveptr_atomic);
        }
        free(pipe_check_copy);
        
        cmd_group_str = strtok_r(NULL, ";", &saveptr_cmd_group);
    }

    free(input_copy);
    return true;
}