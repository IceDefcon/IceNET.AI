/* IceNET Robotics 2026 */

#pragma once

#include <QPlainTextEdit>

#include <iostream>

#include "consoleTypes.h"

class console
{
    private:

        QPlainTextEdit *m_mainConsole;

    public:
        console(QPlainTextEdit *pConsole);
        ~console();

    void printConsole(consoleType type, const QString &message);
};
