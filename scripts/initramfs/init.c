#include <stdio.h>
#include <unistd.h>
#include <sys/reboot.h>

int main(void) {
	printf("\n===== Linux 2.6.11.12 Booted OK! =====\n\n");
	sleep(2);
	sync();
	reboot(RB_POWER_OFF);
	return 0;
}
