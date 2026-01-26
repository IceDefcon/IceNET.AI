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
    std::cout << "[MAIN] [CONSTRUCTOR] " << this << " :: gui" << std::endl;

    setupWindow();
    // setupMainConsole();
    // setupFlashInterface();
}

gui::~gui()
{
    std::cout << "[MAIN] [DESTRUCTOR] " << this << " :: gui" << std::endl;
}

void gui::setupWindow()
{
    setWindowTitle("IceNET AI Drone Platform");
    setFixedSize(w.xWindow, w.yWindow);\
    setStyleSheet(main_window_style);

    QTabWidget *tabs = new QTabWidget(this);
    tabs->setTabPosition(QTabWidget::West);
    tabs->setStyleSheet(tab_style);
    tabs->setGeometry(w.xGap, w.yGap, w.xWindow - w.xGap*2, w.yWindow - w.yGap*2);

    QWidget *flash = new QWidget();
    QWidget *config = new QWidget();
    QWidget *comms = new QWidget();

    tabs->addTab(flash, "FLASH");
    tabs->addTab(config, "CONFIG");
    tabs->addTab(comms, "COMMS");
}

void gui::setupMainConsole()
{
    m_mainConsole = new QPlainTextEdit(this);
    m_mainConsole->setReadOnly(true);
    m_mainConsole->setGeometry(c.xPosition, c.yPosition, c.xSize, c.ySize);

    QFont consoleFont;
    consoleFont.setFamily("Courier");
    consoleFont.setPointSize(9);
    consoleFont.setBold(false);

    m_mainConsole->setFont(consoleFont);

    m_mainConsole->setPlainText("[INIT] Main Console Initialized...");
}

void gui::setupFlashInterface()
{
    QLabel *reset_label = new QLabel("Fx3 Flash", this);
    QFont reset_labelFont;
    reset_labelFont.setFamily("Courier");
    reset_labelFont.setPointSize(20);
    reset_labelFont.setBold(true);
    reset_label->setFont(reset_labelFont);
    reset_label->setGeometry(w.xGap, w.yGap, w.xLogo, w.yLogo);
}
