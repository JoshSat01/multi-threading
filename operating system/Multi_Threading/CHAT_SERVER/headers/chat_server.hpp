/*

going with 
[👽] specific memory block can be accessible in memory 
      based on offset from its fixed point as where it put it known memory
[🦖] you sure ?? 

[👽] ...

*/

#include <iostream>
#include <vector>
#include <thread>
#include <mutex>
#include <queue>
#include <map>
#include <set>
#include <atomic>
#include <memory>
#include <string>
#include <sstream>
#include <chrono>
#include <ctime>


// Windows sockets
#include <winsock2.h>
#include <ws2tcpip.h>

//needed code from windows , at runtime
#pragma comment(lib , "ws2_32.lib") //it tells compiler to add the reference to that library


//ChatMessage in memory , for now it's use dont know 
struct ChatMessage {
    std::string username;
    std::string content;
    std::string room;
    std::string timestamp;
    bool is_private{false};
    std::string target_user;
};


struct User {
    SOCKET socket_fd; //??
    std::string username;
    std::string current_room;
    std::thread handler_thread;
    std::atomic<bool> connected{true}; // {} tells compiler no lose of data , like no conversion from float to int or something like that 
    
};


class ThreadSafeQueue {
private:
    std::queue<ChatMessage> queue_;    
    std::mutex mutex_;
};