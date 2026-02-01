/* IceNET Robotics 2026 */

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
        qWarning() << "Use 'ipcs -m' to check for Shared Memory Segments";
        qWarning() << "Use 'ipcs -s' to check for Semaphore Arrays";
        qWarning() << "'Use 'ipcrm -m <shmid>' to remove Shared Memory";
        qWarning() << "'Use 'ipcrm -s <semid>' to remove Semaphore";

        return 1;
    }

    auto window = std::make_unique<gui>();
    window->show();

    return app.exec();
}
