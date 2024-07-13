#include "kernel/types.h"
#include "user/user.h"

void main(int argc,char const *argv[]){
	if(argc != 2){
		fprintf(2,"usage: wait <time>\n");
		exit(1);
	}
	wait(atoi(argv[1])); //wrong usage !
	exit(0);
}