# Office Bakery Multithreading Simulation (Part C)

## Problem Description
This program simulates an office bakery with multithreading constraints:
- 4 ovens, 4 chefs, sofa with 4 seats, standing room for additional customers
- Maximum capacity: 25 customers total
- Customer workflow: enter → sit → request cake → pay → leave
- Chef workflow: bake cake (2s) → accept payment (2s)
- Chefs prioritize accepting payment over baking

## Implementation Features

### Resource Constraints
- **Bakery Capacity**: Maximum 25 customers can be in the bakery
- **Sofa Capacity**: Maximum 4 customers can sit on the sofa
- **Concurrent Baking**: Maximum 4 customers can get cake simultaneously (4 ovens)
- **Payment Register**: Only 1 customer can pay at a time (single cash register)

### Synchronization
- **Semaphores**: Used for capacity limits and resource management
- **Mutexes**: Used for thread-safe printing and state management
- **Condition Variables**: Used for chef-customer coordination
- **FIFO Queues**: Ensure proper ordering for sofa seating

### Threading Model
- **Customer Threads**: Each customer runs in its own thread
- **Chef Threads**: 4 chef threads handle baking and payment acceptance
- **Priority System**: Chefs prioritize payment acceptance over baking new cakes

### Timing Constraints
- **Customer Actions**: Each action (enter, sit, request, pay) takes 1 second
- **Chef Actions**: Baking and payment acceptance each take 2 seconds
- **Proper Sequencing**: Actions cannot be interrupted once started

## Compilation and Usage

```bash
gcc -pthread bakery.c -o bakery
```

### Input Format
```
<timestamp> Customer <id>
<timestamp> Customer <id>
...
<EOF>
```

### Example Input
```
10 Customer 1
11 Customer 2
12 Customer 3
<EOF>
```

### Output Format
```
<timestamp> Customer <id> <action>
<timestamp> Chef <id> <action>
```

Where actions are:
- Customer actions: enters, sits, requests cake, pays, leaves
- Chef actions: bakes for Customer <id>, accepts payment for Customer <id>

## Key Implementation Details

1. **FIFO Sofa Seating**: Customers who arrive when sofa is full wait in standing area and get seats in order of arrival
2. **Any Chef Can Accept Payment**: When a customer is ready to pay, any available chef can accept the payment (not restricted to the chef who baked)
3. **Priority Handling**: Chefs prioritize accepting payments over baking new cakes
4. **Resource Management**: Proper semaphore usage ensures capacity limits are never exceeded
5. **Thread Safety**: All shared state access is protected by mutexes
6. **Chef Action Timing**: Chefs start their actions 1 second after the customer's request
   - Customer requests cake at time T → Chef prints "bakes" at time T+1 → Baking finishes at T+3
   - Customer pays at time T → Chef prints "accepts payment" at time T+1 → Payment finishes at T+3

## Assumptions

1. **Capacity Enforcement**: If bakery is at full capacity (25 customers), new customers cannot enter and leave immediately without waiting
2. **Input Ordering**: Input is sorted by timestamp (as per Q&A #11)
3. **Action Duration**: Each customer action (enter, sit, request, pay) takes 1 second; each chef action (baking, payment) takes 2 seconds
4. **Sofa Reservation**: Sofa seat remains reserved for a customer until they completely leave the bakery (after payment)
5. **Multiple Simultaneous Arrivals**: The system can handle multiple customers arriving at the same timestamp
6. **Customer Request Sequence**: Customers must sit on sofa before requesting cake

## Testing

The implementation has been tested with the provided examples and produces output that matches the expected format, demonstrating:
- Correct resource constraint enforcement
- Proper FIFO ordering
- Accurate timing simulation
- Thread-safe operations
- Chef priority handling

## Files
- `bakery.c`: Main implementation file
- `README.md`: This documentation file