#include <scheduler.h>
#include <interrupts.h>
#include <schedulerfunctions.h>

static task processes[NUM_PROCESSES];
static int process_qty = 0;
static int current_pid = -1;
static char scheduler_active = 0;

// Cuando llamamos al pipe se tiene que ejecutar la siguiente funcion;
//Función que crea una task y la agrega al array processes
//devuelve el pid
int load_processes(uint64_t rip, int fd, char * string) {
    task new_task = {
        .rip = rip,
        .rsp = initialize_process(STACK_BASE + PROCESS_SIZE * process_qty, rip,fd,string),
        .stack_base = STACK_BASE + PROCESS_SIZE * process_qty,
        .active = 1
    };
    processes[process_qty++] = new_task;
    return process_qty - 1;
}


//Guarda la current task a ejecutar, teniendo en cuenta el pid que recibe como argumento
//actualiza el current pid y corre el proceso
//Si terminó de correr el proceso el lugar en el array que guarda los procesos eliminado
//y actualizar el valor de current pid a -1 para saber que no se está corriendo nada
void exec_process(int pid){
    if ( pid < 0 || pid >= process_qty) {
        return;
    }
    task current_task = processes[pid];
    if(current_task.active == 0){
        return;
    }
    current_pid = pid;
    run_process(current_task.rsp);
    //Si llego aca, es porque el proceso terminó
    current_task.active = 0;
    processes[pid] = current_task;
    current_pid = -1;
}

//Obtiene el proceso de acuerdo al pid recibido por argumento
//y realiza la actualizacion de RIP y RSP de la task
void pause_process(int pid) {
    if ( pid < 0 || pid >= process_qty ) {
        return;
    }
    task current_task = processes[pid];
    current_task.rip = get_current_rip();
    current_task.rsp = stop_process(get_current_rsp(), current_task.rip);
    current_task.active = 0;
    processes[pid] = current_task;
}

void activate_scheduler() {
    scheduler_active = 1;
}

char is_scheduler_active() {
    return scheduler_active;
}

void scheduler(){
    pause_process(current_pid);
    run_process((current_pid + 1) % NUM_PROCESSES);
}