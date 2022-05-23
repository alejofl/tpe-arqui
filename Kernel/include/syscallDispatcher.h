#ifndef SYSCALL_DISPATCHER_H

#define SYSCALL_DISPATCHER_H

int sys_write(unsigned int fd, const char * buf, unsigned int count);
int sys_read(unsigned int fd, char * buf, unsigned int count);
int sys_clear(uint64_t rdi, uint64_t rsi, uint64_t rdx);
int sys_seconds_elapsed(uint64_t rdi, uint64_t rsi, uint64_t rdx);

#endif
