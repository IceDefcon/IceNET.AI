/* IceNET Robotics 2026 */

#include "console.h"

console::console(QPlainTextEdit *pConsole) :
m_mainConsole(pConsole)
{
    std::cout << "[INFO] [CONSTRUCTOR] " << this << " :: " << __PRETTY_FUNCTION__ << std::endl;
}

console::~console()
{
    std::cout << "[INFO] [DESTRUCTOR] " << this << " :: " << __PRETTY_FUNCTION__ << std::endl;
}

void console::printConsole(consoleType type, const QString &message)
{
    QString prefix;

    switch(type)
    {
        case INFO: prefix = "$ [INFO] "; break;
        case TODO: prefix = "$ [TODO] "; break;
        case WARN: prefix = "$ [WARN] "; break;
        case ERNO: prefix = "$ [ERNO] "; break;
    }

    if (m_mainConsole)
    {
        m_mainConsole->appendPlainText(prefix + message);
    }
}
