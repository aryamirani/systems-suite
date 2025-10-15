#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>
#include <string.h>
#include <time.h>

#define MAX_CAPACITY 25
#define SOFA_CAPACITY 4
#define NUM_CHEFS 4
#define NUM_OVENS 4

typedef struct {
    int id;
    int arrival_time;
    int enter_time;
    int sit_time;
    int request_time;
    int baking_start_time;
    int pay_time;
    int payment_accepted_time;
    int chef_id;
} Customer;

// Global variables
int current_time = 0;
int customers_in_shop = 0;
int customers_on_sofa = 0;
Customer *sofa_queue[SOFA_CAPACITY];
Customer **standing_customers;
int standing_count = 0;
int standing_capacity = MAX_CAPACITY - SOFA_CAPACITY;

pthread_mutex_t shop_mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t print_mutex = PTHREAD_MUTEX_INITIALIZER;

Customer **all_customers;
int customer_count = 0;
int chef_busy_until[NUM_CHEFS + 1];
int cash_register_busy_until = 0;

void print_event(int time, const char *type, int id, const char *action, int customer_id) {
    pthread_mutex_lock(&print_mutex);
    if (customer_id == -1) {
        printf("%d %s %d %s\n", time, type, id, action);
    } else {
        printf("%d %s %d %s %d\n", time, type, id, action, customer_id);
    }
    fflush(stdout);
    pthread_mutex_unlock(&print_mutex);
}

void* customer_thread(void *arg) {
    Customer *c = (Customer *)arg;
    
    // Wait until arrival time
    while (current_time < c->arrival_time) {
        usleep(100);
    }
    
    // Try to enter shop
    pthread_mutex_lock(&shop_mutex);
    if (customers_in_shop >= MAX_CAPACITY) {
        pthread_mutex_unlock(&shop_mutex);
        return NULL;
    }
    customers_in_shop++;
    c->enter_time = current_time;
    print_event(current_time, "Customer", c->id, "enters", -1);
    pthread_mutex_unlock(&shop_mutex);
    
    // Wait 1 second after entering
    while (current_time < c->enter_time + 1) {
        usleep(100);
    }
    
    // Try to sit on sofa
    pthread_mutex_lock(&shop_mutex);
    if (customers_on_sofa < SOFA_CAPACITY) {
        customers_on_sofa++;
        c->sit_time = current_time;
        print_event(current_time, "Customer", c->id, "sits", -1);
        pthread_mutex_unlock(&shop_mutex);
    } else {
        // Stand and wait
        standing_customers[standing_count++] = c;
        pthread_mutex_unlock(&shop_mutex);
        
        // Wait for sofa seat
        while (1) {
            pthread_mutex_lock(&shop_mutex);
            int found = 0;
            for (int i = 0; i < standing_count; i++) {
                if (standing_customers[i] == c) {
                    found = 1;
                    break;
                }
            }
            if (!found) {
                // Got a seat
                c->sit_time = current_time;
                print_event(current_time, "Customer", c->id, "sits", -1);
                pthread_mutex_unlock(&shop_mutex);
                break;
            }
            pthread_mutex_unlock(&shop_mutex);
            usleep(100);
        }
    }
    
    // Wait 1 second after sitting
    while (current_time < c->sit_time + 1) {
        usleep(100);
    }
    
    // Request cake
    pthread_mutex_lock(&shop_mutex);
    c->request_time = current_time;
    print_event(current_time, "Customer", c->id, "requests cake", -1);
    pthread_mutex_unlock(&shop_mutex);
    
    // Wait for chef to start baking
    while (c->baking_start_time == 0) {
        usleep(100);
    }
    
    // Wait for baking to complete (2 seconds from baking_start_time)
    while (current_time < c->baking_start_time + 2) {
        usleep(100);
    }
    
    // Pay (after baking completes)
    pthread_mutex_lock(&shop_mutex);
    c->pay_time = current_time;
    print_event(current_time, "Customer", c->id, "pays", -1);
    pthread_mutex_unlock(&shop_mutex);
    
    // Wait for payment to be accepted (chef will set payment_accepted_time)
    while (c->payment_accepted_time == 0) {
        usleep(100);
    }
    
    // Wait for payment acceptance to complete (2 seconds from payment_accepted_time)
    while (current_time < c->payment_accepted_time + 2) {
        usleep(100);
    }
    
    // Leave
    pthread_mutex_lock(&shop_mutex);
    print_event(current_time, "Customer", c->id, "leaves", -1);
    customers_in_shop--;
    customers_on_sofa--;
    
    // Let standing customer sit
    if (standing_count > 0) {
        Customer *next = standing_customers[0];
        for (int i = 1; i < standing_count; i++) {
            standing_customers[i-1] = standing_customers[i];
        }
        standing_count--;
        customers_on_sofa++;
    }
    
    pthread_mutex_unlock(&shop_mutex);
    
    return NULL;
}

void* chef_thread(void *arg) {
    int chef_id = *((int *)arg);
    
    while (1) {
        pthread_mutex_lock(&shop_mutex);
        
        // Priority 1: Accept payment (payment takes priority over baking)
        Customer *payment_customer = NULL;
        int earliest_pay_time = -1;
        
        for (int i = 0; i < customer_count; i++) {
            Customer *cust = all_customers[i];
            // Customer must have paid and payment not yet accepted
            if (cust->pay_time > 0 && cust->payment_accepted_time == 0) {
                // Check if we can start accepting payment (must be at least 1 second after customer paid)
                if (current_time >= cust->pay_time + 1 && current_time >= cash_register_busy_until) {
                    if (earliest_pay_time == -1 || cust->pay_time < earliest_pay_time) {
                        earliest_pay_time = cust->pay_time;
                        payment_customer = cust;
                    }
                }
            }
        }
        
        if (payment_customer != NULL) {
            payment_customer->payment_accepted_time = current_time;
            cash_register_busy_until = current_time + 2;
            chef_busy_until[chef_id] = current_time + 2;
            print_event(current_time, "Chef", chef_id, "accepts payment for Customer", payment_customer->id);
            pthread_mutex_unlock(&shop_mutex);
            
            while (current_time < chef_busy_until[chef_id]) {
                usleep(100);
            }
            continue;
        }
        
        // Priority 2: Bake cake
        Customer *bake_customer = NULL;
        int earliest_request_time = -1;
        
        for (int i = 0; i < customer_count; i++) {
            Customer *cust = all_customers[i];
            // Customer must have requested and not started baking yet
            if (cust->request_time > 0 && cust->baking_start_time == 0) {
                // Check if we can start baking (must be at least 1 second after customer requested)
                if (current_time >= cust->request_time + 1 && current_time >= chef_busy_until[chef_id]) {
                    if (earliest_request_time == -1 || cust->request_time < earliest_request_time) {
                        earliest_request_time = cust->request_time;
                        bake_customer = cust;
                    }
                }
            }
        }
        
        if (bake_customer != NULL) {
            bake_customer->baking_start_time = current_time;
            bake_customer->chef_id = chef_id;
            chef_busy_until[chef_id] = current_time + 2;
            print_event(current_time, "Chef", chef_id, "bakes for Customer", bake_customer->id);
            pthread_mutex_unlock(&shop_mutex);
            
            while (current_time < chef_busy_until[chef_id]) {
                usleep(100);
            }
            continue;
        }
        
        pthread_mutex_unlock(&shop_mutex);
        usleep(100);
        
        // Check if all customers are done
        int all_done = 1;
        pthread_mutex_lock(&shop_mutex);
        for (int i = 0; i < customer_count; i++) {
            if (all_customers[i]->payment_accepted_time == 0 || 
                current_time < all_customers[i]->payment_accepted_time + 2) {
                all_done = 0;
                break;
            }
        }
        pthread_mutex_unlock(&shop_mutex);
        
        if (all_done && customers_in_shop == 0) {
            break;
        }
    }
    
    return NULL;
}

void* timer_thread(void *arg) {
    while (1) {
        usleep(10000); // 10ms = 1 unit of time
        pthread_mutex_lock(&shop_mutex);
        current_time++;
        pthread_mutex_unlock(&shop_mutex);
    }
    return NULL;
}

int main() {
    char line[256];
    all_customers = malloc(sizeof(Customer*) * 1000);
    standing_customers = malloc(sizeof(Customer*) * (MAX_CAPACITY - SOFA_CAPACITY));
    
    for (int i = 0; i <= NUM_CHEFS; i++) {
        chef_busy_until[i] = 0;
    }
    
    // Read input
    while (fgets(line, sizeof(line), stdin)) {
        if (strstr(line, "<EOF>") != NULL) break;
        
        int time, id;
        char type[20];
        if (sscanf(line, "%d %s %d", &time, type, &id) == 3) {
            Customer *c = malloc(sizeof(Customer));
            c->id = id;
            c->arrival_time = time;
            c->enter_time = 0;
            c->sit_time = 0;
            c->request_time = 0;
            c->baking_start_time = 0;
            c->pay_time = 0;
            c->payment_accepted_time = 0;
            c->chef_id = 0;
            all_customers[customer_count++] = c;
        }
    }
    
    // Start timer
    pthread_t timer;
    pthread_create(&timer, NULL, timer_thread, NULL);
    
    // Start chefs
    pthread_t chefs[NUM_CHEFS];
    int chef_ids[NUM_CHEFS];
    for (int i = 0; i < NUM_CHEFS; i++) {
        chef_ids[i] = i + 1;
        pthread_create(&chefs[i], NULL, chef_thread, &chef_ids[i]);
    }
    
    // Start customers
    pthread_t *customers = malloc(sizeof(pthread_t) * customer_count);
    for (int i = 0; i < customer_count; i++) {
        pthread_create(&customers[i], NULL, customer_thread, all_customers[i]);
    }
    
    // Wait for customers to finish
    for (int i = 0; i < customer_count; i++) {
        pthread_join(customers[i], NULL);
    }
    
    // Wait for all chefs to finish
    for (int i = 0; i < NUM_CHEFS; i++) {
        pthread_join(chefs[i], NULL);
    }
    
    // Cleanup
    free(all_customers);
    free(standing_customers);
    free(customers);
    
    return 0;
}