#define NtCurrentTeb() ((TEB*) __readfsword(0x18))


/*
//this is preprocessor directive , before compilation the places where this function code NtCurrentTeb()  is replaced by (TEB*) __readfsword(0x18);
#define NtCurrentTeb() ((TEB*) __readfsword(0x18))



// __readfsword is placed in known memory , where offset 0x18 is accessed here
mov eax, dword ptr fs:[24h]



//this is like memory in hardware ?
FS Segment Map (32-bit Windows):
text
FS:[0000] = ExceptionList
FS:[0004] = StackBase
FS:[0008] = StackLimit
FS:[000C] = SubSystemTib
FS:[0010] = FiberData
FS:[0014] = ArbitraryUserPointer
FS:[0018] = TEB Self Pointer        ← __readfsdword(0x18) reads here!
FS:[001C] = EnvironmentPointer
FS:[0020] = Process ID (ClientId.UniqueProcess)
FS:[0024] = Thread ID (ClientId.UniqueThread)  ← GetCurrentThreadId() reads here!
FS:[0028] = ActiveRpcHandle
FS:[002C] = ThreadLocalStoragePointer


*/