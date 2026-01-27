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
    setupFlashInterface();
}

gui::~gui()
{
    std::cout << "[MAIN] [DESTRUCTOR] " << this << " :: gui" << std::endl;
}

void gui::setupWindow()
{
    setWindowTitle("IceNET AI Drone Platform");
    setStyleSheet(main_window_style);

    QTabWidget *tabs = new QTabWidget(this);
    tabs->setTabPosition(QTabWidget::West);
    tabs->tabBar()->setShape(QTabBar::RoundedWest);
    tabs->setStyleSheet(tab_style);

    m_flash  = new QWidget();
    m_config = new QWidget();
    m_comms  = new QWidget();

    tabs->addTab(m_flash, "FLASH");
    tabs->addTab(m_config, "CONFIG");
    tabs->addTab(m_comms, "COMMS");

    /* Main Console :: Right Layout */
    setupMainConsole();
    QVBoxLayout *rightLayout = new QVBoxLayout();
    rightLayout->addWidget(m_mainConsole);

    /* Tabs :: Left Layout ---> Merge Layouts */
    QHBoxLayout *mainLayout = new QHBoxLayout(this);
    mainLayout->addWidget(tabs, 2);
    mainLayout->addLayout(rightLayout, 1);

    setLayout(mainLayout);

    /* Multi-screen maximize workaround */
    QScreen *screen = QGuiApplication::screenAt(QCursor::pos());
    if (!screen)
    {
        screen = QGuiApplication::primaryScreen();
    }

    QRect geom = screen->availableGeometry();
    this->setGeometry(geom);
    this->show();
}


void gui::setupMainConsole()
{
    m_mainConsole = new QPlainTextEdit(this); // <-- parent = main window
    m_mainConsole->setReadOnly(true);

    QFont consoleFont;
    consoleFont.setFamily("Courier");
    consoleFont.setPointSize(10);
    consoleFont.setStyleHint(QFont::Monospace);
    consoleFont.setFixedPitch(true);

    m_mainConsole->setFont(consoleFont);
    m_mainConsole->setStyleSheet(console_style);
    m_mainConsole->setPlainText("[INIT] Main Console Initialized...");
}

void gui::setupFlashInterface()
{
    /* TODO :: NEXT */
}
