/* IceNET Technology 2026 */

#include <iostream>
#include "gui.h"

static const mainWindowType w =
{
    .xWindow = 1200,
    .yWindow = 750,
    .xGap = 5,
    .yGap = 5,
    .xLogo = 200,
    .yLogo = 50,
    .xUnit = 50,
    .yUnit = 25,
};

static const mainConsoleType c =
{
    .xPosition = w.xGap, /* OK */
    .yPosition = w.yWindow - 300 - w.xGap,
    .xSize = w.xWindow - w.xGap*2,
    .ySize = 300,
};

gui::gui()
{
    std::cout << "[MAIN] [CONSTRUCTOR]" << this << ":: gui";

    setupWindow();
    setupMainConsole();
}

gui::~gui()
{
    std::cout << "[MAIN] [DESTRUCTOR]" << this << ":: gui";
}

void gui::setupWindow()
{
    setWindowTitle("IceNET Platform");
    setFixedSize(w.xWindow, w.yWindow);
}

void gui::setupMainConsole()
{
    m_mainConsole = new QPlainTextEdit(this);
    m_mainConsole->setReadOnly(true);
    m_mainConsole->setGeometry(c.xPosition, c.yPosition, c.xSize, c.ySize);
    m_mainConsole->setPlainText("[INIT] Main Console Initialized...");
}
