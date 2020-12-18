#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <pthread.h>
#include <semaphore.h>

unsigned int honeypot_full = 0;
unsigned int max_delay = 0;
unsigned long honeypot = 0;
unsigned long honeypot_target = 200;
struct timespec sim_init_time;

sem_t bear_sem;
pthread_spinlock_t honeypot_lock;

struct simulation_time{
	unsigned long sec;
	unsigned short msec;
};

void sim_time(struct simulation_time *ptr){
	struct timespec ct;
	clock_gettime(CLOCK_REALTIME, &ct);
	ptr->sec = ct.tv_sec - sim_init_time.tv_sec;
	ptr->msec = (ct.tv_nsec - sim_init_time.tv_nsec) / 1000000;
	if(ct.tv_nsec - sim_init_time.tv_nsec < 0){
        	ptr->sec--;
	        ptr->msec += 1000;
	}
}

void *run_a_bee(void *pthread_data){
	unsigned int bee_id = (unsigned int)pthread_data;
	struct simulation_time ct;
	while(1){
		if(max_delay)
			usleep((1 + rand() % max_delay) * 1000);
		pthread_spin_lock(&honeypot_lock);
		sim_time(&ct);
		if(honeypot >= honeypot_target){
			if(!honeypot_full){
				honeypot_full = 1;
				sem_post(&bear_sem);
				// it might have been nice to unlock the honeypot before awaking the bear
				// howewer it appeared to be too costly for the simulation when many threads are being executed:
				// dispermitting bees execution until bear awakes helps somehwat
				continue;
			}
			else{
				printf("%lu.%.3hu\tbee #%.3u won't upfill the honeypot since it's full\n", ct.sec, ct.msec, bee_id);
			}
		}
		else{
			honeypot++;
			printf("%lu.%.3hu\tbee #%.3u upfills the honeypot\n", ct.sec, ct.msec, bee_id);
		}
		pthread_spin_unlock(&honeypot_lock);
	}
	return NULL;
}


void put_the_bear_to_sleep(void){
	struct simulation_time ct;
	sim_time(&ct);
	printf("%li.%.3hu\tsleepy bear starts sleeping\n", ct.sec, ct.msec);
	sem_wait(&bear_sem);
}

void *run_a_bear(void *pthread_data){
	struct simulation_time ct;
	put_the_bear_to_sleep();
	while(1){
		sim_time(&ct);
		printf("%lu.%.3hu\tthe bear awakes eating all the honey: %lu points in total\n", ct.sec, ct.msec, honeypot);
		honeypot = 0;
		honeypot_full = 0;
		pthread_spin_unlock(&honeypot_lock); // here we assume that when the bear _awakes_, the spinlock is left for us to unlock
		put_the_bear_to_sleep();
	}
	return NULL;
}

void print_help(){
    printf("Usage: task [bees_count [target [delay]]]\n");
    printf("Bees count should be in range (0, 4096). Default value: 5\n");
    printf("Target honey shouold be an unsigned 32 bit number greater than 0. Default value: 200\n");
    printf("Inclusive honeyhunt delay upper bound should be an unsigned 32 bit number of milliseconds. Default value: 1\n");
}

int main(int argc, char **argv){
	int bees_count = 5;
	switch(argc){
	case 4:
		if(!sscanf(argv[3], "%u", &max_delay)){
			printf("Wrong inclusive honeyhunt delay upper bound format. There be a 32 bit unsigned number\n");
			return -1;
		}
	case 3:
		if(!sscanf(argv[2], "%u", &honeypot_target) || !honeypot_target){
			printf("Wrong target honey format. There be a non-zero unsinged 32 bit number.\n");
			return -1;
		}
	case 2:
		if(sscanf(argv[1], "%u", &bees_count)){
        		if(bees_count == 0 || bees_count >= 4096ull){
	        		printf("Wrong bees count format. There be a number in range (1, 4096)\n");
        			return -1;
        		}
		}
		else{
        		print_help();
        		return 0;
		}
	case 1:
		break;
	default:
		print_help();
		return -1;
	}
	printf("Starting the simulation\n");
	pthread_t bear;
	pthread_t *bees = alloca(bees_count * sizeof(pthread_t));
	pthread_spin_init(&honeypot_lock, PTHREAD_PROCESS_PRIVATE);
	sem_init(&bear_sem, 0, 0);

	clock_gettime(CLOCK_REALTIME, &sim_init_time);
	pthread_create(&bear, NULL, run_a_bear, NULL);
	for(unsigned int i = 0; i < bees_count; i++)
		pthread_create(bees + i, NULL, run_a_bee, i);
	pthread_join(bear, NULL);
	return 0;
}
