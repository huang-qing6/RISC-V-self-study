#include "kernel/types.h"
#include "user.h"

void main(int argc, char const *argv[]){
    int time;
	if(argc != 2){
		fprintf(2,"usage: uptime <time>\n");
		exit(1);
	}
    int exectime = atoi(argv[1]);
    for(int i=0; i < exectime; i++){
        sleep(1);
        time =  uptime();
        fprintf(1,"OS strat time: %d\n", time);
    }
    exit(1);
}