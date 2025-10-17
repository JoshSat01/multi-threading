
//this project deepseek link >> https://chat.deepseek.com/share/dvuuazciygmowwb6hl

#ifndef   _LOCK_SYSTEM_H_
#define   _LOCK_SYSTEM_H_   

#include <stdbool.h>

// #define __GNU__ 1

/* compiler specific annotations*/
#ifdef __GNU__
    #define __lock_level_order(a, b) __attribute__((lock_order(a, b)))   //this is for analyser after ast making locking flow check
    #define __no_competing_thread __attribute__((no_thread_safety_analysis)) //this tells no need to do anyhting extra
    
    /*
        [dont force 🧠 to tell what it is by some other stuff 🤯]
        in below line, 
        __attribute__ is compiler specific keyword
        ✨(acquire(x)  is like label to tell compiler that this function acquires lock 
        (acquire(x)) -> not a function or anthter things
     */

    #define _Acquires_exclusive_lock_(x) __attribute__((acquire(x))) 
    #define _Releases_exclusive_lock_(x) __attribute__((release(x)))
    #define _Acquires_shared_lock_(x) __attribute__((require_capability(x)))
#else
    /* Fallback for other compilers */
    #define __lock_level_order(a, b) __attribute__((lock_order(a, b)))
    #define __no_competing_thread
    #define _Acquires_exclusive_lock_(lock)
    #define _Releases_exclusive_lock_(lock) 
    #define _Requires_lock_held_(lock)
#endif


// _lock_level_order(mylock1 , mylock2)
// _lock_level_order(mylock2 , mylock3)


typedef struct {
    volatile bool locked; /* volatile is telling compiler like this variable 
    should be accessed from memory every time , not from previously cached registers */
    char name[32];
    //padding to make structure size 64 bytes for lock cache memory alignment
    char padding[64 - sizeof(bool) - 32];
} mylock_t;

void mylock_init(mylock_t* lock, const char* name);
_Acquires_exclusive_lock_(lock)
void mylock_lock(mylock_t* lock);
_Releases_exclusive_lock_(lock)
void mylock_unlock(mylock_t* lock);
bool mylock_trylock(mylock_t* lock);


//locks
extern mylock_t network_lock; //its definition is in some other .c file
extern mylock_t file_lock;
extern mylock_t memory_lock;



#endif/* _LOCK_SYSTEM_H_ */