#include "kernel/types.h" // value type
#include "user/user.h" //fnc

#define RD 0 //pipe read
#define WR 1 //pipe write

int main(int argc,char const *argv){
    char buf = 'p';
    int fd_c2p[2]; //子进程->父进程
    int fd_p2c[2]; //父进程->子进程
    pipe(fd_c2p);
    pipe(fd_p2c);

    int pid = fork();
    int exit_status = 0;

    if(pid < 0){
        fprintf(2, "fork() error!\n");
        close(fd_c2p[RD]);
        close(fd_c2p[WR]);
        close(fd_p2c[RD]);
        close(fd_p2c[WR]);
        exit(1);
    } else if (pid == 0){ //子进程
        close(fd_p2c[WR]);
        close(fd_c2p[RD]);

        if(read(fd_p2c[RD],&buf,sizeof(char)) != sizeof(char)){
            fprintf(2,"child read() error!\n");
            exit_status = 1;// flag error
        }else{
            fprintf(1,"%d: received ping\n",getpid());
        }


        if(write(fd_c2p[WR],&buf,sizeof(char))!=sizeof(char)){
            fprintf(2,"child write() error!");
            exit_status = 1;
        }

        close(fd_c2p[WR]);
        close(fd_p2c[RD]);

        exit(exit_status);
    }else{//父进程
        close(fd_c2p[WR]);
        close(fd_p2c[RD]);

        if(write(fd_p2c[WR],&buf,sizeof(char))!=sizeof(char)){
            fprintf(2,"parent write() error!");
            exit_status = 1;
        }

        if(read(fd_c2p[RD],&buf,sizeof(char))!=sizeof(char)){
            fprintf(2,"parent read() error!");
            exit_status = 1;
        }else{
            fprintf(1,"%d: received pong\n",getpid());
        }

        close(fd_c2p[RD]);
        close(fd_p2c[WR]);
        exit(exit_status);
    }

}