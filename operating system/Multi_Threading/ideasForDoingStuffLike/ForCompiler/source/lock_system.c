/*

CPU atomic instructions (like x86 LOCK XCHG){

    __sync_lock_test_and_set(&mutex->locked, true);



}

hardware protects the entire 64-byte block containing your atomic variable,🦖

-> 
L1 Cache Structure:
[Address Tag][State(MESI)][Data...][Data...]
[0x1000     ][Modified   ][64 bytes of data]
[0x1040     ][Exclusive  ][64 bytes of data]  
[0x1080     ][Shared     ][64 bytes of data]
[0x10C0     ][Invalid    ][...empty...]

Real L1 Cache (64 entries):

text
Entry 1:  [0x1000][Modified]  [64 bytes]
Entry 2:  [0x1040][Exclusive] [64 bytes]
...
Entry 64: [0x10C0][Invalid]   [Empty]


"Checking" = Parallel Hardware Lookup:

verilog
// This happens in hardware - all tags checked simultaneously
input_request_addr = 0x1000;
// ALL cache tags compare simultaneously in 1 cycle:
tag[0]: 0x1000 == input_request_addr? → MATCH, state=Modified
tag[1]: 0x1040 == input_request_addr? → no
tag[2]: 0x1080 == input_request_addr? → no  
tag[3]: 0x10C0 == input_request_addr? → no


Finite state machines for MESI protocol



/////////////////////////////////////////////////


Memory barriers to ensure visibility across cores

Cache coherency protocols (MESI)

*/



#include "lock_system.h"
#include <stdio.h>


mylock_t network_lock = { .locked = false, .name = "network_lock" };
mylock_t file_lock = { .locked = false, .name = "file_lock" }; 
mylock_t memory_lock = { .locked = false, .name = "memory_lock" };



void mylock_init(mylock_t *lock, const char *name) {
    lock->locked = false;
    strncpy(lock->name, name, sizeof(lock->name) - 1);
    lock->name[sizeof(lock->name) - 1] = '\0'; // Ensure null-termination
}


_Acquires_exclusive_lock_(lock)
void mylock_lock(mylock_t *lock) {
    while (__sync_lock_test_and_set(&lock->locked, true)) {
        // Busy-wait (spin) until the lock is acquired
        // Optionally, you can add a pause or yield instruction here
    }
}




