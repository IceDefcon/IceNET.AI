/* IceNET Technology 2026 */

#include <iostream>

#include "gui.h"

static QSystemSemaphore semaphore("IceNETSemaphore", 1);
static QSharedMemory sharedMemory("IceNETSharedMemory");

bool multipleInstances()
{
    semaphore.acquire();
    bool alreadyRunning = !sharedMemory.create(1);
    semaphore.release();

    return alreadyRunning;
}

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    if (multipleInstances())
    {
        qWarning() << "Another instance is already running!";
        qWarning() << "Please check manually: 'ipcs -m' and 'ipcs -s'";
        qWarning() << "And Remove if needed: 'ipcrm -m <shmid>' and 'ipcrm -s <semid>'";

        return 1;
    }

    gui window;
    window.show();

    return app.exec();
}
