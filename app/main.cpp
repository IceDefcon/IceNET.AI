/* IceNET Technology 2026 */

#include "gui.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    gui window;
    window.show();

    return app.exec();
}
